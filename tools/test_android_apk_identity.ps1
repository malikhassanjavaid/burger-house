$ErrorActionPreference = "Stop"

$helperPath = Join-Path $PSScriptRoot "android_apk_identity.ps1"

if (-not (Test-Path -LiteralPath $helperPath)) {
    throw "FAIL: the Android APK identity helper has not been implemented."
}

. $helperPath

if (-not (Get-Command ConvertFrom-AndroidApkBadging -ErrorAction SilentlyContinue)) {
    throw "FAIL: APK badging parsing has not been implemented."
}

$badging = @"
package: name='com.malikhassanjavaid.hungryspot' versionCode='1' versionName='1.0.0'
sdkVersion:'24'
launchable-activity: name='com.malikhassanjavaid.hungryspot.MainActivity' label='' icon=''
"@

$identity = ConvertFrom-AndroidApkBadging -Badging $badging
if ($identity.PackageName -ne "com.malikhassanjavaid.hungryspot") {
    throw "FAIL: package name was not parsed from APK badging."
}
if ($identity.ActivityName -ne "com.malikhassanjavaid.hungryspot.MainActivity") {
    throw "FAIL: launchable activity was not parsed from APK badging."
}
if ($identity.ComponentName -ne "com.malikhassanjavaid.hungryspot/com.malikhassanjavaid.hungryspot.MainActivity") {
    throw "FAIL: Android component name was not assembled correctly."
}

$missingActivityFailed = $false
try {
    ConvertFrom-AndroidApkBadging -Badging "package: name='com.example.renamed' versionCode='1'" | Out-Null
}
catch {
    $missingActivityFailed = $_.Exception.Message -match "launchable activity"
}

if (-not $missingActivityFailed) {
    throw "FAIL: missing launchable activity metadata did not produce a clear error."
}

Write-Host "PASS: Android APK package and launchable activity metadata are resolved dynamically."
