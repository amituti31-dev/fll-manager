param([string]$NewVersion = "")

$ErrorActionPreference = "Stop"
$Root       = $PSScriptRoot
$WebDir     = Join-Path $Root "web"
$AndroidDir = Join-Path $Root "Android"
$Repo       = "amituti31-dev/fll-manager"
$UTF8       = New-Object System.Text.UTF8Encoding $false

$tokenFile = Join-Path $Root ".github-token"
if (-not (Test-Path $tokenFile)) { throw "Missing .github-token file in project root" }
$Token   = (Get-Content $tokenFile -Raw).Trim()
$Headers = @{ Authorization = "token $Token"; Accept = "application/vnd.github+json" }

$verJson = [System.IO.File]::ReadAllText("$WebDir\version.json", $UTF8) | ConvertFrom-Json
$Current = $verJson.version
$CurrentAndroid = $verJson.androidVersion

if (-not $NewVersion) {
    $parts = $Current.Split('.')
    $parts[2] = [string]([int]$parts[2] + 1)
    $NewVersion = $parts -join '.'
}

$ApkUrl = "https://github.com/$Repo/releases/download/v$NewVersion/app-release.apk"

Write-Host "FLL Manager: $Current -> $NewVersion (Windows + Android)" -ForegroundColor Cyan

# [1] Update files
Write-Host "[1/7] Updating files..." -ForegroundColor Yellow

$f = [System.IO.File]::ReadAllText("$WebDir\version.json", $UTF8)
$f = $f -replace [regex]::Escape("`"version`": `"$Current`""), "`"version`": `"$NewVersion`""
$f = $f -replace [regex]::Escape("`"androidVersion`": `"$CurrentAndroid`""), "`"androidVersion`": `"$NewVersion`""
$f = $f -replace '"downloadUrl": "[^"]*"', "`"downloadUrl`": `"$ApkUrl`""
[System.IO.File]::WriteAllText("$WebDir\version.json", $f, $UTF8)

$f = [System.IO.File]::ReadAllText("$WebDir\index.html", $UTF8)
$f = $f -replace [regex]::Escape($Current), $NewVersion
[System.IO.File]::WriteAllText("$WebDir\index.html", $f, $UTF8)

$f = [System.IO.File]::ReadAllText("$WebDir\js\pwa.js", $UTF8)
$f = $f -replace [regex]::Escape($Current), $NewVersion
[System.IO.File]::WriteAllText("$WebDir\js\pwa.js", $f, $UTF8)

$f = [System.IO.File]::ReadAllText("$Root\package.json", $UTF8)
$f = $f -replace [regex]::Escape("`"version`": `"$Current`""), "`"version`": `"$NewVersion`""
[System.IO.File]::WriteAllText("$Root\package.json", $f, $UTF8)

$f = [System.IO.File]::ReadAllText("$AndroidDir\lib\main.dart", $UTF8)
$f = $f -replace "static const _currentVersion = '[^']*'", "static const _currentVersion = '$NewVersion'"
[System.IO.File]::WriteAllText("$AndroidDir\lib\main.dart", $f, $UTF8)

$f = [System.IO.File]::ReadAllText("$AndroidDir\lib\screens\settings\settings_screen.dart", $UTF8)
$f = $f -replace "(?<=גרסה )\d+\.\d+\.\d+(?= – )", $NewVersion
[System.IO.File]::WriteAllText("$AndroidDir\lib\screens\settings\settings_screen.dart", $f, $UTF8)

Write-Host "  OK" -ForegroundColor Green

# [2] Build Windows
Write-Host "[2/7] Building Windows EXE..." -ForegroundColor Yellow
Set-Location $Root
npm run build
$ExePath = "$Root\dist\FLL Manager Setup $NewVersion.exe"
if (-not (Test-Path $ExePath)) { throw "EXE not found after build" }
$exeMB = [int]((Get-Item $ExePath).Length / 1MB)
Write-Host "  OK ($exeMB MB)" -ForegroundColor Green

# [3] Build Android
Write-Host "[3/7] Building Android APK..." -ForegroundColor Yellow
Set-Location $AndroidDir
flutter build apk --release
$ApkPath = "$AndroidDir\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $ApkPath)) { throw "APK not found after build" }
$apkMB = [int]((Get-Item $ApkPath).Length / 1MB)
Write-Host "  OK ($apkMB MB)" -ForegroundColor Green

# [4] Git push
Write-Host "[4/7] Git push..." -ForegroundColor Yellow
git -C $WebDir     add index.html version.json js/pwa.js
git -C $AndroidDir add lib/main.dart lib/screens/settings/settings_screen.dart
git -C $Root       add package.json main.js
git -C $Root       commit -m "Release v$NewVersion"
git -C $Root       push
Write-Host "  OK" -ForegroundColor Green

# [5] Firebase
Write-Host "[5/7] Firebase deploy..." -ForegroundColor Yellow
Set-Location $WebDir
firebase deploy --only hosting | Out-Null
Write-Host "  OK" -ForegroundColor Green

# [6] GitHub Release + EXE
Write-Host "[6/7] Creating GitHub Release..." -ForegroundColor Yellow
$body = @{
    tag_name   = "v$NewVersion"
    name       = "FLL Manager v$NewVersion"
    body       = "v$NewVersion - Windows + Android"
    draft      = $false
    prerelease = $false
} | ConvertTo-Json
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Method POST -Headers $Headers -Body $body -ContentType "application/json"

$url   = "https://uploads.github.com/repos/$Repo/releases/$($release.id)/assets?name=FLL.Manager.Setup.exe"
$bytes = [System.IO.File]::ReadAllBytes($ExePath)
Invoke-RestMethod -Uri $url -Method POST -Headers $Headers -Body $bytes -ContentType "application/octet-stream" | Out-Null
Write-Host "  OK - EXE uploaded" -ForegroundColor Green

# [7] Upload APK
Write-Host "[7/7] Uploading APK..." -ForegroundColor Yellow
$url   = "https://uploads.github.com/repos/$Repo/releases/$($release.id)/assets?name=app-release.apk"
$bytes = [System.IO.File]::ReadAllBytes($ApkPath)
Invoke-RestMethod -Uri $url -Method POST -Headers $Headers -Body $bytes -ContentType "application/octet-stream" | Out-Null
Write-Host "  OK - APK uploaded" -ForegroundColor Green

Write-Host ""
Write-Host "Done! v$NewVersion released - Windows + Android synced." -ForegroundColor Green
