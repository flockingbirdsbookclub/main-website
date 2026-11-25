-- Content: partners, books, reading cycles, Socials, albums, photo tags,
-- testimonials. Design: docs/DATA_MODEL.md.

create table public.partners (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique check (public.is_valid_slug(slug)),
  name           text not null,
  kind           text not null check (kind in ('bookshop', 'merch', 'gifting', 'venue', 'other')),
  role           text not null,
  member_offer   text,
  image_media_id uuid references public.media (id) on delete set null,
  url            text,
  is_active      boolean not null default true,
  sort_order     int not null default 0,
  archived_at    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table public.books (
  id               uuid primary key default gen_random_uuid(),
  slug             text not null unique check (public.is_valid_slug(slug)),
  title            text not null,
  author           text not null,
  tag              text, -- "Heavy", "Lighter"
  blurb            text,
  cover_media_id   uuid references public.media (id) on delete set null,
  purchase_url     text,
  store_partner_id uuid references public.partners (id) on delete set null,
  archived_at      timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- When a book was or is being read. flock_id null means the whole club.
-- Dates are optional for older books whose dates were never recorded;
-- sort_order then keeps the shelf in order.
create table public.reading_cycles (
  id         uuid primary key default gen_random_uuid(),
  book_id    uuid not null references public.books (id) on delete cascade,
  flock_id   uuid references public.flocks (id) on delete cascade,
  starts_on  date,
  ends_on    date,
  note       text,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_on is null or starts_on is null or ends_on >= starts_on)
);
create index reading_cycles_book_idx on public.reading_cycles (book_id);
create index reading_cycles_dates_idx on public.reading_cycles (starts_on, ends_on);

create table public.events (
  id              uuid primary key default gen_random_uuid(),
  slug            text not null unique check (public.is_valid_slug(slug)),
  number          text,
  heading         text not null,
  edition         text,
  tagline         text,
  description     text,
  starts_at       timestamptz not null,
  ends_at         timestamptz not null,
  venue_name      text,
  venue_address   text,
  price_kes       int check (price_kes >= 0),
  price_note      text,
  who             text,
  bring           text,
  poster_media_id uuid references public.media (id) on delete set null,
  book_id         uuid references public.books (id) on delete set null,
  recap_title     text,
  recap_body      text,
  status          text not null default 'draft' check (status in ('draft', 'published')),
  archived_at     timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index events_status_starts_idx on public.events (status, starts_at);

create table public.event_speakers (
  id             uuid primary key default gen_random_uuid(),
  event_id       uuid not null references public.events (id) on delete cascade,
  name           text not null,
  title          text,
  organisation   text,
  talk_title     text,
  photo_media_id uuid references public.media (id) on delete set null,
  profile_id     uuid references public.profiles (id) on delete set null,
  sort_order     int not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index event_speakers_event_idx on public.event_speakers (event_id);

create table public.event_rsvps (
  id            uuid primary key default gen_random_uuid(),
  event_id      uuid not null references public.events (id) on delete cascade,
  profile_id    uuid references public.profiles (id) on delete set null,
  name          text not null,
  phone         text,
  email         text,
  party_size    text,
  member_status text,
  attended      boolean,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index event_rsvps_event_idx on public.event_rsvps (event_id);

create table public.albums (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique check (public.is_valid_slug(slug)),
  title          text not null,
  taken_on       date,
  event_id       uuid references public.events (id) on delete set null,
  flock_id       uuid references public.flocks (id) on delete set null,
  cover_media_id uuid references public.media (id) on delete set null,
  status         text not null default 'draft' check (status in ('draft', 'published')),
  archived_at    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table public.album_photos (
  id         uuid primary key default gen_random_uuid(),
  album_id   uuid not null references public.albums (id) on delete cascade,
  media_id   uuid not null references public.media (id) on delete cascade,
  caption    text,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (album_id, media_id)
);

create table public.photo_tags (
  id         uuid primary key default gen_random_uuid(),
  media_id   uuid not null references public.media (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  tagged_by  uuid references auth.users (id) on delete set null,
  status     text not null default 'pending' check (status in ('pending', 'approved', 'declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (media_id, profile_id)
);
create index photo_tags_profile_idx on public.photo_tags (profile_id);

create table public.testimonials (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles (id) on delete set null,
  quote      text not null,
  name       text not null,
  flock_id   uuid references public.flocks (id) on delete set null,
  consent_at timestamptz,
  status     text not null default 'draft' check (status in ('draft', 'published')),
  sort_order int not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint published_needs_consent check (status <> 'published' or consent_at is not null)
);

select public.track_table('public.partners');
select public.track_table('public.books');
select public.track_table('public.reading_cycles');
select public.track_table('public.events');
select public.track_table('public.event_speakers');
select public.track_table('public.event_rsvps');
select public.track_table('public.albums');
select public.track_table('public.album_photos');
select public.track_table('public.photo_tags');
select public.track_table('public.testimonials');

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------

alter table public.partners       enable row level security;
alter table public.books          enable row level security;
alter table public.reading_cycles enable row level security;
alter table public.events         enable row level security;
alter table public.event_speakers enable row level security;
alter table public.event_rsvps    enable row level security;
alter table public.albums         enable row level security;
alter table public.album_photos   enable row level security;
alter table public.photo_tags     enable row level security;
alter table public.testimonials   enable row level security;

revoke all on public.partners, public.books, public.reading_cycles, public.events,
  public.event_speakers, public.event_rsvps, public.albums, public.album_photos,
  public.photo_tags, public.testimonials
  from anon, authenticated;

grant select on public.partners, public.books, public.reading_cycles, public.events,
  public.event_speakers, public.albums, public.album_photos, public.photo_tags,
  public.testimonials
  to anon, authenticated;
grant insert, update, delete on public.partners, public.books, public.reading_cycles,
  public.events, public.event_speakers, public.albums, public.album_photos,
  public.photo_tags, public.testimonials
  to authenticated;

-- Public reads
create policy "active partners are public" on public.partners
  for select to anon, authenticated using ((is_active and archived_at is null) or public.is_staff());
create policy "books are public" on public.books
  for select to anon, authenticated using (archived_at is null or public.is_staff());
create policy "reading cycles are public" on public.reading_cycles
  for select to anon, authenticated using (true);
create policy "published events are public" on public.events
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());
create policy "speakers of published events are public" on public.event_speakers
  for select to anon, authenticated
  using (exists (select 1 from public.events e where e.id = event_id and e.status = 'published' and e.archived_at is null)
         or public.is_staff());
create policy "published albums are public" on public.albums
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());
create policy "photos in published albums are public" on public.album_photos
  for select to anon, authenticated
  using (exists (select 1 from public.albums a where a.id = album_id and a.status = 'published' and a.archived_at is null)
         or public.is_staff());
create policy "approved tags are public" on public.photo_tags
  for select to anon, authenticated
  using (status = 'approved' or profile_id = public.current_profile_id() or public.is_staff());
create policy "published testimonials are public" on public.testimonials
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());

-- Staff write
create policy "staff manage partners" on public.partners
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage books" on public.books
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage reading cycles" on public.reading_cycles
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage events" on public.events
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage speakers" on public.event_speakers
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage albums" on public.albums
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage album photos" on public.album_photos
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage photo tags" on public.photo_tags
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage testimonials" on public.testimonials
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- A member approves or declines tags of themselves, and nothing else.
grant update (status) on public.photo_tags to authenticated;
create policy "members answer their own tags" on public.photo_tags
  for update to authenticated
  using (profile_id = public.current_profile_id())
  with check (profile_id = public.current_profile_id() and status in ('approved', 'declined'));

-- RSVPs: written by server code (service role). Staff read and tick
-- attendance; a member reads their own.
grant select, update on public.event_rsvps to authenticated;
create policy "staff and the member read rsvps" on public.event_rsvps
  for select to authenticated using (public.is_staff() or profile_id = public.current_profile_id());
create policy "staff update rsvps" on public.event_rsvps
  for update to authenticated using (public.is_staff()) with check (public.is_staff());

-- ---------------------------------------------------------------------------
-- Views the pages read
-- ---------------------------------------------------------------------------

-- The next Social: earliest published event that has not ended.
create view public.next_event with (security_invoker = on) as
  select * from public.events
   where status = 'published' and archived_at is null and ends_at > now()
   order by starts_at
   limit 1;

-- Past Socials, newest first.
create view public.past_events with (security_invoker = on) as
  select * from public.events
   where status = 'published' and archived_at is null and ends_at <= now()
   order by starts_at desc;

-- Current read: the club-wide cycle covering today.
create view public.current_reads with (security_invoker = on) as
  select b.*, c.starts_on, c.ends_on, c.id as cycle_id
    from public.reading_cycles c
    join public.books b on b.id = c.book_id
   where c.flock_id is null and b.archived_at is null
     and c.starts_on <= current_date and (c.ends_on is null or c.ends_on >= current_date);

-- Shelf: club-wide books already read, most recent first.
create view public.shelf with (security_invoker = on) as
  select b.*, c.starts_on, c.ends_on, c.sort_order as shelf_order
    from public.reading_cycles c
    join public.books b on b.id = c.book_id
   where c.flock_id is null and b.archived_at is null
     and (c.ends_on < current_date or (c.starts_on is null and c.ends_on is null));

grant select on public.next_event, public.past_events, public.current_reads, public.shelf to anon, authenticated;
