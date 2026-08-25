param(
    [string]$DeviceId = "",
    [int]$VmServicePort = 33391,
    [switch]$ReuseBuiltApk
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$apk = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-debug.apk"
$stripeConfig = Join-Path $projectRoot "stripe.config.json"
$functionsSecret = Join-Path $projectRoot "functions\.secret.local"
$firebaseNodeHelper = Join-Path $PSScriptRoot "firebase_node_runtime.ps1"
$firebaseProcessHelper = Join-Path $PSScriptRoot "firebase_process_launcher.ps1"
$androidPluginCacheHelper = Join-Path $PSScriptRoot "android_plugin_cache.ps1"
$pluginMetadata = Join-Path $projectRoot ".flutter-plugins-dependencies"
$pluginFingerprint = Join-Path $projectRoot ".dart_tool\android-plugin-fingerprint.txt"
$projectFirebaseNode = Join-Path $projectRoot ".dart_tool\firebase-node-v22\node.exe"
$emulatorOutLog = Join-Path $projectRoot ".dart_tool\stripe-functions-emulator.out.log"
$emulatorErrorLog = Join-Path $projectRoot ".dart_tool\stripe-functions-emulator.error.log"
$packageName = "com.example.flutter_application_1"
$activityName = "$packageName/.MainActivity"
$functionsPort = 5001
$stripeFunctionUrl = "http://127.0.0.1:$functionsPort/burger-house-80541/us-central1/createPaymentIntent"

. $firebaseNodeHelper
. $firebaseProcessHelper
. $androidPluginCacheHelper

function Test-LocalPort {
    param([int]$Port)

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $connect = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        if (-not $connect.AsyncWaitHandle.WaitOne(500)) {
            return $false
        }
        $client.EndConnect($connect)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Test-StripeFunctions {
    if (-not (Test-LocalPort -Port $functionsPort)) {
        return $false
    }

    try {
        Invoke-WebRequest `
            -Uri $stripeFunctionUrl `
            -Method Post `
            -ContentType "application/json" `
            -Body '{"data":{}}' `
            -TimeoutSec 5 `
            -UseBasicParsing | Out-Null
        return $true
    }
    catch {
        if ($null -eq $_.Exception.Response) {
            return $false
        }

        $statusCode = [int]$_.Exception.Response.StatusCode
        return $statusCode -in @(400, 401, 403)
    }
}

function Assert-AndroidDeviceReady {
    param([string]$Id)

    $state = (& $adb -s $Id get-state 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $state -ne "device") {
        throw @"
The Android phone is no longer connected or authorized.
Unlock it, accept the USB debugging prompt, keep the cable connected, and run this command again.
"@
    }
}

function Set-StripeReverseTunnel {
    param([string]$Id)

    Assert-AndroidDeviceReady -Id $Id
    & $adb -s $Id reverse "tcp:$functionsPort" "tcp:$functionsPort" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "ADB reverse failed for Android device '$Id'."
    }

    $rules = (& $adb -s $Id reverse --list 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or $rules -notmatch "tcp:$functionsPort\s+tcp:$functionsPort") {
        throw "The phone could not be linked to the local Stripe service on port $functionsPort."
    }
}

if (-not (Test-Path -LiteralPath $adb)) {
    throw "ADB was not found at $adb"
}

if (-not (Test-Path -LiteralPath $stripeConfig)) {
    throw @"
Stripe test configuration is missing at:
$stripeConfig

Create it from stripe.config.example.json and add your pk_test_ publishable key.
"@
}

$stripeSettings = Get-Content -LiteralPath $stripeConfig -Raw | ConvertFrom-Json
$publishableKey = [string]$stripeSettings.STRIPE_PUBLISHABLE_KEY
if (-not $publishableKey.StartsWith("pk_test_")) {
    throw "STRIPE_PUBLISHABLE_KEY in stripe.config.json must be a Stripe test publishable key beginning with pk_test_."
}

if (-not (Test-Path -LiteralPath $functionsSecret)) {
    throw @"
The local Stripe server secret is missing at:
$functionsSecret

Copy functions/.secret.local.example to functions/.secret.local and put your rotated sk_test_ key in that local file.
"@
}

Set-Location -LiteralPath $projectRoot

$adbDeviceRows = @(& $adb devices -l)
if ($LASTEXITCODE -ne 0) {
    throw "ADB could not list connected devices. Reconnect your phone and try again."
}

$connectedDeviceIds = @(
    $adbDeviceRows |
        ForEach-Object {
            if ($_ -match "^\s*(\S+)\s+device(?:\s|$)") {
                $Matches[1]
            }
        }
)

if ($connectedDeviceIds.Count -eq 0) {
    Write-Host "No phone detected. Restarting ADB once..." -ForegroundColor Yellow
    & $adb kill-server | Out-Null
    & $adb start-server | Out-Null
    Start-Sleep -Seconds 2

    $adbDeviceRows = @(& $adb devices -l)
    $connectedDeviceIds = @(
        $adbDeviceRows |
            ForEach-Object {
                if ($_ -match "^\s*(\S+)\s+device(?:\s|$)") {
                    $Matches[1]
                }
            }
    )
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    if ($connectedDeviceIds.Count -eq 0) {
        throw @"
No authorized Android device was found.
1. Connect your phone with a data-capable USB cable.
2. Enable Developer options and USB debugging.
3. Unlock the phone and accept the 'Allow USB debugging' prompt.
4. Run this command again.
"@
    }

    $DeviceId = $connectedDeviceIds[0]
}
elseif ($DeviceId -notin $connectedDeviceIds) {
    throw "Android device '$DeviceId' is not connected or authorized. Available devices: $($connectedDeviceIds -join ', ')"
}

Write-Host "Using Android device $DeviceId." -ForegroundColor Green

Assert-AndroidDeviceReady -Id $DeviceId

if ((Test-LocalPort -Port $functionsPort) -and -not (Test-StripeFunctions)) {
    Write-Host "Restarting an incomplete Firebase Functions emulator..." -ForegroundColor Yellow
    $emulatorOwners = Get-NetTCPConnection -State Listen -LocalPort $functionsPort -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($ownerId in $emulatorOwners) {
        $owner = Get-CimInstance Win32_Process -Filter "ProcessId=$ownerId"
        if ($owner.CommandLine -match "firebase.*emulators:start") {
            Stop-Process -Id $ownerId -Force
        }
    }
    for ($attempt = 0; $attempt -lt 20 -and (Test-LocalPort -Port $functionsPort); $attempt++) {
        Start-Sleep -Milliseconds 250
    }
}

if (-not (Test-StripeFunctions)) {
    $firebaseCommand = Get-Command firebase.cmd -ErrorAction SilentlyContinue
    if ($null -eq $firebaseCommand) {
        throw "Firebase CLI was not found. Install it with: npm install -g firebase-tools"
    }

    $hostNodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
    $firebaseNode = Resolve-FirebaseNodeRuntime -CandidatePaths @(
        $projectFirebaseNode
        if ($null -ne $hostNodeCommand) { $hostNodeCommand.Source }
    )
    $firebaseEntryPoint = Resolve-FirebaseCliEntryPoint -ShimPath $firebaseCommand.Source

    New-Item -ItemType Directory -Path (Split-Path -Parent $emulatorOutLog) -Force | Out-Null
    Remove-Item -LiteralPath $emulatorOutLog -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $emulatorErrorLog -Force -ErrorAction SilentlyContinue

    $env:FUNCTIONS_DISCOVERY_TIMEOUT = "60"

    Write-Host "Starting the local Stripe payment function..." -ForegroundColor Cyan
    Start-FirebaseFunctionsEmulator `
        -NodePath $firebaseNode `
        -FirebaseEntryPoint $firebaseEntryPoint `
        -ProjectRoot $projectRoot `
        -ProjectId "burger-house-80541" `
        -StandardOutputLog $emulatorOutLog `
        -StandardErrorLog $emulatorErrorLog | Out-Null

    $emulatorReady = $false
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        Start-Sleep -Milliseconds 500
        if (Test-StripeFunctions) {
            $emulatorReady = $true
            break
        }
    }

    if (-not $emulatorReady) {
        $details = ""
        if (Test-Path -LiteralPath $emulatorErrorLog) {
            $details = (Get-Content -LiteralPath $emulatorErrorLog -Tail 20) -join [Environment]::NewLine
        }
        throw "The local Stripe payment functions were not registered on port $functionsPort.`n$details"
    }
}

Write-Host "Connecting the phone to the local Stripe payment function..." -ForegroundColor Cyan
Set-StripeReverseTunnel -Id $DeviceId
Write-Host "Stripe test connection verified on the phone." -ForegroundColor Green

if ($ReuseBuiltApk) {
    Write-Host "Refreshing the APK so the current Stripe test configuration is embedded..." -ForegroundColor Yellow
}

Write-Host "Refreshing Flutter dependency metadata..." -ForegroundColor Cyan
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    throw "Flutter dependency resolution failed."
}

$refreshAndroidPlugins = Test-AndroidPluginRefreshRequired `
    -PluginMetadataPath $pluginMetadata `
    -FingerprintPath $pluginFingerprint
$currentAndroidPluginFingerprint = Get-AndroidPluginFingerprint -PluginMetadataPath $pluginMetadata
if ($refreshAndroidPlugins) {
    Write-Host "Android plugin versions changed. Clearing stale Gradle plugin outputs once..." -ForegroundColor Yellow
    Clear-AndroidGradleOutputs -ProjectRoot $projectRoot
}

Write-Host "Building the Hungry Spot debug APK with Stripe test mode..." -ForegroundColor Cyan
& flutter build apk `
    --debug `
    "--dart-define-from-file=$stripeConfig" `
    --dart-define=USE_FIREBASE_EMULATORS=true `
    --dart-define=FUNCTIONS_EMULATOR_HOST=127.0.0.1 `
    "--dart-define=FUNCTIONS_EMULATOR_PORT=$functionsPort"
if ($LASTEXITCODE -ne 0) {
    throw "Flutter build failed."
}
Save-AndroidPluginFingerprint `
    -Fingerprint $currentAndroidPluginFingerprint `
    -FingerprintPath $pluginFingerprint

$phoneReady = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    $postBuildDevices = @(& $adb devices)
    if ($postBuildDevices -match "^$([regex]::Escape($DeviceId))\s+device(?:\s|$)") {
        $phoneReady = $true
        break
    }

    if ($attempt -eq 0) {
        Write-Host "Waiting for the phone to reconnect..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 1
}

if (-not $phoneReady) {
    throw @"
The APK built successfully, but the phone disconnected before installation.
Reconnect and unlock the phone, accept the USB debugging prompt, then run:

powershell -ExecutionPolicy Bypass -File ".\tools\run_hot_reload.ps1" -ReuseBuiltApk
"@
}

Write-Host "Restoring the Stripe tunnel before installation..." -ForegroundColor Cyan
Set-StripeReverseTunnel -Id $DeviceId

Write-Host "Installing the debug APK on $DeviceId..." -ForegroundColor Cyan
& $adb -s $DeviceId install -r -t $apk
if ($LASTEXITCODE -ne 0) {
    throw "APK installation failed."
}

Write-Host "Restoring the Stripe tunnel after installation..." -ForegroundColor Cyan
Set-StripeReverseTunnel -Id $DeviceId

Write-Host "Starting the Dart VM service on port $VmServicePort..." -ForegroundColor Cyan
& $adb -s $DeviceId forward --remove-all | Out-Null
& $adb -s $DeviceId shell am force-stop $packageName
& $adb -s $DeviceId shell am start `
    -n $activityName `
    --ez enable-dart-profiling true `
    --ez enable-checked-mode true `
    --ez verify-entry-points true `
    --ez disable-service-auth-codes true `
    --ei vm-service-port $VmServicePort

Start-Sleep -Seconds 3

Write-Host "Verifying the Stripe tunnel after app launch..." -ForegroundColor Cyan
Set-StripeReverseTunnel -Id $DeviceId

& $adb -s $DeviceId forward "tcp:$VmServicePort" "tcp:$VmServicePort"
if ($LASTEXITCODE -ne 0) {
    throw "ADB port forwarding failed."
}

Write-Host ""
Write-Host "Stripe test mode is configured for this launch." -ForegroundColor Green
Write-Host "Attaching Flutter. Keep this terminal open." -ForegroundColor Green
Write-Host "Press r for hot reload, R for hot restart, and q to quit." -ForegroundColor Green
Write-Host ""

& flutter attach --debug-uri "http://127.0.0.1:$VmServicePort/"
