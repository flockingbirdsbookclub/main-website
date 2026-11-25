-- Merch: drops (campaigns with a deadline and a minimum run), products,
-- variants, photos, and orders for products we take preorders on.
-- Design: docs/DATA_MODEL.md.

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
  kind         text not null,
  name         text not null,
  description  text,
  price_kes    int not null check (price_kes >= 0),
  fulfilment   text not null default 'preorder' check (fulfilment in ('partner_store', 'preorder')),
  external_url text,
  min_run      int check (min_run > 0),
  -- [{"label":"Colour","swatch":true,"values":["forest","cream"]}, ...]
  options      jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  status       text not null default 'draft' check (status in ('draft', 'published')),
  sort_order   int not null default 0,
  archived_at  timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint partner_store_needs_link check (fulfilment <> 'partner_store' or external_url is not null)
);
create index merch_products_drop_idx on public.merch_products (drop_id, sort_order);

create table public.merch_variants (
  id                 uuid primary key default gen_random_uuid(),
  product_id         uuid not null references public.merch_products (id) on delete cascade,
  options            jsonb not null check (jsonb_typeof(options) = 'object'),
  price_override_kes int check (price_override_kes >= 0),
  external_url       text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (product_id, options)
);

create table public.merch_product_media (
  product_id uuid not null references public.merch_products (id) on delete cascade,
  media_id   uuid not null references public.media (id) on delete cascade,
  sort_order int not null default 0,
  primary key (product_id, media_id)
);

create table public.merch_orders (
  id          uuid primary key default gen_random_uuid(),
  drop_id     uuid references public.merch_drops (id) on delete set null,
  profile_id  uuid references public.profiles (id) on delete set null,
  name        text not null,
  phone       text not null,
  flock_id    uuid references public.flocks (id) on delete set null,
  flock_text  text, -- what they picked, including "Not a member yet"
  total_kes   int not null check (total_kes >= 0),
  deposit_kes int not null check (deposit_kes >= 0 and deposit_kes <= total_kes),
  mpesa_code  text,
  status      text not null default 'pending_deposit'
              check (status in ('pending_deposit', 'deposit_paid', 'paid', 'collected', 'refunded', 'cancelled')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index merch_orders_drop_idx on public.merch_orders (drop_id);

create table public.merch_order_items (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references public.merch_orders (id) on delete cascade,
  product_id     uuid not null references public.merch_products (id) on delete restrict,
  variant        jsonb not null default '{}'::jsonb,
  qty            int not null check (qty > 0),
  unit_price_kes int not null check (unit_price_kes >= 0),
  created_at     timestamptz not null default now()
);
create index merch_order_items_order_idx on public.merch_order_items (order_id);
create index merch_order_items_product_idx on public.merch_order_items (product_id);

select public.track_table('public.merch_drops');
select public.track_table('public.merch_products');
select public.track_table('public.merch_variants');
select public.track_table('public.merch_product_media');
select public.track_table('public.merch_orders');
select public.track_table('public.merch_order_items');

alter table public.merch_drops         enable row level security;
alter table public.merch_products      enable row level security;
alter table public.merch_variants      enable row level security;
alter table public.merch_product_media enable row level security;
alter table public.merch_orders        enable row level security;
alter table public.merch_order_items   enable row level security;

revoke all on public.merch_drops, public.merch_products, public.merch_variants,
  public.merch_product_media, public.merch_orders, public.merch_order_items
  from anon, authenticated;

grant select on public.merch_drops, public.merch_products, public.merch_variants, public.merch_product_media
  to anon, authenticated;
grant insert, update, delete on public.merch_drops, public.merch_products, public.merch_variants,
  public.merch_product_media, public.merch_orders, public.merch_order_items
  to authenticated;
grant select on public.merch_orders, public.merch_order_items to authenticated;

create policy "published drops are public" on public.merch_drops
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());
create policy "published products are public" on public.merch_products
  for select to anon, authenticated using ((status = 'published' and archived_at is null) or public.is_staff());
create policy "variants of published products are public" on public.merch_variants
  for select to anon, authenticated
  using (exists (select 1 from public.merch_products p where p.id = product_id and p.status = 'published' and p.archived_at is null)
         or public.is_staff());
create policy "photos of published products are public" on public.merch_product_media
  for select to anon, authenticated
  using (exists (select 1 from public.merch_products p where p.id = product_id and p.status = 'published' and p.archived_at is null)
         or public.is_staff());

create policy "staff manage drops" on public.merch_drops
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage products" on public.merch_products
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage variants" on public.merch_variants
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff manage product photos" on public.merch_product_media
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- Orders are created by server code (service role), which works out the
-- totals itself. Staff manage them; a member reads their own.
create policy "staff and the member read orders" on public.merch_orders
  for select to authenticated using (public.is_staff() or profile_id = public.current_profile_id());
create policy "staff manage orders" on public.merch_orders
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff and the member read order items" on public.merch_order_items
  for select to authenticated
  using (public.is_staff()
         or exists (select 1 from public.merch_orders o where o.id = order_id and o.profile_id = public.current_profile_id()));
create policy "staff manage order items" on public.merch_order_items
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- How close each item is to its minimum run. Cancelled and refunded orders
-- don't count. Staff only: it is built from orders.
create view public.merch_run_counts with (security_invoker = on) as
  select i.product_id, p.name, p.min_run, i.variant, sum(i.qty)::int as qty
    from public.merch_order_items i
    join public.merch_orders o on o.id = i.order_id
    join public.merch_products p on p.id = i.product_id
   where o.status not in ('cancelled', 'refunded')
   group by i.product_id, p.name, p.min_run, i.variant;

-- Public version: totals per product only, so the store can show progress
-- towards the minimum run without exposing any order.
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
                    where i.product_id = p.id
                      and o.status not in ('cancelled', 'refunded')), 0)::int
    from public.merch_products p
   where p.drop_id = p_drop_id and p.status = 'published' and p.archived_at is null;
$$;
grant execute on function public.merch_product_progress(uuid) to anon, authenticated;

grant select on public.merch_run_counts to authenticated;
