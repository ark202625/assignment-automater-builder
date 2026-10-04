$ErrorActionPreference = "Stop"

function New-AssignmentOutputStructure {
    param(
        [Parameter(Mandatory)][string]$OutputRoot,
        [Parameter(Mandatory)][int]$EXP
    )

    $root = Join-Path $OutputRoot ("!EXP {0}" -f $EXP)
    $practical = Join-Path $root "Practical"
    $project = Join-Path $root ("Project {0}" -f $EXP)

    New-Item -ItemType Directory -Force $root,$practical,$project | Out-Null

    [pscustomobject]@{
        Root = $root
        Practical = $practical
        Project = $project
    }
}
