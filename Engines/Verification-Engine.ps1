$ErrorActionPreference = "Stop"

function Test-RequiredFiles {
    param(
        [Parameter(Mandatory)][string[]]$Paths
    )
    foreach ($p in $Paths) {
        [pscustomobject]@{
            Path = $p
            Exists = (Test-Path -LiteralPath $p)
            Size = if (Test-Path -LiteralPath $p) { (Get-Item $p).Length } else { 0 }
        }
    }
}

function Test-TextNotEmpty {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return -not [string]::IsNullOrWhiteSpace((Get-Content -LiteralPath $Path -Raw))
}
