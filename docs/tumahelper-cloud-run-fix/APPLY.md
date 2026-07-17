# Apply Cloud Run API wiring fix on your laptop

```powershell
cd C:\tumahelper
git checkout master
git pull origin master
git checkout -b cursor/cloud-run-api-wiring-16c4

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/walu22/supabase-fccwrbbofuoghluksohe/cursor/retarget-active-supabase-16c4/docs/tumahelper-cloud-run-fix/CLOUD_RUN_API_AUDIT.md" -OutFile "docs\CLOUD_RUN_API_AUDIT.md"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/walu22/supabase-fccwrbbofuoghluksohe/cursor/retarget-active-supabase-16c4/docs/tumahelper-cloud-run-fix/next.config.js" -OutFile "next.config.js"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/walu22/supabase-fccwrbbofuoghluksohe/cursor/retarget-active-supabase-16c4/docs/tumahelper-cloud-run-fix/env.local.example" -OutFile ".env.local.example"

# Patch bookings route: in app\api\bookings\route.ts, inside the GET catch block, replace:
#   } catch (error) {
#     return errorResponse("INTERNAL_ERROR", "Failed to fetch bookings", 500);
#   }
# with:
#   } catch (error) {
#     if (error instanceof Error && error.message === "Unauthorized") {
#       return errorResponse("UNAUTHORIZED", "Not authenticated", 401);
#     }
#     return errorResponse("INTERNAL_ERROR", "Failed to fetch bookings", 500);
#   }

git add next.config.js docs/CLOUD_RUN_API_AUDIT.md .env.local.example app/api/bookings/route.ts
git commit -m "Fix Cloud Run API proxy wiring and bookings auth status"
git push -u origin cursor/cloud-run-api-wiring-16c4
```

Then open: https://github.com/walu22/tumahelper/pull/new/cursor/cloud-run-api-wiring-16c4
