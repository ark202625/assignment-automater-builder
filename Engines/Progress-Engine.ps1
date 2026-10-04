function Write-AutomaterProgress {
    param(
        [Parameter(Mandatory)][string]$Stage,
        [Parameter(Mandatory)][string]$Message
    )
    Write-Host ("[{0}] {1}" -f $Stage.ToUpperInvariant(),$Message)
}
