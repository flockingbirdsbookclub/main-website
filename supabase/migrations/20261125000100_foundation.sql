-- Foundation: helpers, staff roles, media, settings, audit log.
-- Design: docs/DATA_MODEL.md. Every later migration builds on these.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Keeps updated_at honest on every table that has one.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Slugs: lowercase letters, digits and single hyphens.
create or replace function public.is_valid_slug(s text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select s ~ '^[a-z0-9]+(-[a-z0-9]+)*$';
$$;

-- ---------------------------------------------------------------------------
-- Staff
-- ---------------------------------------------------------------------------

create table public.staff_roles (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  role       text not null check (role in ('admin', 'editor')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Emails that become staff the first time they sign in. Never readable by
-- anyone through the API: only the sign-in trigger and the service role use it.
-- Staff emails are added in the Supabase dashboard, never in this repository.
create table public.staff_invites (
  email      text primary key check (email = lower(email)),
  role       text not null check (role in ('admin', 'editor')),
  created_at timestamptz not null default now()
);

-- security definer so the access rules can call these without recursing
-- into staff_roles' own rules.
create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.staff_roles where user_id = auth.uid());
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.staff_roles where user_id = auth.uid() and role = 'admin');
$$;

-- ---------------------------------------------------------------------------
-- Media: every image, once
-- ---------------------------------------------------------------------------

create table public.media (
  id          uuid primary key default gen_random_uuid(),
  -- 'site' means a file in the website's own public/ folder (path starts
  -- with /images/). Everything else is a Supabase Storage bucket.
  bucket      text not null check (bucket in ('site', 'avatars', 'covers', 'partners', 'events', 'albums', 'articles', 'merch')),
  path        text not null,
  alt         text not null check (length(trim(alt)) > 0),
  width       int check (width > 0),
  height      int check (height > 0),
  uploaded_by uuid references auth.users (id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (bucket, path)
);

-- ---------------------------------------------------------------------------
-- Settings: values used in many places
-- ---------------------------------------------------------------------------

create table public.settings (
  key        text primary key check (key ~ '^[a-z0-9_]+$'),
  value      jsonb not null,
  is_public  boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Audit log: who changed what
-- ---------------------------------------------------------------------------

create table public.audit_log (
  id         bigint generated always as identity primary key,
  actor_id   uuid,
  table_name text not null,
  row_id     text,
  action     text not null check (action in ('insert', 'update', 'delete')),
  diff       jsonb,
  at         timestamptz not null default now()
);
create index audit_log_table_row_idx on public.audit_log (table_name, row_id);
create index audit_log_at_idx on public.audit_log (at desc);

-- Records changed columns only. security definer so it can write to
-- audit_log, which nobody can write to directly.
create or replace function public.audit_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  old_j jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  new_j jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  changed jsonb;
  rid text;
begin
  rid := coalesce(new_j, old_j) ->> 'id';
  if rid is null then
    rid := coalesce(new_j, old_j) ->> 'key';
  end if;
  if rid is null then
    rid := coalesce(new_j, old_j) ->> 'user_id';
  end if;

  if tg_op = 'UPDATE' then
    select jsonb_object_agg(n.key, jsonb_build_object('old', old_j -> n.key, 'new', n.value))
      into changed
      from jsonb_each(new_j) n
     where n.key not in ('updated_at')
       and (old_j -> n.key) is distinct from n.value;
    if changed is null then
      return new;
    end if;
  elsif tg_op = 'INSERT' then
    changed := new_j;
  else
    changed := old_j;
  end if;

  insert into public.audit_log (actor_id, table_name, row_id, action, diff)
  values (auth.uid(), tg_table_name, rid, lower(tg_op), changed);

  return coalesce(new, old);
end;
$$;

-- Attaches updated_at and audit triggers. Called at the end of each migration
-- for the tables it creates.
create or replace function public.track_table(t regclass, audit boolean default true)
returns void
language plpgsql
set search_path = ''
as $$
declare
  tname text := (select relname from pg_class where oid = t);
begin
  if exists (
    select 1 from pg_attribute
     where attrelid = t and attname = 'updated_at' and not attisdropped
  ) then
    execute format(
      'create trigger %I before update on %s for each row execute function public.set_updated_at()',
      tname || '_set_updated_at', t);
  end if;
  if audit then
    execute format(
      'create trigger %I after insert or update or delete on %s for each row execute function public.audit_row()',
      tname || '_audit', t);
  end if;
end;
$$;

select public.track_table('public.staff_roles');
select public.track_table('public.staff_invites');
select public.track_table('public.media');
select public.track_table('public.settings');

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------

alter table public.staff_roles   enable row level security;
alter table public.staff_invites enable row level security;
alter table public.media         enable row level security;
alter table public.settings      enable row level security;
alter table public.audit_log     enable row level security;

-- Grants are explicit on every table, so nothing depends on Supabase's
-- default privileges. Access rules then narrow each grant down.
revoke all on public.staff_roles, public.staff_invites, public.media, public.settings, public.audit_log
  from anon, authenticated;

grant select on public.staff_roles to authenticated;
grant insert, update, delete on public.staff_roles to authenticated;
create policy "staff see their own role, admins see all" on public.staff_roles
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "admins manage staff" on public.staff_roles
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- staff_invites: no grants to anon or authenticated at all.

grant select on public.media to anon, authenticated;
grant insert, update, delete on public.media to authenticated;
create policy "media is public" on public.media
  for select to anon, authenticated using (true);
create policy "staff manage media" on public.media
  for all to authenticated using (public.is_staff()) with check (public.is_staff());
-- Members add media for their own avatar and articles (see the members migration).

grant select on public.settings to anon, authenticated;
grant insert, update, delete on public.settings to authenticated;
create policy "public settings are public" on public.settings
  for select to anon, authenticated using (is_public or public.is_staff());
create policy "admins manage settings" on public.settings
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

grant select on public.audit_log to authenticated;
create policy "admins read the audit log" on public.audit_log
  for select to authenticated using (public.is_admin());
