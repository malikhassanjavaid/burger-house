$ErrorActionPreference = "Stop"

$helperPath = Join-Path $PSScriptRoot "firebase_node_runtime.ps1"
if (-not (Test-Path -LiteralPath $helperPath)) {
    throw "FAIL: the Firebase Node runtime resolver has not been implemented."
}

. $helperPath

$versions = @{
    "project-node" = "v22.23.2"
    "host-node" = "v24.18.0"
}

$selected = Resolve-FirebaseNodeRuntime `
    -CandidatePaths @("project-node", "host-node") `
    -VersionReader { param($path) $versions[$path] }

if ($selected -ne "project-node") {
    throw "FAIL: expected the supported project runtime, got '$selected'."
}

$unsupportedError = $null
try {
    Resolve-FirebaseNodeRuntime `
        -CandidatePaths @("host-node") `
        -VersionReader { "v24.18.0" } | Out-Null
}
catch {
    $unsupportedError = $_.Exception.Message
}

if ($unsupportedError -notmatch "Node.js 20 or 22") {
    throw "FAIL: an unsupported host runtime did not produce actionable guidance."
}

Write-Host "PASS: Firebase runtime selection rejects Node 24 and prefers project-local Node 22."
