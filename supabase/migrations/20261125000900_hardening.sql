-- Hardening after Supabase's security and performance advisors ran on staging.
--
-- 1. Helper functions the access rules use move to a `private` schema, which
--    the API does not expose, so nobody can call them at /rest/v1/rpc/...
--    Policies refer to functions by id, so they keep working after the move.
-- 2. Trigger functions can't be executed by API roles at all.
-- 3. Access rules call auth.uid() once per query instead of once per row.
-- 4. Staff "for all" rules become insert, update and delete rules, so they no
--    longer overlap with the public read rules (which already let staff read).

-- ---------------------------------------------------------------------------
-- 1 and 2: functions
-- ---------------------------------------------------------------------------

create schema if not exists private;
grant usage on schema private to anon, authenticated;

alter function public.is_staff() set schema private;
alter function public.is_admin() set schema private;
alter function public.is_member() set schema private;
alter function public.current_profile_id() set schema private;
alter function public.is_valid_slug(text) set schema private;
alter function public.award_automatic(text, uuid, text) set schema private;
alter function public.track_table(regclass, boolean) set schema private;
alter function public.merch_product_is_public(uuid) set schema private;

-- Function bodies are stored as text, so any function that calls a moved
-- helper by its old public. name is rewritten to call private. instead.
do $$
declare
  f record;
  def text;
begin
  for f in
    select p.oid
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname in ('public', 'private')
       and p.prosrc ~ 'public\.(is_staff|is_admin|is_member|current_profile_id|is_valid_slug|award_automatic|track_table|merch_product_is_public)\('
  loop
    def := pg_get_functiondef(f.oid);
    def := regexp_replace(def, 'public\.(is_staff|is_admin|is_member|current_profile_id|is_valid_slug|award_automatic|track_table|merch_product_is_public)\(', 'private.\1(', 'g');
    execute def;
  end loop;
end
$$;

-- Functions created later in public are not executable by default.
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon, authenticated;

-- Trigger functions: never callable through the API.
revoke execute on function
  public.set_updated_at(),
  public.audit_row(),
  public.handle_new_user(),
  public.guard_profile_update(),
  public.guard_article_write(),
  public.profile_links_default_visibility(),
  public.score_entries_append_only(),
  public.points_for_published_article(),
  public.points_for_attendance()
  from public, anon, authenticated;

-- Functions the API is meant to offer. Each checks permissions itself.
revoke execute on function public.approve_profile_changes(uuid) from public, anon;
revoke execute on function public.profile_private(uuid)        from public, anon;
revoke execute on function public.staff_game_options(uuid)     from public, anon;
grant  execute on function public.approve_profile_changes(uuid) to authenticated;
grant  execute on function public.profile_private(uuid)        to authenticated;
grant  execute on function public.staff_game_options(uuid)     to authenticated;
grant  execute on function public.merch_product_progress(uuid) to anon, authenticated;

-- The access rules call these as the visitor, so the API roles need EXECUTE.
-- They stay unreachable over HTTP because `private` is not an exposed schema.
revoke execute on all functions in schema private from public;
grant execute on function private.is_staff(), private.is_admin(), private.is_member(),
  private.current_profile_id(), private.is_valid_slug(text), private.merch_product_is_public(uuid)
  to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3 and 4: access rules
-- ---------------------------------------------------------------------------

do $$
declare
  p record;
  using_expr text;
  check_expr text;
  op text;
begin
  -- 4: split every staff or admin "for all" rule.
  for p in
    select schemaname, tablename, policyname, roles, qual, with_check
      from pg_policies
     where schemaname in ('public')
       and pg_policies.cmd = 'ALL'
       and (policyname like 'staff manage %' or policyname like 'admins manage %')
  loop
    execute format('drop policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
    foreach op in array array['insert', 'update', 'delete'] loop
      execute format(
        'create policy %I on %I.%I for %s to authenticated %s %s',
        p.policyname || ' (' || op || ')', p.schemaname, p.tablename, op,
        case when op in ('update', 'delete') then 'using (' || p.qual || ')' else '' end,
        case when op in ('insert', 'update') then 'with check (' || coalesce(p.with_check, p.qual) || ')' else '' end);
    end loop;
  end loop;

  -- 3: wrap auth.uid() and the helpers so Postgres evaluates them once.
  for p in
    select schemaname, tablename, policyname, qual, with_check
      from pg_policies
     where schemaname in ('public', 'storage')
       and (coalesce(qual, '') ~ 'auth\.uid\(\)|is_staff\(\)|is_admin\(\)|is_member\(\)|current_profile_id\(\)'
            or coalesce(with_check, '') ~ 'auth\.uid\(\)|is_staff\(\)|is_admin\(\)|is_member\(\)|current_profile_id\(\)')
  loop
    using_expr := p.qual;
    check_expr := p.with_check;
    using_expr := regexp_replace(using_expr, '(auth\.uid\(\)|(private\.)?(is_staff|is_admin|is_member|current_profile_id)\(\))', '(select \1)', 'g');
    check_expr := regexp_replace(check_expr, '(auth\.uid\(\)|(private\.)?(is_staff|is_admin|is_member|current_profile_id)\(\))', '(select \1)', 'g');
    execute format('alter policy %I on %I.%I %s %s',
      p.policyname, p.schemaname, p.tablename,
      case when using_expr is not null then 'using (' || using_expr || ')' else '' end,
      case when check_expr is not null then 'with check (' || check_expr || ')' else '' end);
  end loop;
end
$$;
