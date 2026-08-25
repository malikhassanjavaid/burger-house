$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$helperPath = Join-Path $PSScriptRoot "android_plugin_cache.ps1"
$fixtureRoot = Join-Path $projectRoot ".dart_tool\android-plugin-cache-tests"
$metadataPath = Join-Path $fixtureRoot ".flutter-plugins-dependencies"
$fingerprintPath = Join-Path $fixtureRoot "android-plugin-fingerprint.txt"
$safeFixtureParent = [IO.Path]::GetFullPath((Join-Path $projectRoot ".dart_tool"))
$resolvedFixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)

if (-not $resolvedFixtureRoot.StartsWith($safeFixtureParent + [IO.Path]::DirectorySeparatorChar)) {
    throw "FAIL: fixture cleanup escaped the project .dart_tool directory."
}

if (-not (Test-Path -LiteralPath $helperPath)) {
    throw "FAIL: the Android plugin cache guard has not been implemented."
}

. $helperPath

foreach ($commandName in @(
    "Get-AndroidPluginFingerprint",
    "Test-AndroidPluginRefreshRequired",
    "Save-AndroidPluginFingerprint"
)) {
    if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
        throw "FAIL: missing Android plugin cache command '$commandName'."
    }
}

function Write-PluginMetadataFixture {
    param([string]$CloudFunctionsVersion)

    $metadata = @{
        plugins = @{
            android = @(
                @{
                    name = "cloud_functions"
                    path = "C:\pub-cache\cloud_functions-$CloudFunctionsVersion\"
                    native_build = $true
                    dependencies = @("firebase_core")
                },
                @{
                    name = "firebase_core"
                    path = "C:\pub-cache\firebase_core-4.14.0\"
                    native_build = $true
                    dependencies = @()
                }
            )
        }
    }

    $metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metadataPath -Encoding UTF8
}

try {
    New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
    Write-PluginMetadataFixture -CloudFunctionsVersion "6.3.6"

    if (-not (Test-AndroidPluginRefreshRequired -PluginMetadataPath $metadataPath -FingerprintPath $fingerprintPath)) {
        throw "FAIL: a missing fingerprint did not request a Gradle refresh."
    }

    $initialFingerprint = Get-AndroidPluginFingerprint -PluginMetadataPath $metadataPath
    Save-AndroidPluginFingerprint -Fingerprint $initialFingerprint -FingerprintPath $fingerprintPath

    if (Test-AndroidPluginRefreshRequired -PluginMetadataPath $metadataPath -FingerprintPath $fingerprintPath) {
        throw "FAIL: unchanged Android plugins requested an unnecessary Gradle refresh."
    }

    Write-PluginMetadataFixture -CloudFunctionsVersion "6.4.0"
    if (-not (Test-AndroidPluginRefreshRequired -PluginMetadataPath $metadataPath -FingerprintPath $fingerprintPath)) {
        throw "FAIL: an Android plugin version/path change did not request a Gradle refresh."
    }

    Write-Host "PASS: Android plugin cache invalidation detects missing, unchanged, and upgraded plugin states."
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
