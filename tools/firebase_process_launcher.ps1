function Resolve-FirebaseCliEntryPoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShimPath
    )

    $shimDirectory = Split-Path -Parent ([IO.Path]::GetFullPath($ShimPath))
    $candidatePaths = @(
        (Join-Path $shimDirectory "node_modules\firebase-tools\lib\bin\firebase.js")
        (Join-Path $shimDirectory "..\firebase-tools\lib\bin\firebase.js")
    )

    foreach ($candidatePath in $candidatePaths) {
        $fullPath = [IO.Path]::GetFullPath($candidatePath)
        if (Test-Path -LiteralPath $fullPath) {
            return $fullPath
        }
    }

    throw "The Firebase CLI entry point could not be resolved from shim '$ShimPath'."
}

function Start-FirebaseFunctionsEmulator {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NodePath,

        [Parameter(Mandatory = $true)]
        [string]$FirebaseEntryPoint,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [Parameter(Mandatory = $true)]
        [string]$StandardOutputLog,

        [Parameter(Mandatory = $true)]
        [string]$StandardErrorLog
    )

    $argumentLine = "`"$FirebaseEntryPoint`" emulators:start --only functions --project `"$ProjectId`""
    $originalPath = $env:PATH
    try {
        $env:PATH = "$(Split-Path -Parent $NodePath);$originalPath"
        return Start-Process `
            -FilePath $NodePath `
            -ArgumentList $argumentLine `
            -WorkingDirectory $ProjectRoot `
            -WindowStyle Hidden `
            -RedirectStandardOutput $StandardOutputLog `
            -RedirectStandardError $StandardErrorLog `
            -PassThru
    }
    finally {
        $env:PATH = $originalPath
    }
}
