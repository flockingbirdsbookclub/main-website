-- Blog: member articles, attributed to their profile. Design: docs/DATA_MODEL.md.

create table public.articles (
  id                uuid primary key default gen_random_uuid(),
  slug              text not null unique check (public.is_valid_slug(slug)),
  author_profile_id uuid not null references public.profiles (id) on delete restrict,
  title             text not null,
  excerpt           text,
  body              text,
  external_url      text,
  cover_media_id    uuid references public.media (id) on delete set null,
  book_id           uuid references public.books (id) on delete set null,
  status            text not null default 'draft' check (status in ('draft', 'submitted', 'published', 'rejected')),
  review_note       text,
  submitted_at      timestamptz,
  published_at      timestamptz,
  reviewed_by       uuid references auth.users (id) on delete set null,
  archived_at       timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint body_or_link check (body is not null or external_url is not null or status = 'draft')
);
create index articles_author_idx on public.articles (author_profile_id);
create index articles_status_published_idx on public.articles (status, published_at desc);

create table public.tags (
  id         uuid primary key default gen_random_uuid(),
  slug       text not null unique check (public.is_valid_slug(slug)),
  name       text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.article_tags (
  article_id uuid not null references public.articles (id) on delete cascade,
  tag_id     uuid not null references public.tags (id) on delete cascade,
  primary key (article_id, tag_id)
);
create index article_tags_tag_idx on public.article_tags (tag_id);

-- What a member may do to their own article: write it, save a draft, submit
-- it. Publishing, rejecting and review notes are for staff.
create or replace function public.guard_article_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'submitted' and (tg_op = 'INSERT' or old.status <> 'submitted') then
    new.submitted_at := now();
  end if;
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;

  if public.is_staff() or auth.uid() is null then
    if new.status in ('published', 'rejected') and (tg_op = 'INSERT' or old.status is distinct from new.status) then
      new.reviewed_by := coalesce(auth.uid(), new.reviewed_by);
    end if;
    return new;
  end if;

  -- Editing a returned article turns it back into a draft.
  if tg_op = 'UPDATE' and old.status = 'rejected' and new.status = 'rejected' then
    new.status := 'draft';
  end if;
  if new.status not in ('draft', 'submitted') then
    raise exception 'Members can save a draft or submit an article, not publish it';
  end if;
  if tg_op = 'UPDATE' then
    new.author_profile_id := old.author_profile_id;
    new.review_note       := old.review_note;
    new.reviewed_by       := old.reviewed_by;
    new.published_at      := old.published_at;
    new.archived_at       := old.archived_at;
  else
    new.review_note  := null;
    new.reviewed_by  := null;
    new.published_at := null;
  end if;
  return new;
end;
$$;
create trigger articles_guard_write
  before insert or update on public.articles
  for each row execute function public.guard_article_write();

select public.track_table('public.articles');
select public.track_table('public.tags');
select public.track_table('public.article_tags');

alter table public.articles     enable row level security;
alter table public.tags         enable row level security;
alter table public.article_tags enable row level security;

revoke all on public.articles, public.tags, public.article_tags from anon, authenticated;
grant select on public.articles, public.tags, public.article_tags to anon, authenticated;
grant insert, update, delete on public.articles, public.tags, public.article_tags to authenticated;

create policy "published articles are public" on public.articles
  for select to anon, authenticated
  using ((status = 'published' and archived_at is null)
         or author_profile_id = public.current_profile_id()
         or public.is_staff());
create policy "members write their own articles" on public.articles
  for insert to authenticated
  with check (author_profile_id = public.current_profile_id());
-- Only while the article is not yet published.
create policy "members edit their own unpublished articles" on public.articles
  for update to authenticated
  using (author_profile_id = public.current_profile_id() and status in ('draft', 'submitted', 'rejected'))
  with check (author_profile_id = public.current_profile_id());
create policy "members delete their own drafts" on public.articles
  for delete to authenticated
  using (author_profile_id = public.current_profile_id() and status in ('draft', 'rejected'));
create policy "staff manage articles" on public.articles
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

create policy "tags are public" on public.tags
  for select to anon, authenticated using (true);
create policy "staff manage tags" on public.tags
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

create policy "tags on visible articles are public" on public.article_tags
  for select to anon, authenticated
  using (exists (select 1 from public.articles a where a.id = article_id));
create policy "authors tag their own unpublished articles" on public.article_tags
  for all to authenticated
  using (exists (select 1 from public.articles a
                  where a.id = article_id and a.author_profile_id = public.current_profile_id()
                    and a.status in ('draft', 'submitted', 'rejected')))
  with check (exists (select 1 from public.articles a
                       where a.id = article_id and a.author_profile_id = public.current_profile_id()
                         and a.status in ('draft', 'submitted', 'rejected')));
create policy "staff manage article tags" on public.article_tags
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
