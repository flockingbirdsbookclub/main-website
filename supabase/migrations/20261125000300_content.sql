-- Content: partners, books and authors, reading cycles, venues, Socials and
-- speakers, RSVPs, albums, photo tags, testimonials.
-- Design: docs/DATA_MODEL.md.
--
-- Normalised: each fact is stored once. A venue, speaker or author used by
-- many rows is its own table. Vocabularies that grow (partner kinds, event
-- kinds) are lookup tables, so a new one is a row, not a migration.

-- ---------------------------------------------------------------------------
-- Partners
-- ---------------------------------------------------------------------------

create table public.partner_kinds (
  key        text primary key check (key ~ '^[a-z0-9_]+$'),
  label      text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.partners (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique check (public.is_valid_slug(slug)),
  name           text not null,
  kind           text not null references public.partner_kinds (key) on update cascade,
  description    text,          -- "Embossed “From the library of” stamps"
  member_offer   text,          -- "10% off for members"
  image_media_id uuid references public.media (id) on delete set null,
  url            text check (url ~ '^https?://'),
  is_active      boolean not null default true,
  sort_order     int not null default 0,
  archived_at    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index partners_kind_idx on public.partners (kind);

-- ---------------------------------------------------------------------------
-- Books
-- ---------------------------------------------------------------------------

create table public.authors (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique check (public.is_valid_slug(slug)),
  name        text not null,
  archived_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table public.books (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique check (public.is_valid_slug(slug)),
  title          text not null,
  reading_weight text check (reading_weight in ('heavy', 'lighter')),
  blurb          text,
  cover_media_id uuid references public.media (id) on delete set null,
  archived_at    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- A book can have several authors, in a set order.
create table public.book_authors (
  book_id    uuid not null references public.books (id) on delete cascade,
  author_id  uuid not null references public.authors (id) on delete restrict,
  position   int not null default 1 check (position > 0),
  created_at timestamptz not null default now(),
  primary key (book_id, author_id),
  unique (book_id, position)
);
create index book_authors_author_idx on public.book_authors (author_id);

-- Where to buy a book. Several shops per book, usually a partner bookshop.
create table public.book_purchase_links (
  id         uuid primary key default gen_random_uuid(),
  book_id    uuid not null references public.books (id) on delete cascade,
  partner_id uuid references public.partners (id) on delete set null,
  url        text not null check (url ~ '^https?://'),
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (book_id, url)
);
create index book_purchase_links_book_idx on public.book_purchase_links (book_id, sort_order);
create index book_purchase_links_partner_idx on public.book_purchase_links (partner_id);

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
create index reading_cycles_flock_idx on public.reading_cycles (flock_id);
create index reading_cycles_dates_idx on public.reading_cycles (starts_on, ends_on);

-- ---------------------------------------------------------------------------
-- Socials
-- ---------------------------------------------------------------------------

create table public.venues (
  id         uuid primary key default gen_random_uuid(),
  slug       text not null unique check (public.is_valid_slug(slug)),
  name       text not null,
  address    text,
  map_url    text check (map_url ~ '^https?://'),
  partner_id uuid references public.partners (id) on delete set null,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.event_kinds (
  key        text primary key check (key ~ '^[a-z0-9_]+$'),
  label      text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.events (
  id              uuid primary key default gen_random_uuid(),
  slug            text not null unique check (public.is_valid_slug(slug)),
  kind            text not null default 'social' references public.event_kinds (key) on update cascade,
  number          text,          -- "4.0"
  heading         text not null, -- "BookClub Social 4.0"
  edition         text,
  tagline         text,
  description     text,
  starts_at       timestamptz not null,
  ends_at         timestamptz not null,
  venue_id        uuid references public.venues (id) on delete set null,
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
create index events_venue_idx on public.events (venue_id);
create index events_book_idx on public.events (book_id);

-- A speaker is a person, who may speak at several Socials.
create table public.speakers (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique check (public.is_valid_slug(slug)),
  name           text not null,
  title          text,
  organisation   text,
  bio            text,
  photo_media_id uuid references public.media (id) on delete set null,
  profile_id     uuid unique references public.profiles (id) on delete set null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table public.event_speakers (
  event_id   uuid not null references public.events (id) on delete cascade,
  speaker_id uuid not null references public.speakers (id) on delete restrict,
  talk_title text,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, speaker_id)
);
create index event_speakers_speaker_idx on public.event_speakers (speaker_id);

-- An RSVP keeps the name and phone given at the time, because most people
-- who RSVP are not members and have no profile.
create table public.event_rsvps (
  id            uuid primary key default gen_random_uuid(),
  event_id      uuid not null references public.events (id) on delete cascade,
  profile_id    uuid references public.profiles (id) on delete set null,
  name          text not null,
  phone         text,
  email         text check (email = lower(email)),
  guests        int not null default 0 check (guests between 0 and 20),
  member_status text check (member_status in ('member', 'first_time', 'returning')),
  attended      boolean,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index event_rsvps_event_idx on public.event_rsvps (event_id);
create index event_rsvps_profile_idx on public.event_rsvps (profile_id);

-- ---------------------------------------------------------------------------
-- Photos
-- ---------------------------------------------------------------------------

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
create index albums_event_idx on public.albums (event_id);
create index albums_flock_idx on public.albums (flock_id);

create table public.album_photos (
  album_id   uuid not null references public.albums (id) on delete cascade,
  media_id   uuid not null references public.media (id) on delete cascade,
  caption    text,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (album_id, media_id)
);
create index album_photos_media_idx on public.album_photos (media_id);

create table public.photo_tags (
  media_id   uuid not null references public.media (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  tagged_by  uuid references auth.users (id) on delete set null,
  status     text not null default 'pending' check (status in ('pending', 'approved', 'declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (media_id, profile_id)
);
create index photo_tags_profile_idx on public.photo_tags (profile_id);

-- ---------------------------------------------------------------------------
-- Testimonials
-- ---------------------------------------------------------------------------

-- Attributed either to a member's profile, or to a name for someone without
-- one, never both, so the name is never stored twice.
create table public.testimonials (
  id              uuid primary key default gen_random_uuid(),
  quote           text not null,
  profile_id      uuid references public.profiles (id) on delete cascade,
  author_name     text,
  author_flock_id uuid references public.flocks (id) on delete set null,
  consent_at      timestamptz,
  status          text not null default 'draft' check (status in ('draft', 'published')),
  sort_order      int not null default 0,
  archived_at     timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint one_attribution check ((profile_id is null) <> (author_name is null)),
  constraint flock_only_without_profile check (profile_id is null or author_flock_id is null),
  constraint published_needs_consent check (status <> 'published' or consent_at is not null)
);
create index testimonials_profile_idx on public.testimonials (profile_id);

select public.track_table('public.partner_kinds');
select public.track_table('public.partners');
select public.track_table('public.authors');
select public.track_table('public.books');
select public.track_table('public.book_authors');
select public.track_table('public.book_purchase_links');
select public.track_table('public.reading_cycles');
select public.track_table('public.venues');
select public.track_table('public.event_kinds');
select public.track_table('public.events');
select public.track_table('public.speakers');
select public.track_table('public.event_speakers');
select public.track_table('public.event_rsvps');
select public.track_table('public.albums');
select public.track_table('public.album_photos');
select public.track_table('public.photo_tags');
select public.track_table('public.testimonials');

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
begin
  foreach t in array array['partner_kinds', 'partners', 'authors', 'books', 'book_authors',
    'book_purchase_links', 'reading_cycles', 'venues', 'event_kinds', 'events', 'speakers',
    'event_speakers', 'event_rsvps', 'albums', 'album_photos', 'photo_tags', 'testimonials']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    if t <> 'event_rsvps' then
      execute format('grant select on public.%I to anon, authenticated', t);
      execute format('grant insert, update, delete on public.%I to authenticated', t);
      execute format(
        'create policy %I on public.%I for all to authenticated using (public.is_staff()) with check (public.is_staff())',
        'staff manage ' || replace(t, '_', ' '), t);
    end if;
  end loop;
end
$$;

-- Public reads. Staff also read drafts and archived rows.
create policy "partner kinds are public" on public.partner_kinds
  for select to anon, authenticated using (true);
create policy "active partners are public" on public.partners
  for select to anon, authenticated using ((is_active and archived_at is null) or public.is_staff());
create policy "authors are public" on public.authors
  for select to anon, authenticated using (archived_at is null or public.is_staff());
create policy "books are public" on public.books
  for select to anon, authenticated using (archived_at is null or public.is_staff());
create policy "book authors are public" on public.book_authors
  for select to anon, authenticated using (true);
create policy "purchase links are public" on public.book_purchase_links
  for select to anon, authenticated using (true);
create policy "reading cycles are public" on public.reading_cycles
  for select to anon, authenticated using (true);
create policy "venues are public" on public.venues
  for select to anon, authenticated using (archived_at is null or public.is_staff());
create policy "event kinds are public" on public.event_kinds
  for select to anon, authenticated using (true);
create policy "published events are public" on public.events
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());
create policy "speakers are public" on public.speakers
  for select to anon, authenticated using (true);
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

-- A member approves or declines tags of themselves, and nothing else.
grant update (status) on public.photo_tags to authenticated;
create policy "members answer their own tags" on public.photo_tags
  for update to authenticated
  using (profile_id = public.current_profile_id())
  with check (profile_id = public.current_profile_id() and status in ('approved', 'declined'));

-- RSVPs: written by server code (secret key). Staff read and tick
-- attendance; a member reads their own.
grant select, update on public.event_rsvps to authenticated;
create policy "staff and the member read rsvps" on public.event_rsvps
  for select to authenticated using (public.is_staff() or profile_id = public.current_profile_id());
create policy "staff update rsvps" on public.event_rsvps
  for update to authenticated using (public.is_staff()) with check (public.is_staff());

-- ---------------------------------------------------------------------------
-- Views the pages read
-- ---------------------------------------------------------------------------
-- Columns are listed, never `select *`: Postgres fixes a view's columns when
-- it is created, so a `*` view would silently miss columns added later.
-- When you add a column a page needs, add it to the view in the same migration.

-- One row per event, with its venue, for every events page.
create view public.event_cards with (security_invoker = on) as
  select e.id, e.slug, e.kind, e.number, e.heading, e.edition, e.tagline, e.description,
         e.starts_at, e.ends_at, e.price_kes, e.price_note, e.who, e.bring,
         e.poster_media_id, e.book_id, e.recap_title, e.recap_body,
         v.name as venue_name, v.address as venue_address, v.map_url as venue_map_url
    from public.events e
    left join public.venues v on v.id = e.venue_id
   where e.status = 'published' and e.archived_at is null;

-- The next Social: the earliest published event that has not ended.
create view public.next_event with (security_invoker = on) as
  select id, slug, kind, number, heading, edition, tagline, description,
         starts_at, ends_at, price_kes, price_note, who, bring,
         poster_media_id, book_id, recap_title, recap_body,
         venue_name, venue_address, venue_map_url
    from public.event_cards
   where ends_at > now() and kind = 'social'
   order by starts_at
   limit 1;

-- Past Socials, newest first.
create view public.past_events with (security_invoker = on) as
  select id, slug, kind, number, heading, edition, tagline, description,
         starts_at, ends_at, price_kes, price_note, who, bring,
         poster_media_id, book_id, recap_title, recap_body,
         venue_name, venue_address, venue_map_url
    from public.event_cards
   where ends_at <= now() and kind = 'social'
   order by starts_at desc;

-- One row per book, with its authors joined in order: "Kim & Mauborgne".
create view public.book_cards with (security_invoker = on) as
  select b.id, b.slug, b.title, b.reading_weight, b.blurb, b.cover_media_id,
         coalesce(string_agg(a.name, ' & ' order by ba.position), '') as authors
    from public.books b
    left join public.book_authors ba on ba.book_id = b.id
    left join public.authors a on a.id = ba.author_id
   where b.archived_at is null
   group by b.id;

-- Current read: the club-wide cycle covering today.
create view public.current_reads with (security_invoker = on) as
  select bc.id, bc.slug, bc.title, bc.reading_weight, bc.blurb, bc.cover_media_id, bc.authors,
         c.id as cycle_id, c.starts_on, c.ends_on
    from public.reading_cycles c
    join public.book_cards bc on bc.id = c.book_id
   where c.flock_id is null
     and c.starts_on <= current_date and (c.ends_on is null or c.ends_on >= current_date);

-- Shelf: club-wide books already read. Dated cycles newest first, then the
-- undated older ones in their set order.
create view public.shelf with (security_invoker = on) as
  select bc.id, bc.slug, bc.title, bc.reading_weight, bc.blurb, bc.cover_media_id, bc.authors,
         c.id as cycle_id, c.starts_on, c.ends_on, c.sort_order
    from public.reading_cycles c
    join public.book_cards bc on bc.id = c.book_id
   where c.flock_id is null
     and (c.ends_on < current_date or (c.starts_on is null and c.ends_on is null))
   order by c.ends_on desc nulls last, c.sort_order;

grant select on public.event_cards, public.next_event, public.past_events, public.book_cards,
  public.current_reads, public.shelf
  to anon, authenticated;
