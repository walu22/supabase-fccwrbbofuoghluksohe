# AGENTS.md

## Project overview

This repository is the **Supabase backend** for **TumaHelper**, an on-demand home-services
marketplace for Lusaka, Zambia. It contains only the database layer — Postgres schema,
migrations, seed data, and local Supabase config. There is **no application/frontend code**
here (no `package.json`, `requirements.txt`, or edge functions); the client app lives in a
separate repository.

Everything is driven by the **Supabase CLI** + **Docker**:

- `supabase/config.toml` — local stack config (Postgres 17, ports 54321–54327).
- `supabase/migrations/*.sql` — schema, RLS policies, and RPCs (`match_helpers`,
  `match_and_reserve_helper`, `create_service_booking`, etc.).
- `supabase/seed.sql` — non-sensitive catalog data (Lusaka areas/estates, services, promo
  codes, demo helpers), loaded on database reset.

## Cursor Cloud specific instructions

The VM snapshot already has Docker, the Supabase CLI, and the `psql` client installed. The
update script does not start any services — you must start them yourself each session.

### Start the stack

1. **Start the Docker daemon** (no systemd in this environment). Run it in a background
   tmux session, e.g.:
   `sudo dockerd > /tmp/dockerd.log 2>&1 &` (then `sudo chmod 666 /var/run/docker.sock` if
   you hit permission errors reaching the daemon).
2. **Start Supabase** from the repo root: `supabase start`.

### IMPORTANT: `seed.sql` breaks `supabase start`/`db reset` seeding

`supabase/seed.sql` uses `COPY ... FROM stdin`. The Supabase CLI's seed executor cannot
stream stdin, so it fails with `syntax error ... (SQLSTATE 42601)` and **rolls the whole
stack back** (this is a known CLI limitation, not a bug in this repo). `psql` handles the
same file fine. So do **not** let the CLI run the seed:

- **Fresh start:** temporarily move the seed aside so `supabase start` succeeds, then load
  it with `psql`:
  ```
  mv supabase/seed.sql /tmp/seed.sql && supabase start && mv /tmp/seed.sql supabase/seed.sql
  psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f supabase/seed.sql
  ```
- **Rebuild schema (the "build" step):** `supabase db reset --no-seed` then re-run the
  `psql ... -f supabase/seed.sql` line above.

Keep `seed.sql` unchanged — it is valid SQL and is applied via `psql`.

### Lint / test / build / run

- **Lint:** `supabase db lint` (one pre-existing IMMUTABLE warning on `try_parse_time` is
  expected).
- **Test:** no automated test suite exists (no pgTAP tests in the repo).
- **Build:** applying migrations via `supabase db reset --no-seed` (see above).
- **Run:** `supabase start`; connection details via `supabase status`. Studio UI is at
  `http://127.0.0.1:54323`, REST/Auth API at `http://127.0.0.1:54321`, Postgres at port
  `54322` (`postgres:postgres`).

### Notes

- `handle_new_user()` exists in migrations but no trigger on `auth.users` is defined there
  (Supabase auth-schema triggers are managed outside the dumped public schema). As a result
  a local email signup creates the `auth.users` row but not a `public.profiles` row. This is
  a migration characteristic, not an environment problem.
