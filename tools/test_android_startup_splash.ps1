$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$apkPath = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-debug.apk"
$identityHelper = Join-Path $PSScriptRoot "android_apk_identity.ps1"
$androidSdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"

if (-not (Test-Path -LiteralPath $apkPath)) {
    throw "FAIL: build the debug APK before testing its startup splash resources."
}

. $identityHelper
$aapt = Resolve-AndroidAapt -AndroidSdkRoot $androidSdkRoot
$resourceLines = @(& $aapt dump --values resources $apkPath 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: unable to inspect compiled Android resources."
}

$resourceDump = $resourceLines -join [Environment]::NewLine
$transparentIconMatch = [regex]::Match(
    $resourceDump,
    "spec resource (0x[0-9a-f]+) [^\r\n]+:drawable/transparent_splash_icon:"
)
if (-not $transparentIconMatch.Success) {
    throw "FAIL: Android 12 still shows the visible launcher icon before Flutter's branded splash."
}

$transparentIconId = $transparentIconMatch.Groups[1].Value
$usesTransparentIcon = $false
for ($index = 0; $index -lt $resourceLines.Count; $index++) {
    if ($resourceLines[$index] -notmatch ":style/LaunchTheme: <bag>") {
        continue
    }

    for ($entry = $index + 1; $entry -lt $resourceLines.Count; $entry++) {
        if ($resourceLines[$entry] -match "^\s*resource ") {
            break
        }
        if (
            $resourceLines[$entry] -match "Key=0x0101062d" -and
            $resourceLines[$entry] -match [regex]::Escape($transparentIconId)
        ) {
            $usesTransparentIcon = $true
            break
        }
    }
}

if (-not $usesTransparentIcon) {
    throw "FAIL: the compiled Android 12 LaunchTheme does not suppress the duplicate launcher icon."
}

Write-Host "PASS: Android 12 hands off to Flutter without a second visible logo treatment."
