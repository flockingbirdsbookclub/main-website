-- Merch: drops (campaigns with a deadline and a minimum run), products and
-- their options, variants, photos, and orders for products we take preorders
-- on. Design: docs/DATA_MODEL.md.
--
-- Normalised the way most shops are: a product has options (Colour, Size),
-- each option has values (forest, M), and every combination someone can buy
-- is a variant. Orders point at variants. Totals are worked out from order
-- lines, never stored next to them.

create table public.merch_categories (
  key        text primary key check (key ~ '^[a-z0-9_]+$'),
  label      text not null,  -- "T-shirt"
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Brand colours used for swatches, stored once.
create table public.merch_colours (
  key        text primary key check (key ~ '^[a-z0-9_]+$'),
  label      text not null,
  hex        text not null check (hex ~ '^#[0-9A-F]{6}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.merch_drops (
  id               uuid primary key default gen_random_uuid(),
  slug             text not null unique check (public.is_valid_slug(slug)),
  name             text not null,
  description      text,
  opens_at         timestamptz,
  closes_at        timestamptz,
  collect_event_id uuid references public.events (id) on delete set null,
  status           text not null default 'draft' check (status in ('draft', 'published')),
  archived_at      timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  check (closes_at is null or opens_at is null or closes_at > opens_at)
);

create table public.merch_products (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique check (public.is_valid_slug(slug)),
  drop_id      uuid references public.merch_drops (id) on delete set null,
  partner_id   uuid references public.partners (id) on delete set null,
  category     text not null references public.merch_categories (key) on update cascade,
  name         text not null,
  description  text,
  price_kes    int not null check (price_kes >= 0),
  fulfilment   text not null default 'preorder' check (fulfilment in ('partner_store', 'preorder')),
  external_url text check (external_url ~ '^https?://'),
  min_run      int check (min_run > 0),
  status       text not null default 'draft' check (status in ('draft', 'published')),
  sort_order   int not null default 0,
  archived_at  timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint partner_store_needs_link check (fulfilment <> 'partner_store' or external_url is not null)
);
create index merch_products_drop_idx on public.merch_products (drop_id, sort_order);
create index merch_products_partner_idx on public.merch_products (partner_id);
create index merch_products_category_idx on public.merch_products (category);

-- "Colour", "Size", "Bird"
create table public.merch_options (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.merch_products (id) on delete cascade,
  label      text not null,
  is_swatch  boolean not null default false,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, label),
  unique (id, product_id)
);

-- "forest", "M", "Owl". A swatch value points at a brand colour.
create table public.merch_option_values (
  id         uuid primary key default gen_random_uuid(),
  option_id  uuid not null references public.merch_options (id) on delete cascade,
  value      text not null,
  colour_key text references public.merch_colours (key) on update cascade,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (option_id, value),
  unique (id, option_id)
);

-- A buyable combination. Price and partner link can differ per variant.
create table public.merch_variants (
  id                 uuid primary key default gen_random_uuid(),
  product_id         uuid not null references public.merch_products (id) on delete cascade,
  sku                text unique,
  price_override_kes int check (price_override_kes >= 0),
  external_url       text check (external_url ~ '^https?://'),
  is_available       boolean not null default true,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (id, product_id)
);
create index merch_variants_product_idx on public.merch_variants (product_id);

-- Which value a variant has for each option. The composite keys make sure
-- the value belongs to the option, the option belongs to the variant's
-- product, and a variant has one value per option.
create table public.merch_variant_values (
  variant_id      uuid not null,
  product_id      uuid not null,
  option_id       uuid not null,
  option_value_id uuid not null,
  primary key (variant_id, option_id),
  foreign key (variant_id, product_id) references public.merch_variants (id, product_id) on delete cascade,
  foreign key (option_id, product_id) references public.merch_options (id, product_id) on delete cascade,
  foreign key (option_value_id, option_id) references public.merch_option_values (id, option_id) on delete cascade
);
create index merch_variant_values_value_idx on public.merch_variant_values (option_value_id);

create table public.merch_product_media (
  product_id uuid not null references public.merch_products (id) on delete cascade,
  media_id   uuid not null references public.media (id) on delete cascade,
  sort_order int not null default 0,
  primary key (product_id, media_id)
);
create index merch_product_media_media_idx on public.merch_product_media (media_id);

-- An order keeps the name and phone given at the time (most buyers have no
-- profile) and the deposit percentage that applied, since settings change.
create table public.merch_orders (
  id          uuid primary key default gen_random_uuid(),
  drop_id     uuid references public.merch_drops (id) on delete set null,
  profile_id  uuid references public.profiles (id) on delete set null,
  name        text not null,
  phone       text not null,
  flock_id    uuid references public.flocks (id) on delete set null, -- null: not in a flock yet
  deposit_pct int not null check (deposit_pct between 0 and 100),
  mpesa_code  text,
  status      text not null default 'pending_deposit'
              check (status in ('pending_deposit', 'deposit_paid', 'paid', 'collected', 'refunded', 'cancelled')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index merch_orders_drop_idx on public.merch_orders (drop_id);
create index merch_orders_profile_idx on public.merch_orders (profile_id);

-- unit_price_kes is the price when ordered, deliberately kept: prices change.
create table public.merch_order_items (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references public.merch_orders (id) on delete cascade,
  variant_id     uuid not null references public.merch_variants (id) on delete restrict,
  qty            int not null check (qty > 0),
  unit_price_kes int not null check (unit_price_kes >= 0),
  created_at     timestamptz not null default now(),
  unique (order_id, variant_id)
);
create index merch_order_items_variant_idx on public.merch_order_items (variant_id);

select public.track_table('public.merch_categories');
select public.track_table('public.merch_colours');
select public.track_table('public.merch_drops');
select public.track_table('public.merch_products');
select public.track_table('public.merch_options');
select public.track_table('public.merch_option_values');
select public.track_table('public.merch_variants');
select public.track_table('public.merch_variant_values');
select public.track_table('public.merch_product_media');
select public.track_table('public.merch_orders');
select public.track_table('public.merch_order_items');

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
begin
  foreach t in array array['merch_categories', 'merch_colours', 'merch_drops', 'merch_products',
    'merch_options', 'merch_option_values', 'merch_variants', 'merch_variant_values',
    'merch_product_media', 'merch_orders', 'merch_order_items']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    if t not in ('merch_orders', 'merch_order_items') then
      execute format('grant select on public.%I to anon, authenticated', t);
    else
      execute format('grant select on public.%I to authenticated', t);
    end if;
    execute format('grant insert, update, delete on public.%I to authenticated', t);
    execute format(
      'create policy %I on public.%I for all to authenticated using (public.is_staff()) with check (public.is_staff())',
      'staff manage ' || replace(t, '_', ' '), t);
  end loop;
end
$$;

create policy "categories are public" on public.merch_categories
  for select to anon, authenticated using (true);
create policy "colours are public" on public.merch_colours
  for select to anon, authenticated using (true);
create policy "published drops are public" on public.merch_drops
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());
create policy "published products are public" on public.merch_products
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());

-- Everything hanging off a product is public when the product is.
create or replace function public.merch_product_is_public(p_product_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.merch_products
                  where id = p_product_id and status = 'published' and archived_at is null);
$$;

create policy "options of published products are public" on public.merch_options
  for select to anon, authenticated using (public.merch_product_is_public(product_id) or public.is_staff());
create policy "values of published products are public" on public.merch_option_values
  for select to anon, authenticated
  using (exists (select 1 from public.merch_options o where o.id = option_id and public.merch_product_is_public(o.product_id))
         or public.is_staff());
create policy "variants of published products are public" on public.merch_variants
  for select to anon, authenticated using (public.merch_product_is_public(product_id) or public.is_staff());
create policy "variant values of published products are public" on public.merch_variant_values
  for select to anon, authenticated using (public.merch_product_is_public(product_id) or public.is_staff());
create policy "photos of published products are public" on public.merch_product_media
  for select to anon, authenticated using (public.merch_product_is_public(product_id) or public.is_staff());

-- Orders are created by server code (secret key), which works out prices
-- itself. Staff manage them; a member reads their own.
create policy "the member reads their own orders" on public.merch_orders
  for select to authenticated using (profile_id = public.current_profile_id() or public.is_staff());
create policy "the member reads their own order items" on public.merch_order_items
  for select to authenticated
  using (exists (select 1 from public.merch_orders o where o.id = order_id and o.profile_id = public.current_profile_id())
         or public.is_staff());

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------

-- Each variant with its price and a readable name: "forest / M".
create view public.merch_variant_cards with (security_invoker = on) as
  select v.id, v.product_id, v.sku, v.is_available,
         coalesce(v.price_override_kes, p.price_kes) as price_kes,
         coalesce(v.external_url, p.external_url) as external_url,
         coalesce(string_agg(ov.value, ' / ' order by o.sort_order), '') as label
    from public.merch_variants v
    join public.merch_products p on p.id = v.product_id
    left join public.merch_variant_values vv on vv.variant_id = v.id
    left join public.merch_options o on o.id = vv.option_id
    left join public.merch_option_values ov on ov.id = vv.option_value_id
   group by v.id, p.price_kes, p.external_url;

-- Order totals, worked out from the lines.
create view public.merch_order_totals with (security_invoker = on) as
  select o.id as order_id, o.drop_id, o.status, o.deposit_pct,
         coalesce(sum(i.qty), 0)::int as items,
         coalesce(sum(i.qty * i.unit_price_kes), 0)::int as total_kes,
         round(coalesce(sum(i.qty * i.unit_price_kes), 0) * o.deposit_pct / 100.0)::int as deposit_kes
    from public.merch_orders o
    left join public.merch_order_items i on i.order_id = o.id
   group by o.id;

-- How many of each variant are reserved. Cancelled and refunded orders don't
-- count. This is the printer's size list.
create view public.merch_run_counts with (security_invoker = on) as
  select v.product_id, i.variant_id, sum(i.qty)::int as qty
    from public.merch_order_items i
    join public.merch_orders o on o.id = i.order_id
    join public.merch_variants v on v.id = i.variant_id
   where o.status not in ('cancelled', 'refunded')
   group by v.product_id, i.variant_id;

grant select on public.merch_variant_cards to anon, authenticated;
grant select on public.merch_order_totals, public.merch_run_counts to authenticated;

-- Public: progress towards each product's minimum run, without exposing orders.
create or replace function public.merch_product_progress(p_drop_id uuid)
returns table (product_id uuid, min_run int, reserved int)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.min_run,
         coalesce((select sum(i.qty)
                     from public.merch_order_items i
                     join public.merch_orders o on o.id = i.order_id
                     join public.merch_variants v on v.id = i.variant_id
                    where v.product_id = p.id
                      and o.status not in ('cancelled', 'refunded')), 0)::int
    from public.merch_products p
   where p.drop_id = p_drop_id and p.status = 'published' and p.archived_at is null;
$$;
grant execute on function public.merch_product_progress(uuid) to anon, authenticated;

-- Creates a variant for every combination of a product's option values that
-- doesn't have one yet: Colour x Size gives forest / S, forest / M, ...
-- Runs as the caller, so only staff (or server code) can use it.
-- Returns how many variants it added.
create or replace function public.merch_generate_variants(p_product_id uuid)
returns int
language plpgsql
set search_path = ''
as $$
declare
  combo uuid[];
  new_variant uuid;
  added int := 0;
begin
  for combo in
    with recursive opts as (
      select o.id, row_number() over (order by o.sort_order, o.label) as rn
        from public.merch_options o where o.product_id = p_product_id
    ),
    combos (rn, vals) as (
      select 1::bigint, array[v.id]
        from opts o join public.merch_option_values v on v.option_id = o.id
       where o.rn = 1
      union all
      select c.rn + 1, c.vals || v.id
        from combos c
        join opts o on o.rn = c.rn + 1
        join public.merch_option_values v on v.option_id = o.id
    )
    select vals from combos where rn = (select max(rn) from opts)
  loop
    -- Skip combinations that already exist.
    continue when exists (
      select 1 from public.merch_variants mv
       where mv.product_id = p_product_id
         and (select array_agg(vv.option_value_id order by vv.option_value_id)
                from public.merch_variant_values vv where vv.variant_id = mv.id)
             = (select array_agg(x order by x) from unnest(combo) x)
    );
    insert into public.merch_variants (product_id) values (p_product_id) returning id into new_variant;
    insert into public.merch_variant_values (variant_id, product_id, option_id, option_value_id)
    select new_variant, p_product_id, v.option_id, v.id
      from public.merch_option_values v where v.id = any (combo);
    added := added + 1;
  end loop;
  return added;
end;
$$;
revoke execute on function public.merch_generate_variants(uuid) from public, anon;
grant execute on function public.merch_generate_variants(uuid) to authenticated;
