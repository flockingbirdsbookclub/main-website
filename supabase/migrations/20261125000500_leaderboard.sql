-- Leaderboard: seasons, categories, a points ledger, awards, standings.
-- Also the mural view. Design: docs/DATA_MODEL.md.

create table public.seasons (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  starts_on        date not null,
  ends_on          date not null,
  reading_cycle_id uuid references public.reading_cycles (id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  check (ends_on >= starts_on)
);
create index seasons_dates_idx on public.seasons (starts_on, ends_on);

create table public.score_categories (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique check (public.is_valid_slug(slug)),
  name           text not null,
  description    text,
  applies_to     text not null check (applies_to in ('flock', 'member', 'both')),
  default_points int not null default 0,
  is_automatic   boolean not null default false,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- A ledger: rows are added, never changed. A mistake is cancelled with a
-- negative entry, so every total can be explained line by line.
create table public.score_entries (
  id          uuid primary key default gen_random_uuid(),
  season_id   uuid not null references public.seasons (id) on delete restrict,
  category_id uuid not null references public.score_categories (id) on delete restrict,
  flock_id    uuid references public.flocks (id) on delete restrict,
  profile_id  uuid references public.profiles (id) on delete restrict,
  points      int not null,
  note        text,
  source      text not null default 'manual' check (source in ('manual', 'automatic')),
  source_ref  text,
  awarded_by  uuid references auth.users (id) on delete set null,
  created_at  timestamptz not null default now(),
  constraint exactly_one_target check ((flock_id is null) <> (profile_id is null)),
  constraint automatic_has_ref check (source = 'manual' or source_ref is not null)
);
-- Nothing is awarded twice for the same thing.
create unique index score_entries_once_idx on public.score_entries (category_id, source_ref) where source_ref is not null;
create index score_entries_season_idx on public.score_entries (season_id);
create index score_entries_flock_idx on public.score_entries (flock_id);
create index score_entries_profile_idx on public.score_entries (profile_id);

create or replace function public.score_entries_append_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Score entries cannot be changed or deleted. Add a correcting entry instead.';
end;
$$;
create trigger score_entries_no_update
  before update or delete on public.score_entries
  for each row execute function public.score_entries_append_only();

create table public.awards (
  id         uuid primary key default gen_random_uuid(),
  season_id  uuid references public.seasons (id) on delete set null,
  title      text not null,
  flock_id   uuid references public.flocks (id) on delete restrict,
  profile_id uuid references public.profiles (id) on delete restrict,
  awarded_on date not null,
  media_id   uuid references public.media (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint exactly_one_winner check ((flock_id is null) <> (profile_id is null))
);
create index awards_awarded_on_idx on public.awards (awarded_on desc);

select public.track_table('public.seasons');
select public.track_table('public.score_categories');
select public.track_table('public.score_entries');
select public.track_table('public.awards');

-- ---------------------------------------------------------------------------
-- Automatic points
-- ---------------------------------------------------------------------------

-- Awards a member the points for an automatic category, once, in the season
-- covering today. Does nothing if there is no such season or the category is
-- switched off.
create or replace function public.award_automatic(p_category_slug text, p_profile_id uuid, p_ref text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  cat public.score_categories;
  season uuid;
begin
  select * into cat from public.score_categories
   where slug = p_category_slug and is_automatic and is_active;
  if cat.id is null or p_profile_id is null then
    return;
  end if;
  select id into season from public.seasons
   where current_date between starts_on and ends_on
   order by starts_on desc limit 1;
  if season is null then
    return;
  end if;
  insert into public.score_entries (season_id, category_id, profile_id, points, source, source_ref)
  values (season, cat.id, p_profile_id, cat.default_points, 'automatic', p_ref)
  on conflict (category_id, source_ref) where source_ref is not null do nothing;
end;
$$;
revoke execute on function public.award_automatic(text, uuid, text) from public, anon, authenticated;

create or replace function public.points_for_published_article()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'published' and (tg_op = 'INSERT' or old.status is distinct from 'published') then
    perform public.award_automatic('article-published', new.author_profile_id, 'article:' || new.id);
  end if;
  return new;
end;
$$;
create trigger articles_award_points
  after insert or update of status on public.articles
  for each row execute function public.points_for_published_article();

create or replace function public.points_for_attendance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.attended is true and new.profile_id is not null
     and (tg_op = 'INSERT' or old.attended is distinct from true) then
    perform public.award_automatic('social-attended', new.profile_id, 'event:' || new.event_id || ':' || new.profile_id);
  end if;
  return new;
end;
$$;
create trigger event_rsvps_award_points
  after insert or update of attended on public.event_rsvps
  for each row execute function public.points_for_attendance();

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------

alter table public.seasons          enable row level security;
alter table public.score_categories enable row level security;
alter table public.score_entries    enable row level security;
alter table public.awards           enable row level security;

revoke all on public.seasons, public.score_categories, public.score_entries, public.awards
  from anon, authenticated;

grant select on public.seasons, public.score_categories, public.awards to anon, authenticated;
grant insert, update, delete on public.seasons, public.score_categories, public.awards to authenticated;
-- Notes on entries are for members and staff, not the open web.
grant select (id, season_id, category_id, flock_id, profile_id, points, source, created_at)
  on public.score_entries to anon;
grant select on public.score_entries to authenticated;
grant insert on public.score_entries to authenticated;

create policy "seasons are public" on public.seasons
  for select to anon, authenticated using (true);
create policy "staff manage seasons" on public.seasons
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "categories are public" on public.score_categories
  for select to anon, authenticated using (is_active or public.is_staff());
create policy "admins manage categories" on public.score_categories
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Points for flocks, and for members whose profile is published, are public.
create policy "points are public" on public.score_entries
  for select to anon, authenticated
  using (
    flock_id is not null
    or exists (select 1 from public.profiles p where p.id = profile_id and p.status = 'published' and p.archived_at is null)
    or profile_id = public.current_profile_id()
    or public.is_staff()
  );
create policy "admins award points" on public.score_entries
  for insert to authenticated
  with check (public.is_admin() and source = 'manual' and awarded_by = auth.uid());

create policy "awards are public" on public.awards
  for select to anon, authenticated
  using (
    flock_id is not null
    or exists (select 1 from public.profiles p where p.id = profile_id and p.status = 'published' and p.archived_at is null)
    or public.is_staff()
  );
create policy "admins manage awards" on public.awards
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- Standings: sums of the ledger, never stored
-- ---------------------------------------------------------------------------

create view public.flock_standings with (security_invoker = on) as
  select e.season_id, e.flock_id, f.slug as flock_slug, f.name as flock_name,
         sum(e.points)::int as points,
         rank() over (partition by e.season_id order by sum(e.points) desc) as rank
    from public.score_entries e
    join public.flocks f on f.id = e.flock_id
   group by e.season_id, e.flock_id, f.slug, f.name;

create view public.member_standings with (security_invoker = on) as
  select e.season_id, e.profile_id, p.slug as profile_slug, p.full_name,
         m.flock_id,
         sum(e.points)::int as points,
         rank() over (partition by e.season_id order by sum(e.points) desc) as rank
    from public.score_entries e
    join public.profiles p on p.id = e.profile_id
    left join public.flock_memberships m on m.profile_id = p.id and m.ended_on is null
   group by e.season_id, e.profile_id, p.slug, p.full_name, m.flock_id;

-- ---------------------------------------------------------------------------
-- The Show Your Work Mural: leaders first, then featured, then everyone
-- ---------------------------------------------------------------------------

create view public.mural_entries with (security_invoker = on) as
  select p.id, p.slug, p.full_name, p.photo_media_id, p.profession, p.fun_fact,
         case when p.show_personality then p.personality_key end as personality_key,
         p.is_featured, p.sort_order,
         f.id as flock_id, f.slug as flock_slug, f.name as flock_name,
         m.role as flock_role,
         case m.role when 'leader' then 0 when 'co_leader' then 1
                     else case when p.is_featured then 2 else 3 end end as mural_group
    from public.profiles p
    left join public.flock_memberships m on m.profile_id = p.id and m.ended_on is null
    left join public.flocks f on f.id = m.flock_id
   where p.status = 'published' and p.archived_at is null;

grant select on public.flock_standings, public.member_standings, public.mural_entries to anon, authenticated;
