# TumaHelper — production configuration

## Active production Supabase (confirmed)

| Field | Value |
|-------|--------|
| **Project ref** | `bwmojebyakileueoraxs` |
| **API URL** | `https://bwmojebyakileueoraxs.supabase.co` |
| **Dashboard** | https://supabase.com/dashboard/project/bwmojebyakileueoraxs |

Use this project for **tumahelper.com**, Vercel production env vars, and any backend API.

### Vercel / Next.js env

```env
NEXT_PUBLIC_SUPABASE_URL=https://bwmojebyakileueoraxs.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon key from dashboard>
SUPABASE_SERVICE_ROLE_KEY=<service role — server only>
```

Keys: https://supabase.com/dashboard/project/bwmojebyakileueoraxs/settings/api

### Apply migrations from this repo to the active project

```bash
# From repo root
npx supabase login
npx supabase link --project-ref bwmojebyakileueoraxs
npx supabase db push
```

Review the diff carefully before confirming. Migrations in `supabase/migrations/` harden
booking RLS, add `create_service_booking` / matching RPCs, and organise Lusaka locations.

### Seed (local / reset only)

`supabase/seed.sql` uses `COPY ... FROM stdin` — load with `psql`, not the CLI seed runner:

```bash
psql "$DATABASE_URL" -f supabase/seed.sql
```

Do **not** blindly re-seed production (it can overwrite catalog IDs).

## Legacy projects (do not use for live users)

| Ref | Notes |
|-----|--------|
| `fccwrbbofuoghluksohe` | Older "Tuma Helper New" project; original home of these migrations |
| `bzvjqfxsuhisnuweenwu` | Retired Lovable / Namibia-era app |

## GCP

| Environment | Project |
|-------------|---------|
| Production | `tumahelper-auth` |
| Staging | `tumahelper-ai-dev` |

## Live app hosting

| Item | Value |
|------|--------|
| Domain | https://tumahelper.com |
| Host | Vercel (`walkers-projects-da1ff726`) |
| App source | Local `C:\tumahelper` — push to `walu22/tumahelper` when ready |
| Old VPS | `31.97.56.157` — no longer serves the domain |
