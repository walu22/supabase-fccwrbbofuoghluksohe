## Patch for tumahelper/README.md

Replace the "## Deployment (Vercel) → #### 2. Add environment variables" table with:

**Do not use one Supabase project for all environments.**  
Full checklist: docs/PRODUCTION_ENV_AUDIT.md

| Variable | Production | Preview / Development |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://bwmojebyakileueoraxs.supabase.co` | `https://vvqouitgiiosmszqztxs.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Prod publishable / anon key | Staging key |
| `SUPABASE_SERVICE_ROLE_KEY` | Prod secret only | Staging secret only |
| `NEXT_PUBLIC_APP_URL` | `https://tumahelper.com` | Preview URL or `http://localhost:3000` |
| `COMING_SOON` | `false` | optional |
| `DEV_AUTH_BYPASS` / `ALLOW_DEV_LOGIN` | **unset / false** | optional for local |
| `NRC_ENCRYPTION_KEY` | 32-character secret | can differ |
| `SUPABASE_STORAGE_BUCKET` | `worker-documents` | `worker-documents` |

Also add to Documentation table:
| docs/PRODUCTION_ENV_AUDIT.md | Vercel prod vs staging Supabase env checklist |
