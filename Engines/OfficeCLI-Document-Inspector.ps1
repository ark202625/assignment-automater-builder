$ErrorActionPreference = "Stop"

function Resolve-LocalOfficeCLI {
    param([string]$Root)

    $candidates = @(
        (Join-Path $Root "Tools\officecli.exe"),
        (Join-Path $env:LOCALAPPDATA "OfficeCLI\officecli.exe")
    )
    foreach ($p in $candidates) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }
    $cmd = Get-Command officecli.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Invoke-LocalOfficeCLI {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $exe = Resolve-LocalOfficeCLI -Root $Root
    if (-not $exe) { throw "OfficeCLI is not available. Put officecli.exe in Tools\ or install it." }

    $out = & $exe @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "OfficeCLI failed ($LASTEXITCODE):`n$($out -join [Environment]::NewLine)"
    }
    $out
}

function Inspect-OfficeDocument {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path)) { throw "File not found: $Path" }
    Invoke-LocalOfficeCLI -Root $Root -Arguments @("view",$Path)
}

function Validate-OfficeDocument {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path)) { throw "File not found: $Path" }
    Invoke-LocalOfficeCLI -Root $Root -Arguments @("validate",$Path)
}
