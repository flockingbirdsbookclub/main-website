-- A `data` JSON object on the main tables, for extra details that don't
-- deserve their own column yet: a Social's dress code, a partner's discount
-- code, a product's care instructions.
--
-- Rules (see "The data field" in docs/DATA_MODEL.md):
-- - Always a JSON object, defaulting to {}. At most 32 KB.
-- - As public as its row. Never put anything private in it.
-- - If a page filters, sorts or joins on a key, or it must always be there,
--   promote it to a real column with its own type and check.
-- - Bookkeeping (created_at, updated_at, status) stays in columns.

do $$
declare
  t text;
begin
  foreach t in array array[
    'media', 'profiles', 'flocks', 'personality_types',
    'partners', 'authors', 'books', 'reading_cycles', 'venues', 'events', 'speakers',
    'event_rsvps', 'albums', 'testimonials',
    'articles', 'seasons', 'awards',
    'merch_drops', 'merch_products', 'merch_variants', 'merch_orders',
    'games', 'game_attempts']
  loop
    execute format(
      'alter table public.%I add column data jsonb not null default %L::jsonb', t, '{}');
    execute format(
      'alter table public.%I add constraint %I check (jsonb_typeof(data) = %L and octet_length(data::text) <= 32768)',
      t, t || '_data_is_small_object', 'object');
  end loop;
end
$$;

-- profiles uses column-level grants, so the new column must be granted.
-- Staff set it; guard_profile_update() below keeps members from changing it.
grant select (data) on public.profiles to anon, authenticated;
grant update (data) on public.profiles to authenticated;

create or replace function public.guard_profile_data()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not (private.is_staff() or auth.uid() is null) then
    new.data := old.data;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_profile_data() from public, anon, authenticated;
create trigger profiles_guard_data
  before update of data on public.profiles
  for each row execute function public.guard_profile_data();

-- Views the pages read get the new column, added at the end as
-- `create or replace view` requires.

create or replace view public.event_cards with (security_invoker = on) as
  select e.id, e.slug, e.kind, e.number, e.heading, e.edition, e.tagline, e.description,
         e.starts_at, e.ends_at, e.price_kes, e.price_note, e.who, e.bring,
         e.poster_media_id, e.book_id, e.recap_title, e.recap_body,
         v.name as venue_name, v.address as venue_address, v.map_url as venue_map_url,
         e.data
    from public.events e
    left join public.venues v on v.id = e.venue_id
   where e.status = 'published' and e.archived_at is null;

create or replace view public.next_event with (security_invoker = on) as
  select id, slug, kind, number, heading, edition, tagline, description,
         starts_at, ends_at, price_kes, price_note, who, bring,
         poster_media_id, book_id, recap_title, recap_body,
         venue_name, venue_address, venue_map_url, data
    from public.event_cards
   where ends_at > now() and kind = 'social'
   order by starts_at
   limit 1;

create or replace view public.past_events with (security_invoker = on) as
  select id, slug, kind, number, heading, edition, tagline, description,
         starts_at, ends_at, price_kes, price_note, who, bring,
         poster_media_id, book_id, recap_title, recap_body,
         venue_name, venue_address, venue_map_url, data
    from public.event_cards
   where ends_at <= now() and kind = 'social'
   order by starts_at desc;

create or replace view public.book_cards with (security_invoker = on) as
  select b.id, b.slug, b.title, b.reading_weight, b.blurb, b.cover_media_id,
         coalesce(string_agg(a.name, ' & ' order by ba.position), '') as authors,
         b.data
    from public.books b
    left join public.book_authors ba on ba.book_id = b.id
    left join public.authors a on a.id = ba.author_id
   where b.archived_at is null
   group by b.id;

create or replace view public.current_reads with (security_invoker = on) as
  select bc.id, bc.slug, bc.title, bc.reading_weight, bc.blurb, bc.cover_media_id, bc.authors,
         c.id as cycle_id, c.starts_on, c.ends_on, bc.data
    from public.reading_cycles c
    join public.book_cards bc on bc.id = c.book_id
   where c.flock_id is null
     and c.starts_on <= current_date and (c.ends_on is null or c.ends_on >= current_date);

create or replace view public.shelf with (security_invoker = on) as
  select bc.id, bc.slug, bc.title, bc.reading_weight, bc.blurb, bc.cover_media_id, bc.authors,
         c.id as cycle_id, c.starts_on, c.ends_on, c.sort_order, bc.data
    from public.reading_cycles c
    join public.book_cards bc on bc.id = c.book_id
   where c.flock_id is null
     and (c.ends_on < current_date or (c.starts_on is null and c.ends_on is null))
   order by c.ends_on desc nulls last, c.sort_order;

create or replace view public.mural_entries with (security_invoker = on) as
  select p.id, p.slug, p.full_name, p.photo_media_id, p.profession, p.fun_fact,
         case when p.show_personality then p.personality_key end as personality_key,
         p.is_featured, p.sort_order,
         f.id as flock_id, f.slug as flock_slug, f.name as flock_name,
         m.role as flock_role,
         case m.role when 'leader' then 0 when 'co_leader' then 1
                     else case when p.is_featured then 2 else 3 end end as mural_group,
         p.data
    from public.profiles p
    left join public.flock_memberships m on m.profile_id = p.id and m.ended_on is null
    left join public.flocks f on f.id = m.flock_id
   where p.status = 'published' and p.archived_at is null;

create or replace view public.merch_variant_cards with (security_invoker = on) as
  select v.id, v.product_id, v.sku, v.is_available,
         coalesce(v.price_override_kes, p.price_kes) as price_kes,
         coalesce(v.external_url, p.external_url) as external_url,
         coalesce(string_agg(ov.value, ' / ' order by o.sort_order), '') as label,
         v.data
    from public.merch_variants v
    join public.merch_products p on p.id = v.product_id
    left join public.merch_variant_values vv on vv.variant_id = v.id
    left join public.merch_options o on o.id = vv.option_id
    left join public.merch_option_values ov on ov.id = vv.option_value_id
   group by v.id, p.price_kes, p.external_url;
