$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$helperPath = Join-Path $PSScriptRoot "firebase_node_runtime.ps1"
$processHelperPath = Join-Path $PSScriptRoot "firebase_process_launcher.ps1"
$portableNode = Join-Path $projectRoot ".dart_tool\firebase-node-v22\node.exe"
$fixtureRoot = Join-Path $projectRoot ".dart_tool\firebase launcher tests"

. $helperPath
. $processHelperPath

if (-not (Get-Command Resolve-FirebaseCliEntryPoint -ErrorAction SilentlyContinue)) {
    throw "FAIL: Firebase CLI entry-point resolution has not been implemented."
}
if (-not (Get-Command Start-FirebaseFunctionsEmulator -ErrorAction SilentlyContinue)) {
    throw "FAIL: safe Firebase process launching has not been implemented."
}
if (-not (Test-Path -LiteralPath $portableNode)) {
    throw "FAIL: the project-local Node 22 test runtime is missing at $portableNode"
}

try {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }

    $globalShim = Join-Path $fixtureRoot "global-bin\firebase.cmd"
    $globalEntry = Join-Path $fixtureRoot "global-bin\node_modules\firebase-tools\lib\bin\firebase.js"
    $localShim = Join-Path $fixtureRoot "local-app\node_modules\.bin\firebase.cmd"
    $localEntry = Join-Path $fixtureRoot "local-app\node_modules\firebase-tools\lib\bin\firebase.js"
    foreach ($path in @($globalShim, $globalEntry, $localShim, $localEntry)) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        New-Item -ItemType File -Path $path -Force | Out-Null
    }

    if ((Resolve-FirebaseCliEntryPoint -ShimPath $globalShim) -ne $globalEntry) {
        throw "FAIL: the global npm Firebase CLI layout was not resolved."
    }
    if ((Resolve-FirebaseCliEntryPoint -ShimPath $localShim) -ne $localEntry) {
        throw "FAIL: the project-local npm Firebase CLI layout was not resolved."
    }

    $probeEntry = Join-Path $fixtureRoot "firebase entry with spaces\probe firebase.js"
    $stdoutLog = Join-Path $fixtureRoot "probe.out.log"
    $stderrLog = Join-Path $fixtureRoot "probe.error.log"
    New-Item -ItemType Directory -Path (Split-Path -Parent $probeEntry) -Force | Out-Null
    @'
console.log(JSON.stringify({
  args: process.argv.slice(2),
  execPath: process.execPath,
  pathFirst: process.env.PATH.split(";")[0]
}));
'@ | Set-Content -LiteralPath $probeEntry -Encoding UTF8

    $process = Start-FirebaseFunctionsEmulator `
        -NodePath $portableNode `
        -FirebaseEntryPoint $probeEntry `
        -ProjectRoot $projectRoot `
        -ProjectId "test-project" `
        -StandardOutputLog $stdoutLog `
        -StandardErrorLog $stderrLog
    if (-not $process.WaitForExit(15000)) {
        Stop-Process -Id $process.Id -Force
        throw "FAIL: the Firebase process launch probe timed out."
    }

    $probe = Get-Content -LiteralPath $stdoutLog -Raw | ConvertFrom-Json
    $expectedArgs = @("emulators:start", "--only", "functions", "--project", "test-project")
    if (($probe.args -join "|") -ne ($expectedArgs -join "|")) {
        throw "FAIL: the Firebase entry point path with spaces corrupted process arguments."
    }
    if ([IO.Path]::GetFullPath($probe.execPath) -ne [IO.Path]::GetFullPath($portableNode)) {
        throw "FAIL: Firebase was not launched by the selected Node runtime."
    }
    if ([IO.Path]::GetFullPath($probe.pathFirst) -ne [IO.Path]::GetFullPath((Split-Path -Parent $portableNode))) {
        throw "FAIL: the selected Node runtime was not first on the Firebase child PATH."
    }

    Write-Host "PASS: Firebase CLI layouts and space-safe Node 22 process launch verified."
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
