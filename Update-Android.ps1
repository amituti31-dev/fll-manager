# ════════════════════════════════════════
#  FLL Manager – Android Release Script
#  שימוש: .\Update-Android.ps1 1.0.2
#         .\Update-Android.ps1        (מעלה patch אוטומטי)
# ════════════════════════════════════════

param([string]$NewVersion = "")

$ErrorActionPreference = "Stop"
$Root       = $PSScriptRoot
$WebDir     = Join-Path $Root "web"
$AndroidDir = Join-Path $Root "Android"
$Repo       = "amituti31-dev/fll-manager"
$tokenFile = Join-Path $Root ".github-token"
if (-not (Test-Path $tokenFile)) { throw "Missing .github-token file in project root" }
$Token = (Get-Content $tokenFile -Raw).Trim()
$Headers    = @{ Authorization = "token $Token"; Accept = "application/vnd.github+json" }

# ── קרא גרסה נוכחית ──────────────────────────────────
$verJson    = Get-Content "$WebDir\version.json" | ConvertFrom-Json
$Current    = $verJson.androidVersion

if (-not $NewVersion) {
    $parts = $Current.Split('.')
    $parts[2] = [string]([int]$parts[2] + 1)
    $NewVersion = $parts -join '.'
}

$ApkUrl = "https://github.com/$Repo/releases/download/android-v$NewVersion/app-release.apk"

Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  FLL Manager Android: $Current → $NewVersion" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ── עדכן קבצים ───────────────────────────────────────
Write-Host "► מעדכן קבצים..." -ForegroundColor Yellow

# version.json — androidVersion + downloadUrl
$raw = Get-Content "$WebDir\version.json" -Raw
$raw = $raw -replace '"androidVersion": "[^"]*"', "`"androidVersion`": `"$NewVersion`""
$raw = $raw -replace '"downloadUrl": "[^"]*"',    "`"downloadUrl`": `"$ApkUrl`""
Set-Content "$WebDir\version.json" $raw -Encoding utf8 -NoNewline

# main.dart — _currentVersion
$dart = Get-Content "$AndroidDir\lib\main.dart" -Raw
$dart = $dart -replace "static const _currentVersion = '[^']*'", "static const _currentVersion = '$NewVersion'"
Set-Content "$AndroidDir\lib\main.dart" $dart -Encoding utf8 -NoNewline

Write-Host "  ✓ גרסה עודכנה בכל הקבצים" -ForegroundColor Green

# ── Build APK ─────────────────────────────────────────
Write-Host "► בונה APK (זה לוקח כמה דקות)..." -ForegroundColor Yellow
Set-Location $AndroidDir
flutter build apk --release
$ApkPath = "$AndroidDir\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $ApkPath)) { throw "הבנייה נכשלה — APK לא נמצא" }
Write-Host "  ✓ APK נבנה ($([int]((Get-Item $ApkPath).Length/1MB)) MB)" -ForegroundColor Green

# ── Git push ──────────────────────────────────────────
Write-Host "► מעלה ל-GitHub..." -ForegroundColor Yellow
git -C $WebDir    add version.json
git -C $AndroidDir add lib/main.dart
git -C $Root      commit -m "Android release v$NewVersion"
git -C $Root      push
Write-Host "  ✓ GitHub מעודכן" -ForegroundColor Green

# ── Firebase deploy ───────────────────────────────────
Write-Host "► Firebase deploy..." -ForegroundColor Yellow
Set-Location $WebDir
firebase deploy --only hosting | Out-Null
Write-Host "  ✓ Firebase חי (version.json מעודכן)" -ForegroundColor Green

# ── GitHub Release ────────────────────────────────────
Write-Host "► יוצר GitHub Release..." -ForegroundColor Yellow
$body = @{
    tag_name   = "android-v$NewVersion"
    name       = "FLL Manager Android v$NewVersion"
    body       = "Android $NewVersion"
    draft      = $false
    prerelease = $false
} | ConvertTo-Json
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Method POST -Headers $Headers -Body $body -ContentType "application/json"

Write-Host "► מעלה APK ל-GitHub..." -ForegroundColor Yellow
$uploadUrl = "https://uploads.github.com/repos/$Repo/releases/$($release.id)/assets?name=app-release.apk"
$fileBytes = [System.IO.File]::ReadAllBytes($ApkPath)
Invoke-RestMethod -Uri $uploadUrl -Method POST -Headers $Headers -Body $fileBytes -ContentType "application/octet-stream" | Out-Null
Write-Host "  ✓ APK הועלה" -ForegroundColor Green

# ── סיום ─────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host "  Android Release v$NewVersion הושלם!" -ForegroundColor Green
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host ""
