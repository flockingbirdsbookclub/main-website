-- Members: personality types, flocks, profiles, contact links, memberships.
-- Feeds the Show Your Work Mural (Phase 10). Design: docs/DATA_MODEL.md.

-- The four results of the bird test. Here, not in the games migration,
-- because a profile can show its bird.
create table public.personality_types (
  key              text primary key check (key in ('red', 'yellow', 'green', 'blue')),
  bird_name        text,
  colour           text not null,
  summary          text,
  strengths        text,
  blind_spots      text,
  how_to_work_with text,
  image_media_id   uuid references public.media (id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table public.flocks (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique check (public.is_valid_slug(slug)),
  name           text not null,
  area           text,
  meeting_rhythm text,
  photo_media_id uuid references public.media (id) on delete set null,
  is_active      boolean not null default true,
  sort_order     int not null default 0,
  archived_at    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table public.profiles (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid unique references auth.users (id) on delete set null,
  email           text not null unique check (email = lower(email)),
  slug            text not null unique check (public.is_valid_slug(slug)),
  full_name       text not null,
  photo_media_id  uuid references public.media (id) on delete set null,
  profession      text,
  fun_fact        text,
  bio             text,
  personality_key text references public.personality_types (key) on delete set null,
  show_personality boolean not null default false,
  joined_on       date,
  status          text not null default 'draft' check (status in ('draft', 'submitted', 'published', 'rejected')),
  review_note     text,
  -- Changes a member makes to a published profile wait here for review, so
  -- the published version stays up until staff approve the new one.
  pending_changes jsonb,
  is_featured     boolean not null default false,
  sort_order      int not null default 0,
  consent_at      timestamptz,
  archived_at     timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint published_needs_consent check (status <> 'published' or consent_at is not null)
);
create index profiles_status_sort_idx on public.profiles (status, sort_order);

create table public.profile_links (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  kind       text not null check (kind in ('linkedin', 'instagram', 'x', 'website', 'email', 'phone', 'whatsapp')),
  value      text not null check (length(trim(value)) > 0),
  visibility text not null check (visibility in ('public', 'members')),
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index profile_links_profile_idx on public.profile_links (profile_id);

-- Phone, email and WhatsApp default to members-only.
create or replace function public.profile_links_default_visibility()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.visibility is null then
    new.visibility := case when new.kind in ('email', 'phone', 'whatsapp') then 'members' else 'public' end;
  end if;
  return new;
end;
$$;
create trigger profile_links_default_visibility
  before insert on public.profile_links
  for each row execute function public.profile_links_default_visibility();

create table public.flock_memberships (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  flock_id   uuid not null references public.flocks (id) on delete restrict,
  role       text not null default 'member' check (role in ('leader', 'co_leader', 'member')),
  started_on date not null default current_date,
  ended_on   date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ended_on is null or ended_on >= started_on)
);
create unique index flock_memberships_one_current_idx
  on public.flock_memberships (profile_id) where ended_on is null;
create index flock_memberships_flock_idx on public.flock_memberships (flock_id);

-- ---------------------------------------------------------------------------
-- Who is signed in
-- ---------------------------------------------------------------------------

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.profiles where user_id = auth.uid() and archived_at is null;
$$;

-- A member is someone signed in whose profile is published or under review.
create or replace function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
     where user_id = auth.uid() and archived_at is null
       and status in ('submitted', 'published')
  );
$$;

-- On first sign-in: link the profile staff made for this email, and grant
-- staff rights if the email was invited.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  invited_role text;
begin
  update public.profiles
     set user_id = new.id
   where email = lower(new.email) and user_id is null;

  select role into invited_role from public.staff_invites where email = lower(new.email);
  if invited_role is not null then
    insert into public.staff_roles (user_id, role) values (new.id, invited_role)
      on conflict (user_id) do nothing;
  end if;
  return new;
end;
$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- What a member may change on their own profile
-- ---------------------------------------------------------------------------

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  public_fields text[] := array['full_name', 'photo_media_id', 'profession', 'fun_fact', 'bio', 'personality_key', 'show_personality'];
  f text;
  pending jsonb := '{}'::jsonb;
  new_j jsonb := to_jsonb(new);
  old_j jsonb := to_jsonb(old);
begin
  if public.is_staff() or auth.uid() is null then
    return new;  -- staff, and server code using the service role
  end if;

  -- Fields only staff set.
  new.user_id     := old.user_id;
  new.email       := old.email;
  new.slug        := old.slug;
  new.is_featured := old.is_featured;
  new.sort_order  := old.sort_order;
  new.joined_on   := old.joined_on;
  new.review_note := old.review_note;
  new.archived_at := old.archived_at;
  new.pending_changes := old.pending_changes;

  if old.status = 'published' then
    -- Keep the published version up and park the edits for review.
    foreach f in array public_fields loop
      if (new_j -> f) is distinct from (old_j -> f) then
        pending := pending || jsonb_build_object(f, new_j -> f);
      end if;
    end loop;
    if pending <> '{}'::jsonb then
      new.pending_changes := coalesce(old.pending_changes, '{}'::jsonb) || pending;
      new.full_name        := old.full_name;
      new.photo_media_id   := old.photo_media_id;
      new.profession       := old.profession;
      new.fun_fact         := old.fun_fact;
      new.bio              := old.bio;
      new.personality_key  := old.personality_key;
      new.show_personality := old.show_personality;
    end if;
    new.status := 'published';
  else
    -- Not yet published: a member can move between draft and submitted only.
    if new.status not in ('draft', 'submitted') then
      new.status := old.status;
    end if;
  end if;
  return new;
end;
$$;
create trigger profiles_guard_update
  before update on public.profiles
  for each row execute function public.guard_profile_update();

-- Staff approve parked edits by calling this.
create or replace function public.approve_profile_changes(p_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  p jsonb;
begin
  if not public.is_staff() then
    raise exception 'Only staff can approve profile changes';
  end if;
  select pending_changes into p from public.profiles where id = p_profile_id;
  if p is null then
    return;
  end if;
  update public.profiles set
    full_name        = coalesce(p ->> 'full_name', full_name),
    photo_media_id   = case when p ? 'photo_media_id' then (p ->> 'photo_media_id')::uuid else photo_media_id end,
    profession       = case when p ? 'profession' then p ->> 'profession' else profession end,
    fun_fact         = case when p ? 'fun_fact' then p ->> 'fun_fact' else fun_fact end,
    bio              = case when p ? 'bio' then p ->> 'bio' else bio end,
    personality_key  = case when p ? 'personality_key' then p ->> 'personality_key' else personality_key end,
    show_personality = case when p ? 'show_personality' then (p ->> 'show_personality')::boolean else show_personality end,
    pending_changes  = null
  where id = p_profile_id;
end;
$$;
revoke execute on function public.approve_profile_changes(uuid) from public, anon;
grant execute on function public.approve_profile_changes(uuid) to authenticated;

select public.track_table('public.personality_types');
select public.track_table('public.flocks');
select public.track_table('public.profiles');
select public.track_table('public.profile_links');
select public.track_table('public.flock_memberships');

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------

alter table public.personality_types enable row level security;
alter table public.flocks            enable row level security;
alter table public.profiles          enable row level security;
alter table public.profile_links     enable row level security;
alter table public.flock_memberships enable row level security;

revoke all on public.personality_types, public.flocks, public.profiles, public.profile_links, public.flock_memberships
  from anon, authenticated;

-- Personality types and flocks: public read, staff write.
grant select on public.personality_types, public.flocks to anon, authenticated;
grant insert, update, delete on public.personality_types, public.flocks to authenticated;
create policy "personality types are public" on public.personality_types
  for select to anon, authenticated using (true);
create policy "staff manage personality types" on public.personality_types
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "active flocks are public" on public.flocks
  for select to anon, authenticated using (archived_at is null or public.is_staff());
create policy "staff manage flocks" on public.flocks
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- Profiles. Email, pending edits and review notes are left out of the
-- public column grant, so no visitor or other member can read them.
grant select (id, slug, full_name, photo_media_id, profession, fun_fact, bio,
              personality_key, show_personality, joined_on, status, is_featured,
              sort_order, archived_at, created_at, updated_at, user_id)
  on public.profiles to anon, authenticated;
-- The update grant covers staff-only columns too, because column grants are
-- per role, not per person. guard_profile_update() resets those columns for
-- anyone who is not staff.
grant update (full_name, photo_media_id, profession, fun_fact, bio, personality_key,
              show_personality, status, consent_at, slug, email, is_featured, sort_order,
              joined_on, review_note, archived_at)
  on public.profiles to authenticated;
grant insert, delete on public.profiles to authenticated;
create policy "published profiles are public" on public.profiles
  for select to anon, authenticated
  using ((status = 'published' and archived_at is null) or user_id = auth.uid() or public.is_staff());
create policy "members edit their own profile" on public.profiles
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
-- Staff get full access, including email and pending edits, through a
-- separate function rather than a broad column grant to every signed-in user.
create or replace function public.profile_private(p_profile_id uuid)
returns table (email text, pending_changes jsonb, review_note text, consent_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select email, pending_changes, review_note, consent_at
    from public.profiles
   where id = p_profile_id
     and (public.is_staff() or user_id = auth.uid());
$$;
revoke execute on function public.profile_private(uuid) from public, anon;
grant execute on function public.profile_private(uuid) to authenticated;
create policy "staff manage profiles" on public.profiles
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
-- Staff approve parked edits with approve_profile_changes().
-- Staff read email and parked edits with profile_private().

-- Contact links: each one public or members-only.
grant select, insert, update, delete on public.profile_links to authenticated;
grant select on public.profile_links to anon;
create policy "public links of published profiles" on public.profile_links
  for select to anon, authenticated
  using (
    visibility = 'public'
    and exists (select 1 from public.profiles p
                 where p.id = profile_id and p.status = 'published' and p.archived_at is null)
  );
create policy "members see members-only links" on public.profile_links
  for select to authenticated
  using (
    public.is_member()
    and exists (select 1 from public.profiles p
                 where p.id = profile_id and p.status = 'published' and p.archived_at is null)
  );
create policy "members manage their own links" on public.profile_links
  for all to authenticated
  using (profile_id = public.current_profile_id())
  with check (profile_id = public.current_profile_id());
create policy "staff manage links" on public.profile_links
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- Memberships: public for published profiles, staff write.
grant select on public.flock_memberships to anon, authenticated;
grant insert, update, delete on public.flock_memberships to authenticated;
create policy "memberships of published profiles are public" on public.flock_memberships
  for select to anon, authenticated
  using (
    exists (select 1 from public.profiles p
             where p.id = profile_id and ((p.status = 'published' and p.archived_at is null) or p.user_id = auth.uid()))
    or public.is_staff()
  );
create policy "staff manage memberships" on public.flock_memberships
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- Members upload their own avatar and article images.
create policy "members add their own media" on public.media
  for insert to authenticated
  with check (uploaded_by = auth.uid() and bucket in ('avatars', 'articles') and public.current_profile_id() is not null);
