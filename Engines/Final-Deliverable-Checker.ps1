$ErrorActionPreference = "Stop"

function Get-DeliverableReport {
    param([Parameter(Mandatory)][string]$Root)

    $files = @(Get-ChildItem -LiteralPath $Root -File -Recurse -ErrorAction SilentlyContinue)
    [pscustomobject]@{
        Root = $Root
        FileCount = $files.Count
        EmptyFiles = @($files | Where-Object Length -eq 0 | Select-Object -ExpandProperty FullName)
        Extensions = @($files | Group-Object Extension | Sort-Object Name | ForEach-Object {
            [pscustomobject]@{ Extension=$_.Name; Count=$_.Count }
        })
        Ready = (($files.Count -gt 0) -and (@($files | Where-Object Length -eq 0).Count -eq 0))
    }
}
