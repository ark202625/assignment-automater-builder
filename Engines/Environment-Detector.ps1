# ============================================================
# Assignment Automater - Environment Detector
# ============================================================

Set-StrictMode -Version Latest

# This script is located in:
# <ProjectRoot>\Engines\Environment-Detector.ps1
#
# Therefore its parent directory is the project root.
$EngineRoot = $PSScriptRoot
$Root = Split-Path -Parent $EngineRoot

function Find-Executable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string[]]$CandidatePaths = @()
    )

    $Command = Get-Command $Name -ErrorAction SilentlyContinue

    if ($Command) {
        return $Command.Source
    }

    foreach ($Candidate in $CandidatePaths) {
        if ($Candidate -and (Test-Path -LiteralPath $Candidate -PathType Leaf)) {
            return $Candidate
        }
    }

    return $null
}

function Test-EnvironmentFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Test-Path -LiteralPath $Path -PathType Container)
}

function Get-AutomaterEnvironment {

    $DataRoot = Join-Path $Root "Assignment-Automater-Data"

    $PdfToTextCandidates = @()

    if ($env:ProgramFiles) {
        $PdfToTextCandidates += @(
            (Join-Path $env:ProgramFiles "Git\ucrt64\bin\pdftotext.exe"),
            (Join-Path $env:ProgramFiles "Git\mingw64\bin\pdftotext.exe"),
            (Join-Path $env:ProgramFiles "Git\usr\bin\pdftotext.exe")
        )
    }

    if (${env:ProgramFiles(x86)}) {
        $PdfToTextCandidates += @(
            (Join-Path ${env:ProgramFiles(x86)} "Git\ucrt64\bin\pdftotext.exe"),
            (Join-Path ${env:ProgramFiles(x86)} "Git\mingw64\bin\pdftotext.exe"),
            (Join-Path ${env:ProgramFiles(x86)} "Git\usr\bin\pdftotext.exe")
        )
    }

    $PdfToText = Find-Executable `
        -Name "pdftotext.exe" `
        -CandidatePaths $PdfToTextCandidates

    $Git = Find-Executable -Name "git.exe"

    $Python = Find-Executable -Name "python.exe"

    $PyLauncher = Find-Executable -Name "py.exe"

    $PowerShell = Find-Executable -Name "powershell.exe"

    $Pwsh = Find-Executable -Name "pwsh.exe"

    $Word = $null
    $Excel = $null
    $PowerPoint = $null

    $OfficeRoots = @()

    if ($env:ProgramFiles) {
        $OfficeRoots += Join-Path $env:ProgramFiles "Microsoft Office\root\Office16"
    }

    if (${env:ProgramFiles(x86)}) {
        $OfficeRoots += Join-Path ${env:ProgramFiles(x86)} "Microsoft Office\root\Office16"
    }

    foreach ($OfficeRoot in $OfficeRoots) {

        if (-not $Word) {
            $Candidate = Join-Path $OfficeRoot "WINWORD.EXE"

            if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
                $Word = $Candidate
            }
        }

        if (-not $Excel) {
            $Candidate = Join-Path $OfficeRoot "EXCEL.EXE"

            if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
                $Excel = $Candidate
            }
        }

        if (-not $PowerPoint) {
            $Candidate = Join-Path $OfficeRoot "POWERPNT.EXE"

            if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
                $PowerPoint = $Candidate
            }
        }
    }

    [PSCustomObject]@{

        DetectedAt = (Get-Date).ToString("o")

        System = [PSCustomObject]@{
            OS = [System.Environment]::OSVersion.VersionString
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            PowerShellEdition = $PSVersionTable.PSEdition
        }

        Paths = [PSCustomObject]@{
            ProjectRoot = $Root
            EngineRoot = $EngineRoot
            DataRoot = $DataRoot
        }

        Tools = [PSCustomObject]@{
            PowerShell = $PowerShell
            PowerShellCore = $Pwsh
            Git = $Git
            PdfToText = $PdfToText
            Python = $Python
            PythonLauncher = $PyLauncher
        }

        Office = [PSCustomObject]@{
            Word = $Word
            Excel = $Excel
            PowerPoint = $PowerPoint
        }

        Folders = [PSCustomObject]@{
            DataRoot = Test-EnvironmentFolder (Join-Path $Root "Assignment-Automater-Data")
            Input = Test-EnvironmentFolder (Join-Path $DataRoot "Assignments\Input")
            Working = Test-EnvironmentFolder (Join-Path $DataRoot "Assignments\Working")
            Output = Test-EnvironmentFolder (Join-Path $DataRoot "Assignments\Output")
            Completed = Test-EnvironmentFolder (Join-Path $DataRoot "Assignments\Completed")
            Backups = Test-EnvironmentFolder (Join-Path $DataRoot "Backups")
            Logs = Test-EnvironmentFolder (Join-Path $DataRoot "Logs")
            Reports = Test-EnvironmentFolder (Join-Path $DataRoot "Reports")
            Notes = Test-EnvironmentFolder (Join-Path $DataRoot "Notes")
        }

        Capabilities = [PSCustomObject]@{
            PdfTextExtraction = [bool]$PdfToText
            GitAvailable = [bool]$Git
            PythonAvailable = [bool]$Python
            WordAvailable = [bool]$Word
            ExcelAvailable = [bool]$Excel
            PowerPointAvailable = [bool]$PowerPoint
        }
    }
}

function Write-EnvironmentReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $Environment = Get-AutomaterEnvironment

    $Parent = Split-Path -Parent $OutputPath

    if (-not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Environment |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $OutputPath -Encoding UTF8

    return $Environment
}

if ($MyInvocation.InvocationName -ne ".") {

    $ReportPath = Join-Path `
        $Root `
        "Assignment-Automater-Data\Reports\Environment-Report.json"

    $Environment = Write-EnvironmentReport -OutputPath $ReportPath

    Write-Host ""
    Write-Host "=============================================="
    Write-Host "ASSIGNMENT AUTOMATER ENVIRONMENT"
    Write-Host "=============================================="

    Write-Host ""
    Write-Host "Project Root:"
    Write-Host "  $($Environment.Paths.ProjectRoot)"

    Write-Host ""
    Write-Host "PowerShell:"
    Write-Host "  $($Environment.System.PowerShellVersion)"

    Write-Host ""
    Write-Host "PDF Text Extraction:"

    if ($Environment.Tools.PdfToText) {
        Write-Host "  AVAILABLE"
        Write-Host "  $($Environment.Tools.PdfToText)"
    }
    else {
        Write-Host "  NOT AVAILABLE"
    }

    Write-Host ""
    Write-Host "Git:"

    if ($Environment.Tools.Git) {
        Write-Host "  AVAILABLE"
    }
    else {
        Write-Host "  NOT AVAILABLE"
    }

    Write-Host ""
    Write-Host "Python:"

    if ($Environment.Tools.Python) {
        Write-Host "  AVAILABLE"
    }
    else {
        Write-Host "  NOT AVAILABLE"
    }

    Write-Host ""
    Write-Host "Microsoft Office:"
    Write-Host "  Word      : $([bool]$Environment.Office.Word)"
    Write-Host "  Excel     : $([bool]$Environment.Office.Excel)"
    Write-Host "  PowerPoint: $([bool]$Environment.Office.PowerPoint)"

    Write-Host ""
    Write-Host "Required Project Folders:"

    Write-Host "  DataRoot  : $($Environment.Folders.DataRoot)"
    Write-Host "  Input     : $($Environment.Folders.Input)"
    Write-Host "  Working   : $($Environment.Folders.Working)"
    Write-Host "  Output    : $($Environment.Folders.Output)"
    Write-Host "  Completed : $($Environment.Folders.Completed)"
    Write-Host "  Backups   : $($Environment.Folders.Backups)"
    Write-Host "  Logs      : $($Environment.Folders.Logs)"
    Write-Host "  Reports   : $($Environment.Folders.Reports)"
    Write-Host "  Notes     : $($Environment.Folders.Notes)"

    Write-Host ""
    Write-Host "Report:"
    Write-Host "  $ReportPath"

    Write-Host ""
    Write-Host "ENVIRONMENT DETECTION COMPLETE"
    Write-Host "=============================================="
}
