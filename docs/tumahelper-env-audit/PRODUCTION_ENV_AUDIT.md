# Production environment audit — Vercel

**Goal:** `tumahelper.com` (Vercel **Production**) must use **only** prod Supabase  
`bwmojebyakileueoraxs`. Staging `vvqouitgiiosmszqztxs` is for Preview / local only.

## Required values

### Production (tumahelper.com)

| Variable | Must be |
|----------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://bwmojebyakileueoraxs.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Prod `sb_publishable_…` (or legacy anon JWT) |
| `SUPABASE_SERVICE_ROLE_KEY` | Prod `sb_secret_…` (or legacy service_role) — **secret** |
| `NEXT_PUBLIC_APP_URL` | `https://tumahelper.com` |
| `COMING_SOON` | `false` (or unset — gate is off by default in code) |
| `DEV_AUTH_BYPASS` | **unset** or `false` |
| `ALLOW_DEV_LOGIN` | **unset** or `false` |
| `SUPABASE_STORAGE_BUCKET` | `worker-documents` |
| `NRC_ENCRYPTION_KEY` | 32-char secret (prod value) |

### Preview / Development (local laptop, Vercel previews)

| Variable | Must be |
|----------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://vvqouitgiiosmszqztxs.supabase.co` |
| Keys | Staging publishable + secret |

## How to audit in Vercel (do this now)

1. Open team: https://vercel.com/walkers-projects-da1ff726  
2. Open project **tumahelper**  
3. **Settings → Environment Variables**  
4. For each variable below, open it and check the **Environment** checkboxes:

### Checklist

- [ ] `NEXT_PUBLIC_SUPABASE_URL`  
  - **Production** = `https://bwmojebyakileueoraxs.supabase.co`  
  - **Preview** / **Development** = `https://vvqouitgiiosmszqztxs.supabase.co`  
  - If one value is shared across all envs → **split it** (edit → remove from wrong envs → add separate entries)

- [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY`  
  - Production = prod publishable key  
  - Preview/Development = staging key  

- [ ] `SUPABASE_SERVICE_ROLE_KEY`  
  - Production = prod secret only  
  - Preview/Development = staging secret only  
  - Never reuse prod secret on Preview  

- [ ] `COMING_SOON` on Production = `false` (or delete the var)  

- [ ] `DEV_AUTH_BYPASS` / `ALLOW_DEV_LOGIN` **not** set on Production  

- [ ] `NEXT_PUBLIC_APP_URL` on Production = `https://tumahelper.com`  

5. After any change: **Deployments → … on latest Production → Redeploy**  
   (required so `NEXT_PUBLIC_*` values are baked into the build)

## CLI audit (optional)

From `C:\tumahelper` after `vercel login` + `vercel link`:

```powershell
npx vercel env ls
npx vercel env pull .env.vercel.production --environment production
Select-String -Path .env.vercel.production -Pattern "SUPABASE_URL|COMING_SOON|DEV_AUTH|ALLOW_DEV"
```

You want Production URL to contain **`bwmojebyakileueoraxs`**, not `vvqoui`.

Then delete `.env.vercel.production` (it contains secrets) — do not commit it.

## Fail conditions (fix immediately)

| Finding | Risk |
|---------|------|
| Production URL is `vvqouitgiiosmszqztxs` | Live site writing to staging DB |
| Same service role key on Production + Preview | Staging deploys can access prod data |
| `DEV_AUTH_BYPASS=true` on Production | Auth bypass on live site |
| `COMING_SOON=true` on Production | Site gated again |

## Backend note

Vercel rewrites `/api/v1/*` → Cloud Run:

`https://tumahelper-prod-api-550454647742.europe-west1.run.app/api/:path*`

Cloud Run production must also use **`bwmojebyakileueoraxs`** credentials (separate from Vercel env). Check GCP secret/env for that service if bookings/API look wrong.
