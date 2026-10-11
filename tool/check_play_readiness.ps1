# Play Market readiness check (no AAB build).
# Exit 0 = ready to build; exit 1 = blockers remain.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$blockers = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$ok = New-Object System.Collections.Generic.List[string]

function Write-Ok([string]$msg) {
    $ok.Add($msg) | Out-Null
    Write-Host "[OK]  $msg" -ForegroundColor Green
}
function Write-WarnItem([string]$msg) {
    $warnings.Add($msg) | Out-Null
    Write-Host "[WARN] $msg" -ForegroundColor Yellow
}
function Write-Block([string]$msg) {
    $blockers.Add($msg) | Out-Null
    Write-Host "[BLOCK] $msg" -ForegroundColor Red
}

# Version
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match '(?m)^version:\s*([0-9.]+)\+(\d+)') {
    $versionName = $Matches[1]
    $versionCode = [int]$Matches[2]
    Write-Ok "version $versionName+$versionCode (versionCode=$versionCode)"
    if ($versionCode -lt 9) {
        Write-WarnItem "versionCode $versionCode may already be on Play (history jumped 5 to 8). Prefer >= 9 before upload."
    }
} else {
    Write-Block "Could not parse version from pubspec.yaml"
}

# Package / Firebase
$buildGradle = Get-Content "android\app\build.gradle" -Raw
$appId = $null
if ($buildGradle -match 'applicationId\s+"([^"]+)"') {
    $appId = $Matches[1]
    Write-Ok "applicationId $appId"
} else {
    Write-Block "applicationId missing in android/app/build.gradle"
}

if (Test-Path "android\app\google-services.json") {
    $gs = Get-Content "android\app\google-services.json" -Raw | ConvertFrom-Json
    $pkg = $gs.client[0].client_info.android_client_info.package_name
    if ($appId -and $pkg -eq $appId) {
        Write-Ok "google-services.json package_name matches ($pkg)"
    } else {
        Write-Block "google-services.json package_name '$pkg' != applicationId '$appId'"
    }
} else {
    Write-Block "android/app/google-services.json missing"
}

# Signing
if (Test-Path "android\app\upload-keystore.jks") {
    Write-Ok "upload-keystore.jks present"
} else {
    Write-Block "android/app/upload-keystore.jks missing"
}

if (Test-Path "android\key.properties") {
    $kp = Get-Content "android\key.properties" -Raw
    $hasPlaceholders = $kp -match 'YOUR_|REPLACE|PLACEHOLDER'
    $hasAlias = $kp -match 'keyAlias\s*='
    $hasStore = $kp -match 'storeFile\s*='
    if ($hasPlaceholders) {
        Write-Block "android/key.properties still has placeholder passwords - fill real values"
    } elseif ($hasAlias -and $hasStore) {
        Write-Ok "android/key.properties present (not validated against keystore)"
    } else {
        Write-Block "android/key.properties incomplete (need keyAlias, storeFile, passwords)"
    }
} else {
    Write-Block "android/key.properties missing - copy from key.properties.example and fill passwords"
    if (Test-Path "android\key.properties.example") {
        Write-WarnItem "Template ready: android/key.properties.example"
    }
}

# Manifest essentials
$manifest = Get-Content "android\app\src\main\AndroidManifest.xml" -Raw
$perms = @(
    "android.permission.INTERNET",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.CAMERA",
    "android.permission.READ_MEDIA_IMAGES"
)
foreach ($perm in $perms) {
    if ($manifest -match [regex]::Escape($perm)) {
        Write-Ok "permission $perm"
    } else {
        Write-WarnItem "permission $perm not declared"
    }
}

if ($manifest -match 'ic_notification') {
    Write-Ok "FCM default_notification_icon set"
} else {
    Write-WarnItem "FCM notification icon meta missing"
}

if (Test-Path "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png") {
    Write-Ok "launcher icon mipmaps present"
} else {
    Write-Block "launcher icon missing"
}

# Privacy / account deletion
if (Test-Path "assets\pdfs\privacy_policy.pdf") {
    Write-Ok "in-app privacy_policy.pdf present"
} else {
    Write-WarnItem "assets/pdfs/privacy_policy.pdf missing"
}

$profile = Get-Content "lib\profile\profile_widget.dart" -Raw -ErrorAction SilentlyContinue
if ($profile -and $profile -match 'dltacnt01|delete_own_account') {
    Write-Ok "account deletion UI present"
} else {
    Write-WarnItem "could not confirm account deletion UI in profile"
}

# Play Console (manual)
Write-WarnItem "Play Console still manual: Data safety, public privacy HTTPS URL, content rating, screenshots - see docs/play_market_submission_guide.md"

Write-Host ""
Write-Host ("Summary: {0} OK, {1} warnings, {2} blockers" -f $ok.Count, $warnings.Count, $blockers.Count)
if ($blockers.Count -gt 0) {
    Write-Host "Not ready to build a signed AAB until blockers are fixed." -ForegroundColor Red
    exit 1
}

Write-Host "Code-side ready. Complete Play Console items, then: flutter build appbundle --release" -ForegroundColor Green
exit 0
