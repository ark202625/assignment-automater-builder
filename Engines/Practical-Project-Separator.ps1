$ErrorActionPreference = "Stop"

function Split-PracticalProjectText {
    param([Parameter(Mandatory)][string]$Text)

    $practical = [System.Collections.Generic.List[string]]::new()
    $project = [System.Collections.Generic.List[string]]::new()
    $general = [System.Collections.Generic.List[string]]::new()
    $mode = "General"

    foreach ($raw in ($Text -split "\r?\n")) {
        $line = $raw.Trim()
        if (-not $line) { continue }

        if ($line -match '^(?i)(practical|experiment|experiments|exp)\b') {
            $mode = "Practical"; continue
        }
        if ($line -match '^(?i)project\b') {
            $mode = "Project"; continue
        }

        switch ($mode) {
            "Practical" { $practical.Add($line) }
            "Project"   { $project.Add($line) }
            default     { $general.Add($line) }
        }
    }

    [pscustomobject]@{
        Practical = @($practical)
        Project   = @($project)
        General   = @($general)
    }
}

function Write-PracticalProjectFiles {
    param(
        [Parameter(Mandatory)]$Parts,
        [Parameter(Mandatory)][string]$OutputRoot
    )

    $practicalDir = Join-Path $OutputRoot "Practical"
    $projectDir   = Join-Path $OutputRoot "Project"
    New-Item -ItemType Directory -Force $practicalDir, $projectDir | Out-Null

    $Parts.Practical | Set-Content (Join-Path $practicalDir "Requirements.txt") -Encoding UTF8
    $Parts.Project   | Set-Content (Join-Path $projectDir "Requirements.txt") -Encoding UTF8

    [pscustomobject]@{ Practical=$practicalDir; Project=$projectDir }
}
