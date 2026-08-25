function Resolve-FirebaseNodeRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CandidatePaths,

        [scriptblock]$VersionReader = {
            param($path)
            (& $path --version 2>&1 | Out-String).Trim()
        }
    )

    foreach ($candidatePath in $CandidatePaths) {
        if ([string]::IsNullOrWhiteSpace($candidatePath)) {
            continue
        }

        try {
            $version = [string](& $VersionReader $candidatePath)
        }
        catch {
            continue
        }

        if ($version -match '^v?(\d+)\.') {
            $majorVersion = [int]$Matches[1]
            if ($majorVersion -in @(20, 22)) {
                return $candidatePath
            }
        }
    }

    throw @"
The Firebase Functions emulator requires Node.js 20 or 22, but no supported runtime was found.
Install Node.js 22 LTS or place its portable Windows runtime at:
.dart_tool\firebase-node-v22\node.exe
"@
}
