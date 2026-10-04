$ErrorActionPreference = "Stop"

function Invoke-SafeRepairCopy {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }
    New-Item -ItemType Directory -Force (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    return $Destination
}
