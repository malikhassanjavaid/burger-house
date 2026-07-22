param(
    [string]$DeviceId = "A9VUCP5512402322",
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
