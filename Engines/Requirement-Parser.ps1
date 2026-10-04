$ErrorActionPreference = "Stop"

function Get-AssignmentRequirements {
    param(
        [Parameter(Mandatory)][string]$Text
    )

    $lines = @($Text -split "\r?\n")
    $requirements = [System.Collections.Generic.List[object]]::new()
    $currentSection = "General"

    foreach ($raw in $lines) {
        $line = ($raw -replace "\s+", " ").Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        if ($line -match '^(?i)(practical|experiment|exp)\b') {
            $currentSection = "Practical"
        } elseif ($line -match '^(?i)project\b') {
            $currentSection = "Project"
        }

        if ($line -match '^(?:\d+[\.\)]|[-*•])\s+(.+)$') {
            $body = $Matches[1].Trim()
            $requirements.Add([pscustomobject]@{
                Section = $currentSection
                Text = $body
                Type = "Task"
            })
        }
    }

    $joined = $Text
    $fileHints = [regex]::Matches($joined, '(?i)\b[\w .-]+\.(?:docx|xlsx|xls|pptx|ppt|pdf|csv|txt)\b') |
        ForEach-Object { $_.Value.Trim() } | Select-Object -Unique

    $formulas = [regex]::Matches($joined, '(?m)(?i)(?:formula|calculate|function)\s*[:\-]?\s*(.+)$') |
        ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -Unique

    [pscustomobject]@{
        Sections = @(
            [pscustomobject]@{
                Name = "Practical"
                Items = @($requirements | Where-Object Section -eq "Practical")
            },
            [pscustomobject]@{
                Name = "Project"
                Items = @($requirements | Where-Object Section -eq "Project")
            },
            [pscustomobject]@{
                Name = "General"
                Items = @($requirements | Where-Object Section -eq "General")
            }
        )
        FileHints = @($fileHints)
        FormulaHints = @($formulas)
        RawTextLength = $Text.Length
    }
}

function Save-AssignmentRequirements {
    param(
        [Parameter(Mandatory)]$Requirements,
        [Parameter(Mandatory)][string]$Path
    )
    $Requirements | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}
