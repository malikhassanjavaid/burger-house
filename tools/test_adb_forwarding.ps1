$ErrorActionPreference = "Stop"

$helperPath = Join-Path $PSScriptRoot "adb_forwarding.ps1"

if (-not (Test-Path -LiteralPath $helperPath)) {
    throw "FAIL: the ADB forwarding helper has not been implemented."
}

. $helperPath

if (-not (Get-Command Test-AdbForwardExists -ErrorAction SilentlyContinue)) {
    throw "FAIL: ADB forwarding-rule detection has not been implemented."
}

$emptyRules = @()
if (Test-AdbForwardExists -Rules $emptyRules -DeviceId "phone-1" -Port 33391) {
    throw "FAIL: an empty ADB forwarding list was treated as an existing rule."
}

$rules = @(
    "phone-1 tcp:33391 tcp:33391",
    "phone-2 tcp:44444 tcp:44444"
)
if (-not (Test-AdbForwardExists -Rules $rules -DeviceId "phone-1" -Port 33391)) {
    throw "FAIL: the matching device and local port were not detected."
}
if (Test-AdbForwardExists -Rules $rules -DeviceId "phone-2" -Port 33391) {
    throw "FAIL: a forwarding rule belonging to another device was matched."
}

Write-Host "PASS: ADB forwarding cleanup is skipped unless the exact listener exists."
