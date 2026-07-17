# Cloud Run ↔ Next.js API wiring audit

**Date:** 2026-07-17  
**Cloud Run:** `https://tumahelper-prod-api-550454647742.europe-west1.run.app`  
**Vercel:** `https://tumahelper.com`

## Architecture (current)

| Traffic | Handled by |
|---------|------------|
| Frontend → `/api/*` | **Local Next.js** route handlers (`app/api/*`, 50+ routes) |
| Frontend → `/api/v1/*` | Was rewritten to Cloud Run `/api/*` (mostly 404) |
| Direct Cloud Run `/health` | **200 OK** |

The live web app does **not** call `/api/v1/*` today. Almost all UI uses `/api/*` on Vercel/Next.js + Supabase.

## Probe results

| Origin | Path | Status | Notes |
|--------|------|--------|-------|
| Cloud Run | `GET /health` | **200** | `{"status":"ok",...}` |
| Cloud Run | `GET /api/health` | 404 | Not mounted |
| Cloud Run | `GET /api/bookings` | 404 | Not mounted |
| Cloud Run | `GET /api/auth/me` | 404 | Not mounted |
| Cloud Run | `GET /api/workers` | 404 | Not mounted |
| Vercel | `GET /api/workers` | 200 | Local Next.js |
| Vercel | `GET /api/notifications` | 401 | Local Next.js (auth required) |
| Vercel | `GET /api/bookings` | 500→should be 401 | Bug: auth error as INTERNAL_ERROR |
| Vercel | `GET /api/v1/health` | 404 | Rewrote to CR `/api/health` (missing) |
| Vercel | `GET /api/v1/workers` | 404 | Rewrote to CR `/api/workers` (missing) |

## Issues

1. **Cloud Run rewrite was broken for real API paths** — service only has `/health`, not `/api/*`.
2. **Health path mismatch** — rewrite sent `/api/v1/health` → `/api/health`, but CR health is `/health`.
3. **Frontend bypasses Cloud Run** — calls `/api/*` (Next.js), so CR proxy was unused in practice.
4. **Bookings GET returned 500** for unauthenticated requests instead of 401.

## Fixes applied in this branch

### `next.config.js`
- Default: `/api/v1/:path*` → local `/api/:path*` (works today).
- Opt-in Cloud Run: set `USE_CLOUD_RUN_API=true` on Vercel.
  - `/api/v1/health` → Cloud Run `/health`
  - `/api/v1/:path*` → Cloud Run `/api/:path*`
- Optional override: `CLOUD_RUN_API_BASE_URL`

### `app/api/bookings/route.ts`
- Unauthenticated GET returns **401** instead of **500**.

## When to turn Cloud Run on

Only set `USE_CLOUD_RUN_API=true` after Cloud Run exposes the same routes the app needs under `/api/*` (auth, bookings, workers, notifications, …), and those routes talk to prod Supabase `bwmojebyakileueoraxs`.

Until then, leave the flag unset — production keeps using Next.js `/api/*`.
