#!/usr/bin/env bash
# Builds the whole database from empty on a throwaway local Postgres, seeds it
# twice (the seed must be safe to re-run), then runs the access-rule tests.
#
#   scripts/test-db.sh
#
# Needs a local Postgres 15+ on PGPORT (default 54329), for example
# Postgres.app. No Docker and no Supabase account needed: supabase/tests/
# local_stub.sql stands in for Supabase's auth and storage schemas.
set -euo pipefail

cd "$(dirname "$0")/.."
PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-54329}"
PGUSER="${PGUSER:-postgres}"
DB="${TEST_DB:-fb_test}"
export PGHOST PGPORT PGUSER

psql_q() { psql -v ON_ERROR_STOP=1 -q -X "$@"; }

psql_q -d postgres -c "drop database if exists $DB" -c "create database $DB"
psql_q -d "$DB" -f supabase/tests/local_stub.sql

for f in supabase/migrations/*.sql; do
  echo "migrate  $(basename "$f")"
  psql_q -d "$DB" -o /dev/null -f "$f"
done

echo "seed     supabase/seed.sql (twice)"
psql_q -d "$DB" -o /dev/null -f supabase/seed.sql
psql_q -d "$DB" -o /dev/null -f supabase/seed.sql

echo "test     supabase/tests/access_test.sql"
psql_q -d "$DB" -o /dev/null -f supabase/tests/access_test.sql
echo "All database checks passed."
