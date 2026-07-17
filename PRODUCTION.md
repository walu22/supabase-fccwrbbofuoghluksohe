# TumaHelper — production configuration

## Supabase environments (confirmed)

| Environment | Project ref | URL |
|-------------|-------------|-----|
| **Production** | `bwmojebyakileueoraxs` | https://bwmojebyakileueoraxs.supabase.co |
| **Staging** | `vvqouitgiiosmszqztxs` | https://vvqouitgiiosmszqztxs.supabase.co |

| Dashboard (prod) | https://supabase.com/dashboard/project/bwmojebyakileueoraxs |
| Dashboard (staging) | https://supabase.com/dashboard/project/vvqouitgiiosmszqztxs |

### What belongs where

| Surface | Supabase |
|---------|----------|
| **tumahelper.com** (Vercel Production) | **prod** `bwmojebyakileueoraxs` |
| Vercel Preview / local laptop default | **staging** `vvqouitgiiosmszqztxs` |
| Google Cloud Run production backend | **prod** `bwmojebyakileueoraxs` |

Local `C:\tumahelper\.env.local` currently points at **staging** (`vvqouitgiiosmszqztxs`) with prod commented out — that is correct for local/dev work.

### Vercel Production env

Prod uses Supabase **publishable** + **secret** keys:

```env
NEXT_PUBLIC_SUPABASE_URL=https://bwmojebyakileueoraxs.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<sb_publishable_... from prod dashboard>
SUPABASE_SERVICE_ROLE_KEY=<sb_secret_... from prod dashboard — server only>
```

Never commit secret keys. Rotate any secret pasted into chat.

### Vercel Preview / local staging env

```env
NEXT_PUBLIC_SUPABASE_URL=https://vvqouitgiiosmszqztxs.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<staging publishable or anon key>
SUPABASE_SERVICE_ROLE_KEY=<staging secret — server only>
```

Keys:
- Prod: https://supabase.com/dashboard/project/bwmojebyakileueoraxs/settings/api
- Staging: https://supabase.com/dashboard/project/vvqouitgiiosmszqztxs/settings/api

### Schema note (critical)

Production `bwmojebyakileueoraxs` uses the **current platform schema**, including:

- `users`, `worker_profiles`, `worker_references`
- `bookings`, `job_posts`, `job_applications`
- `payments`, `reviews`, `disputes`, `notifications`
- `service_categories`, `verification_documents`, `audit_logs`

It does **not** have older tables/RPCs from early migrations in this repo
(`service_bookings`, `lusaka_areas`, `create_service_booking`, etc.).

**Do not** run `supabase db push` of those older migrations against production
unless there is an explicit, reviewed migration plan.

### Seed (local / reset only)

`supabase/seed.sql` uses `COPY ... FROM stdin` — load with `psql`, not the CLI seed runner.
Do **not** blindly re-seed production.

## Legacy projects (do not use)

| Ref | Notes |
|-----|--------|
| `fccwrbbofuoghluksohe` | Older project; original home of early migrations in this repo |
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
| App source | `C:\tumahelper` → GitHub `walu22/tumahelper` (private) |
| Backend | Google Cloud Run (Vercel rewrite proxy) |
| Old VPS | `31.97.56.157` — no longer serves the domain |
