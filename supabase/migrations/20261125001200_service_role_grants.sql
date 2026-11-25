-- Server code uses the secret key, which acts as the `service_role` role. It
-- skips the access rules, but still needs table privileges, and new Supabase
-- projects no longer grant those on new tables automatically. Without this,
-- server code gets "permission denied" (found by scripts/test-auth.mjs).
--
-- Only server code ever holds the secret key (lib/supabase/admin.ts).

grant usage on schema public, private to service_role;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant execute on all functions in schema public to service_role;
grant execute on all functions in schema private to service_role;

-- Tables, sequences and functions added by later migrations.
alter default privileges in schema public grant all on tables to service_role;
alter default privileges in schema public grant all on sequences to service_role;
alter default privileges in schema public grant execute on functions to service_role;
alter default privileges in schema private grant execute on functions to service_role;
