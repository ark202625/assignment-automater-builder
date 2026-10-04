$ErrorActionPreference = "Stop"

function Invoke-KeyWorkflow {
    param(
        [Parameter(Mandatory)][hashtable]$Key
    )

    $root = $PSScriptRoot
    while ((Split-Path -Leaf $root) -ne "Assignment-Automater" -and (Split-Path -Parent $root) -ne $root) {
        $root = Split-Path -Parent $root
    }
    [pscustomobject]@{
        EXP = $Key.Assignment.EXP
        PDF = $Key.Assignment.PDF
        Root = $root
        Status = "Controller loaded; main engine should perform assignment-specific execution."
    }
}
