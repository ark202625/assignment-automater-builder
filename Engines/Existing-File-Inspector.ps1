$ErrorActionPreference = "Stop"

function Get-AssignmentFiles {
    param([Parameter(Mandatory)][string]$Root)

    if (-not (Test-Path -LiteralPath $Root)) { return @() }

    Get-ChildItem -LiteralPath $Root -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in ".docx",".xlsx",".xls",".pptx",".ppt",".pdf",".txt",".csv" } |
        ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                FullName = $_.FullName
                Extension = $_.Extension.ToLowerInvariant()
                Length = $_.Length
                LastWriteTime = $_.LastWriteTime
            }
        }
}

function Get-FileInventory {
    param([Parameter(Mandatory)][string]$Root)

    Get-AssignmentFiles -Root $Root |
        Sort-Object Extension, Name
}

function Save-FileInventory {
    param(
        [Parameter(Mandatory)]$Inventory,
        [Parameter(Mandatory)][string]$Path
    )
    $Inventory | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}
