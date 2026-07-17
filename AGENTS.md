# AGENTS.md

## Project overview

This repository is the **Supabase backend** for **TumaHelper**, an on-demand home-services
marketplace for Lusaka, Zambia. It contains only the database layer — Postgres schema,
migrations, seed data, and local Supabase config. There is **no application/frontend code**
here; the live client is a Next.js app on Vercel (`tumahelper.com`).

**Databases (confirmed):**

| Env | Ref | URL |
|-----|-----|-----|
| **Production** | `bwmojebyakileueoraxs` | https://bwmojebyakileueoraxs.supabase.co |
| **Staging** | `vvqouitgiiosmszqztxs` | https://vvqouitgiiosmszqztxs.supabase.co |

See `PRODUCTION.md` for Vercel/GCP env mapping.

Everything is driven by the **Supabase CLI** + **Docker**:

- `supabase/config.toml` — local stack config
- `supabase/migrations/*.sql` — schema, RLS, RPCs
- `supabase/seed.sql` — Lusaka catalog data (load via `psql`, not CLI seed)

## Critical production facts

1. Live site: **Vercel**, not the old Hostinger VPS.
2. Production Supabase: **`bwmojebyakileueoraxs`**. Staging: **`vvqouitgiiosmszqztxs`**.
3. App source: `walu22/tumahelper` (private; from `C:\tumahelper`). Local `.env.local` uses staging by default.
4. Backend: Google Cloud Run (proxied from Vercel). GCP prod: `tumahelper-auth`; staging: `tumahelper-ai-dev`.

## Cursor Cloud specific instructions

### Start the stack

1. Start Docker if needed (`sudo dockerd` in background).
2. From repo root: `supabase start` (see seed note below).

### IMPORTANT: `seed.sql` breaks CLI seeding

`supabase/seed.sql` uses `COPY ... FROM stdin`. The Supabase CLI seed executor cannot stream
stdin. Load with `psql` after `supabase db reset --no-seed` or after moving the seed aside
during `supabase start`.

### Lint / build / run

- **Lint:** `supabase db lint`
- **Build:** `supabase db reset --no-seed` then `psql` seed
- **Remote push:** `supabase link --project-ref bwmojebyakileueoraxs && supabase db push`
