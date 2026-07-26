param(
    [string]$DeviceId = "",
    [int]$VmServicePort = 33391
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$apk = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-debug.apk"
$packageName = "com.example.flutter_application_1"
$activityName = "$packageName/.MainActivity"

if (-not (Test-Path -LiteralPath $adb)) {
    throw "ADB was not found at $adb"
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
Write-Host "Building the Hungry Spot debug APK..." -ForegroundColor Cyan
& flutter build apk --debug
if ($LASTEXITCODE -ne 0) {
    throw "Flutter build failed."
}

Write-Host "Installing the debug APK on $DeviceId..." -ForegroundColor Cyan
& $adb -s $DeviceId install -r -t $apk
if ($LASTEXITCODE -ne 0) {
    throw "APK installation failed."
}

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

& $adb -s $DeviceId forward "tcp:$VmServicePort" "tcp:$VmServicePort"
if ($LASTEXITCODE -ne 0) {
    throw "ADB port forwarding failed."
}

Write-Host ""
Write-Host "Attaching Flutter. Keep this terminal open." -ForegroundColor Green
Write-Host "Press r for hot reload, R for hot restart, and q to quit." -ForegroundColor Green
Write-Host ""

& flutter attach --debug-uri "http://127.0.0.1:$VmServicePort/"
