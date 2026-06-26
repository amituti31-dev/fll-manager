# ════════════════════════════════════════
#  FLL Manager – Release Script
#  שימוש: .\release.ps1 1.0.4
#         .\release.ps1        (מעלה patch אוטומטי)
# ════════════════════════════════════════

param([string]$NewVersion = "")

$ErrorActionPreference = "Stop"
$Root    = $PSScriptRoot
$WebDir  = Join-Path $Root "web"
$tokenFile = Join-Path $Root ".github-token"
if (-not (Test-Path $tokenFile)) { throw "Missing .github-token file in project root" }
$Token = (Get-Content $tokenFile -Raw).Trim()
$Repo    = "amituti31-dev/fll-manager"
$Headers = @{ Authorization = "token $Token"; Accept = "application/vnd.github+json" }

# ── קרא גרסה נוכחית ──────────────────────────────────
$verJson = Get-Content "$WebDir\version.json" | ConvertFrom-Json
$Current = $verJson.version

if (-not $NewVersion) {
    $parts = $Current.Split('.')
    $parts[2] = [string]([int]$parts[2] + 1)
    $NewVersion = $parts -join '.'
}

Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  FLL Manager Release: $Current → $NewVersion" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ── עדכן קבצים ───────────────────────────────────────
Write-Host "► מעדכן קבצים..." -ForegroundColor Yellow

# version.json
$raw = Get-Content "$WebDir\version.json" -Raw
$raw = $raw -replace '"version": "[^"]*"', "`"version`": `"$NewVersion`""
Set-Content "$WebDir\version.json" $raw -Encoding utf8 -NoNewline

# index.html
$html = Get-Content "$WebDir\index.html" -Raw
$html = $html -replace 'גרסה [\d\.]+ –', "גרסה $NewVersion –"
Set-Content "$WebDir\index.html" $html -Encoding utf8 -NoNewline

# pwa.js
$pwa = Get-Content "$WebDir\js\pwa.js" -Raw
$pwa = $pwa -replace 'עדכון v[\d\.]+ זמין', "עדכון v$NewVersion זמין"
Set-Content "$WebDir\js\pwa.js" $pwa -Encoding utf8 -NoNewline

# package.json
$pkg = Get-Content "$Root\package.json" -Raw
$pkg = $pkg -replace '"version": "[^"]*"', "`"version`": `"$NewVersion`""
Set-Content "$Root\package.json" $pkg -Encoding utf8 -NoNewline

Write-Host "  ✓ גרסה עודכנה בכל הקבצים" -ForegroundColor Green

# ── Git push ──────────────────────────────────────────
Write-Host "► מעלה ל-GitHub..." -ForegroundColor Yellow
git -C $WebDir add index.html version.json js/pwa.js
git -C $Root  add package.json main.js
git -C $Root  commit -m "Release v$NewVersion"
git -C $Root  push
Write-Host "  ✓ GitHub מעודכן" -ForegroundColor Green

# ── Firebase deploy ───────────────────────────────────
Write-Host "► Firebase deploy..." -ForegroundColor Yellow
Set-Location $WebDir
firebase deploy --only hosting | Out-Null
Write-Host "  ✓ Firebase חי" -ForegroundColor Green

# ── Build Electron ────────────────────────────────────
Write-Host "► בונה installer..." -ForegroundColor Yellow
Set-Location $Root
npm run build | Out-Null
$ExePath = "$Root\dist\FLL Manager Setup $NewVersion.exe"
if (-not (Test-Path $ExePath)) { throw "הבנייה נכשלה — קובץ לא נמצא" }
Write-Host "  ✓ Installer נבנה ($([int]((Get-Item $ExePath).Length/1MB)) MB)" -ForegroundColor Green

# ── GitHub Release ────────────────────────────────────
Write-Host "► יוצר GitHub Release..." -ForegroundColor Yellow
$body = @{
    tag_name   = "v$NewVersion"
    name       = "FLL Manager v$NewVersion"
    body       = "גרסה $NewVersion"
    draft      = $false
    prerelease = $false
} | ConvertTo-Json
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Method POST -Headers $Headers -Body $body -ContentType "application/json"

Write-Host "► מעלה installer ל-GitHub..." -ForegroundColor Yellow
$uploadUrl  = "https://uploads.github.com/repos/$Repo/releases/$($release.id)/assets?name=FLL.Manager.Setup.exe"
$fileBytes  = [System.IO.File]::ReadAllBytes($ExePath)
Invoke-RestMethod -Uri $uploadUrl -Method POST -Headers $Headers -Body $fileBytes -ContentType "application/octet-stream" | Out-Null
Write-Host "  ✓ Release v$NewVersion הועלה" -ForegroundColor Green

# ── סיום ─────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host "  Release v$NewVersion הושלם בהצלחה!" -ForegroundColor Green
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host ""
