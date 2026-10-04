$ErrorActionPreference = "Stop"

function Test-AutomaterPackage {
    param([Parameter(Mandatory)][string]$Root)

    $checks = @(
        "Assignment-Automater.ps1",
        "RUN-FROM-KEY.ps1",
        "Engines\Requirement-Parser.ps1",
        "Engines\Practical-Project-Separator.ps1",
        "Engines\Existing-File-Inspector.ps1",
        "Engines\OfficeCLI-Document-Inspector.ps1",
        "Engines\Backup-Engine.ps1",
        "Engines\Verification-Engine.ps1"
    )

    foreach ($relative in $checks) {
        $path = Join-Path $Root $relative
        [pscustomobject]@{ Path=$relative; Exists=(Test-Path -LiteralPath $path) }
    }
}
