$ErrorActionPreference = "Stop"

function Test-AdbForwardExists {
    param(
        [string[]]$Rules,

        [Parameter(Mandatory = $true)]
        [string]$DeviceId,

        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $devicePattern = [regex]::Escape($DeviceId)
    $listenerPattern = "^\s*$devicePattern\s+tcp:$Port\s+\S+"
    return $null -ne ($Rules | Where-Object { $_ -match $listenerPattern } | Select-Object -First 1)
}
