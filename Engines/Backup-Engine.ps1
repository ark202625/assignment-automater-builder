$ErrorActionPreference = "Stop"

function Backup-File {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$BackupRoot,
        [string]$Label = "backup"
    )

    if (-not (Test-Path -LiteralPath $Source)) { throw "Cannot backup missing file: $Source" }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $destDir = Join-Path $BackupRoot $stamp
    New-Item -ItemType Directory -Force $destDir | Out-Null
    $dest = Join-Path $destDir ("{0}-{1}{2}" -f [IO.Path]::GetFileNameWithoutExtension($Source),$Label,[IO.Path]::GetExtension($Source))
    Copy-Item -LiteralPath $Source -Destination $dest -Force
    return $dest
}
