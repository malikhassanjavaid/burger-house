$ErrorActionPreference = "Stop"

function ConvertFrom-AndroidApkBadging {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Badging
    )

    $packageMatch = [regex]::Match($Badging, "(?m)^package:\s+name='([^']+)'")
    if (-not $packageMatch.Success) {
        throw "The built APK does not contain a package name in its Android metadata."
    }

    $activityMatch = [regex]::Match($Badging, "(?m)^launchable-activity:\s+name='([^']+)'")
    if (-not $activityMatch.Success) {
        throw "The built APK does not declare a launchable activity in its Android metadata."
    }

    $packageName = $packageMatch.Groups[1].Value
    $activityName = $activityMatch.Groups[1].Value

    [pscustomobject]@{
        PackageName = $packageName
        ActivityName = $activityName
        ComponentName = "$packageName/$activityName"
    }
}

function Resolve-AndroidAapt {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AndroidSdkRoot
    )

    $buildToolsRoot = Join-Path $AndroidSdkRoot "build-tools"
    if (-not (Test-Path -LiteralPath $buildToolsRoot)) {
        throw "Android SDK build tools were not found at $buildToolsRoot"
    }

    $aaptCandidates = @(
        Get-ChildItem -LiteralPath $buildToolsRoot -Directory |
            ForEach-Object {
                $candidate = Join-Path $_.FullName "aapt.exe"
                if (Test-Path -LiteralPath $candidate) {
                    [pscustomobject]@{
                        Path = $candidate
                        Version = try { [version]$_.Name } catch { [version]"0.0" }
                    }
                }
            } |
            Sort-Object Version -Descending
    )

    if ($aaptCandidates.Count -eq 0) {
        throw "Android Asset Packaging Tool (aapt.exe) was not found under $buildToolsRoot"
    }

    return $aaptCandidates[0].Path
}

function Get-AndroidApkIdentity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApkPath,

        [Parameter(Mandatory = $true)]
        [string]$AndroidSdkRoot
    )

    if (-not (Test-Path -LiteralPath $ApkPath)) {
        throw "The built APK was not found at $ApkPath"
    }

    $aapt = Resolve-AndroidAapt -AndroidSdkRoot $AndroidSdkRoot
    $badgingLines = @(& $aapt dump badging $ApkPath 2>&1)
    $aaptExitCode = $LASTEXITCODE
    if ($aaptExitCode -ne 0) {
        $details = ($badgingLines | Out-String).Trim()
        throw "Unable to read Android metadata from the built APK.`n$details"
    }

    return ConvertFrom-AndroidApkBadging -Badging ($badgingLines -join [Environment]::NewLine)
}
