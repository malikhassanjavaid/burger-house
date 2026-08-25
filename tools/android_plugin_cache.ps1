function Get-AndroidPluginFingerprint {
    param([Parameter(Mandatory = $true)][string]$PluginMetadataPath)

    if (-not (Test-Path -LiteralPath $PluginMetadataPath)) {
        throw "Flutter Android plugin metadata is missing at '$PluginMetadataPath'. Run 'flutter pub get' first."
    }

    $metadata = Get-Content -LiteralPath $PluginMetadataPath -Raw | ConvertFrom-Json
    $androidPlugins = @($metadata.plugins.android)
    $normalizedPlugins = @(
        $androidPlugins |
            Sort-Object -Property name |
            ForEach-Object {
                $dependencies = @($_.dependencies) | Sort-Object
                "{0}|{1}|{2}|{3}" -f `
                    ([string]$_.name).Trim(),
                    ([IO.Path]::GetFullPath([string]$_.path)).TrimEnd('\'),
                    [bool]$_.native_build,
                    ($dependencies -join ',')
            }
    )
    $payload = $normalizedPlugins -join "`n"
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Test-AndroidPluginRefreshRequired {
    param(
        [Parameter(Mandatory = $true)][string]$PluginMetadataPath,
        [Parameter(Mandatory = $true)][string]$FingerprintPath
    )

    if (-not (Test-Path -LiteralPath $FingerprintPath)) {
        return $true
    }

    $savedFingerprint = (Get-Content -LiteralPath $FingerprintPath -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($savedFingerprint)) {
        return $true
    }

    $currentFingerprint = Get-AndroidPluginFingerprint -PluginMetadataPath $PluginMetadataPath
    return $savedFingerprint -ne $currentFingerprint
}

function Save-AndroidPluginFingerprint {
    param(
        [Parameter(Mandatory = $true)][string]$Fingerprint,
        [Parameter(Mandatory = $true)][string]$FingerprintPath
    )

    $fingerprintDirectory = Split-Path -Parent $FingerprintPath
    New-Item -ItemType Directory -Path $fingerprintDirectory -Force | Out-Null
    Set-Content -LiteralPath $FingerprintPath -Value $Fingerprint.Trim() -Encoding ASCII
}

function Resolve-FlutterJavaExecutable {
    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
        $candidates += Join-Path $env:JAVA_HOME "bin\java.exe"
    }

    try {
        $flutterConfig = (& flutter config --machine 2>$null | Out-String) | ConvertFrom-Json
        $configuredJdk = [string]$flutterConfig.'jdk-dir'
        if (-not [string]::IsNullOrWhiteSpace($configuredJdk)) {
            $candidates += Join-Path $configuredJdk "bin\java.exe"
        }
    }
    catch {
        # Fall through to Android Studio and PATH discovery.
    }

    $candidates += Join-Path $env:ProgramFiles "Android\Android Studio\jbr\bin\java.exe"
    $pathJava = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($null -ne $pathJava) {
        $candidates += $pathJava.Source
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (Test-Path -LiteralPath $candidate) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }

    throw "Flutter's Java runtime could not be found. Run 'flutter doctor -v' and configure a JDK."
}

function Clear-AndroidGradleOutputs {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $resolvedProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
    $androidRoot = [IO.Path]::GetFullPath((Join-Path $resolvedProjectRoot "android"))
    $wrapperJar = Join-Path $androidRoot "gradle\wrapper\gradle-wrapper.jar"
    if (-not (Test-Path -LiteralPath $wrapperJar)) {
        throw "The Android Gradle wrapper was not found at '$wrapperJar'."
    }

    $java = Resolve-FlutterJavaExecutable
    Push-Location -LiteralPath $androidRoot
    try {
        & $java `
            "-Dorg.gradle.appname=gradlew" `
            -classpath "gradle\wrapper\gradle-wrapper.jar" `
            org.gradle.wrapper.GradleWrapperMain `
            clean `
            --console=plain
        if ($LASTEXITCODE -ne 0) {
            throw "Gradle could not clear stale Android plugin outputs."
        }
    }
    finally {
        Pop-Location
    }
}
