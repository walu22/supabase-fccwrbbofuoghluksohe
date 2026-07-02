# Remove TumaHelper "Coming soon" gate and prepare for Vercel redeploy.
# Run from your Next.js project root (e.g. C:\tumahelper):
#   powershell -ExecutionPolicy Bypass -File .\remove-coming-soon.ps1
#
# What this does:
# 1. Finds middleware / page redirects that force /coming-soon
# 2. Disables COMING_SOON env flags in .env* files
# 3. Prints next steps for git push + Vercel redeploy

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (Test-Path (Join-Path $root "package.json")) {
    # script copied into project root
} elseif (Test-Path (Join-Path (Get-Location) "package.json")) {
    $root = Get-Location
} else {
    Write-Error "Run this from your Next.js project root (folder with package.json), e.g. C:\tumahelper"
}

Write-Host "TumaHelper — remove coming-soon gate" -ForegroundColor Cyan
Write-Host "Project root: $root`n"

$changed = @()

function Touch-File($path) {
    if ($path -and (Test-Path $path)) { $script:changed += $path }
}

# --- 1. middleware.ts ---
$middleware = Join-Path $root "middleware.ts"
if (Test-Path $middleware) {
    $text = Get-Content $middleware -Raw
    $original = $text

    # Comment out rewrite/redirect blocks that send traffic to /coming-soon
    $text = $text -replace '(?m)^(\s*)(return\s+NextResponse\.(rewrite|redirect)\([^)]*coming-soon[^)]*\).*)$', '$1// LAUNCH: disabled coming-soon gate — $2'

    # Force COMING_SOON checks to false
    $text = $text -replace 'process\.env\.(NEXT_PUBLIC_)?COMING_SOON\s*===?\s*[''"]true[''"]', 'false /* was COMING_SOON */'
    $text = $text -replace 'process\.env\.(NEXT_PUBLIC_)?LAUNCH_MODE\s*===?\s*[''"]coming-soon[''"]', 'false /* was LAUNCH_MODE */'

    if ($text -ne $original) {
        Set-Content -Path $middleware -Value $text -NoNewline
        Touch-File $middleware
        Write-Host "[fixed] middleware.ts"
    } else {
        Write-Host "[ok]    middleware.ts (no automatic patch — review manually)"
    }
} else {
    Write-Host "[skip]  middleware.ts not found"
}

# --- 2. app/page.tsx root redirect ---
$page = Join-Path $root "app\page.tsx"
if (Test-Path $page) {
    $text = Get-Content $page -Raw
    $original = $text
    $text = $text -replace '(?m)^(\s*)(redirect\([''"]\/coming-soon[''"]\).*)$', '$1// LAUNCH: $2'
    $text = $text -replace '(?m)^(\s*)(permanentRedirect\([''"]\/coming-soon[''"]\).*)$', '$1// LAUNCH: $2'
    if ($text -ne $original) {
        Set-Content -Path $page -Value $text -NoNewline
        Touch-File $page
        Write-Host "[fixed] app/page.tsx (removed redirect to /coming-soon)"
    } else {
        Write-Host "[ok]    app/page.tsx"
    }
}

# --- 3. next.config.* redirects ---
Get-ChildItem -Path $root -Filter "next.config.*" | ForEach-Object {
    $text = Get-Content $_.FullName -Raw
    $original = $text
    $text = $text -replace "destination:\s*['\`"]/coming-soon['\`"]", "destination: '/' /* was /coming-soon */"
    if ($text -ne $original) {
        Set-Content -Path $_.FullName -Value $text -NoNewline
        Touch-File $_.FullName
        Write-Host "[fixed] $($_.Name)"
    }
}

# --- 4. .env files ---
Get-ChildItem -Path $root -Filter ".env*" -File | ForEach-Object {
    $lines = Get-Content $_.FullName
    $out = @()
    $fileChanged = $false
    foreach ($line in $lines) {
        if ($line -match '^(NEXT_PUBLIC_)?(COMING_SOON|LAUNCH_MODE)\s*=') {
            $out += ($line -replace '=.*$', '=false')
            $fileChanged = $true
        } else {
            $out += $line
        }
    }
    if ($fileChanged) {
        Set-Content -Path $_.FullName -Value $out
        Touch-File $_.FullName
        Write-Host "[fixed] $($_.Name)"
    }
}

# Ensure .env.local has explicit false if missing
$envLocal = Join-Path $root ".env.local"
if (-not (Test-Path $envLocal)) {
    @(
        "COMING_SOON=false",
        "NEXT_PUBLIC_COMING_SOON=false"
    ) | Set-Content $envLocal
    Touch-File $envLocal
    Write-Host "[added] .env.local with COMING_SOON=false"
}

Write-Host ""
if ($changed.Count -eq 0) {
    Write-Host "No files were auto-patched." -ForegroundColor Yellow
    Write-Host "Open these manually and remove the coming-soon gate:"
    Write-Host "  - middleware.ts"
    Write-Host "  - app/page.tsx"
    Write-Host "  - app/layout.tsx (search for 'coming-soon')"
    Write-Host "  - Vercel dashboard -> Settings -> Environment Variables"
    Write-Host "      set COMING_SOON=false and NEXT_PUBLIC_COMING_SOON=false"
} else {
    Write-Host "Patched $($changed.Count) file(s):" -ForegroundColor Green
    $changed | ForEach-Object { Write-Host "  - $_" }
}

Write-Host "`n--- Next steps ---"
Write-Host "1. Test locally:  npm run dev   then open http://localhost:3000"
Write-Host "2. Commit:        git add -A && git commit -m `"Remove coming soon gate`""
Write-Host "3. Push:          git push"
Write-Host "4. Vercel:        Project -> Settings -> Environment Variables"
Write-Host "                  COMING_SOON=false, NEXT_PUBLIC_COMING_SOON=false (all environments)"
Write-Host "5. Redeploy:      Vercel -> Deployments -> Redeploy (or auto on push)"
Write-Host "6. Verify:        curl https://tumahelper.com/  (should NOT say 'Coming soon')"
