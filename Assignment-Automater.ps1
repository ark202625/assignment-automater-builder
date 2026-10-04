# ============================================================
# ASSIGNMENT AUTOMATER
# INTEGRATED MAIN ENGINE
# Windows PowerShell 5.1
# ============================================================

[CmdletBinding()]
param(
    [hashtable]$Key
)

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$DataRoot = Join-Path $Root "Assignment-Automater-Data"
$EngineRoot = Join-Path $Root "Engines"

function Write-AutomaterLog {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("INFO","WARN","ERROR")][string]$Level = "INFO"
    )

    $logDir = Join-Path $DataRoot "Logs"
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $logPath = Join-Path $logDir ("Automater_{0}.log" -f (Get-Date -Format "yyyyMMdd"))
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    Write-Host $line
}

function Stop-Automater {
    param([Parameter(Mandatory=$true)][string]$Message)
    Write-AutomaterLog -Level ERROR -Message $Message
    throw $Message
}

function Test-AutomaterStructure {
    $required = @(
        $DataRoot,
        (Join-Path $DataRoot "Assignments\Input"),
        (Join-Path $DataRoot "Assignments\Working"),
        (Join-Path $DataRoot "Assignments\Output"),
        (Join-Path $DataRoot "Assignments\Completed"),
        (Join-Path $DataRoot "Backups"),
        (Join-Path $DataRoot "Logs"),
        (Join-Path $DataRoot "Reports"),
        (Join-Path $DataRoot "Notes")
    )

    foreach ($path in $required) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

function Test-Key {
    param([Parameter(Mandatory=$true)][hashtable]$AssignmentKey)

    if (-not $AssignmentKey.ContainsKey("Assignment")) {
        throw "Key is missing the Assignment section."
    }

    if (-not $AssignmentKey.Assignment.ContainsKey("EXP")) {
        throw "Key is missing Assignment.EXP."
    }

    if (-not $AssignmentKey.Assignment.ContainsKey("PDF")) {
        throw "Key is missing Assignment.PDF."
    }

    $exp = [int]$AssignmentKey.Assignment.EXP
    $pdf = [string]$AssignmentKey.Assignment.PDF

    if ($exp -le 0) { throw "EXP must be greater than zero." }
    if ([string]::IsNullOrWhiteSpace($pdf)) { throw "PDF name/path cannot be empty." }
}

function Resolve-AssignmentPDF {
    param([Parameter(Mandatory=$true)][string]$PdfValue)

    $inputRoot = Join-Path $DataRoot "Assignments\Input"

    $candidates = @(
        $PdfValue,
        (Join-Path $inputRoot $PdfValue),
        (Join-Path $Root $PdfValue)
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $leaf = Split-Path -Leaf $PdfValue
    $found = Get-ChildItem -LiteralPath $inputRoot -Filter "*.pdf" -File -Recurse |
        Where-Object { $_.Name -ieq $leaf } |
        Select-Object -First 1

    if ($found) { return $found.FullName }

    throw "Assignment PDF not found: $PdfValue"
}

function New-RunInformation {
    param(
        [Parameter(Mandatory=$true)][int]$EXP,
        [Parameter(Mandatory=$true)][string]$PdfPath
    )

    $workingRoot = Join-Path $DataRoot "Assignments\Working"
    $runName = "EXP{0}_{1}" -f $EXP, (Get-Date -Format "yyyyMMdd_HHmmss")
    $runDirectory = Join-Path $workingRoot $runName
    New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null

    [PSCustomObject]@{
        EXP = $EXP
        PDF = $PdfPath
        RunDirectory = $runDirectory
        Started = Get-Date
    }
}

function Load-Engine {
    param([Parameter(Mandatory=$true)][string]$Name)

    $path = Join-Path $EngineRoot $Name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required engine not found: $path"
    }

    . $path
}

Write-AutomaterLog "Assignment Automater startup initiated."
Test-AutomaterStructure

if (-not $Key) {
    Stop-Automater "No key supplied. Use .\RUN-FROM-KEY.ps1 or call this script with -Key."
}

Test-Key -AssignmentKey $Key

$EXP = [int]$Key.Assignment.EXP
$PDFPath = Resolve-AssignmentPDF -PdfValue ([string]$Key.Assignment.PDF)
$RunInfo = New-RunInformation -EXP $EXP -PdfPath $PDFPath
$RunDirectory = $RunInfo.RunDirectory

Write-AutomaterLog "EXP: $EXP"
Write-AutomaterLog "PDF: $PDFPath"
Write-AutomaterLog "Run directory: $RunDirectory"

# ------------------------------------------------------------
# Load required engines
# ------------------------------------------------------------
$engineLoadList = @(
    "Environment-Detector.ps1",
    "PDF-Analyzer.ps1",
    "Requirement-Parser.ps1",
    "Practical-Project-Separator.ps1",
    "Assignment-Folder-Builder.ps1",
    "Existing-File-Inspector.ps1",
    "Backup-Engine.ps1",
    "OfficeCLI-Document-Inspector.ps1",
    "Verification-Engine.ps1",
    "Final-Deliverable-Checker.ps1",
    "Reporting-Engine.ps1",
    "Progress-Engine.ps1",
    "Build-Engine.ps1",
    "Repair-Engine.ps1"
)

foreach ($engineName in $engineLoadList) {
    $enginePath = Join-Path $EngineRoot $engineName
    if (-not (Test-Path -LiteralPath $enginePath -PathType Leaf)) {
        throw "Required engine not found: $enginePath"
    }
    . $enginePath
}

# ------------------------------------------------------------
# Environment
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "ENVIRONMENT" -Message "Checking local environment."

$environment = Get-AutomaterEnvironment
$environmentReportPath = Join-Path $DataRoot "Reports\Environment-Report.json"
Write-EnvironmentReport -OutputPath $environmentReportPath

# ------------------------------------------------------------
# PDF extraction
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "PDF" -Message "Extracting the complete assignment PDF."

$PDFAnalysis = Invoke-PdfAnalysis `
    -PdfPath $PDFPath `
    -OutputDirectory $RunDirectory

$analysisPath = Join-Path $RunDirectory "PDF-Analysis.json"
if (-not (Test-Path -LiteralPath $analysisPath)) {
    try {
        $PDFAnalysis | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $analysisPath -Encoding UTF8
    } catch {
        Write-AutomaterLog "Could not serialize PDF analysis object: $($_.Exception.Message)" "WARN"
    }
}

$textCandidates = @(
    (Join-Path $RunDirectory "Assignment-Extracted-Text.txt"),
    (Join-Path $RunDirectory "Extracted-Text.txt")
)

$textPath = $textCandidates | Where-Object {
    Test-Path -LiteralPath $_ -PathType Leaf
} | Select-Object -First 1

if (-not $textPath) {
    $possibleText = Get-ChildItem -LiteralPath $RunDirectory -Filter "*.txt" -File |
        Select-Object -First 1
    if ($possibleText) { $textPath = $possibleText.FullName }
}

if (-not $textPath) {
    Stop-Automater "PDF extraction completed but no extracted text file was produced."
}

$ExtractedText = Get-Content -LiteralPath $textPath -Raw -Encoding UTF8

if ([string]::IsNullOrWhiteSpace($ExtractedText)) {
    Stop-Automater "The extracted PDF text is empty."
}

Write-AutomaterLog "Extracted text length: $($ExtractedText.Length) characters."

# ------------------------------------------------------------
# Requirement analysis
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "REQUIREMENTS" -Message "Parsing assignment requirements."

$Requirements = Get-AssignmentRequirements -Text $ExtractedText
$requirementsPath = Join-Path $RunDirectory "Assignment-Requirements.json"
Save-AssignmentRequirements -Requirements $Requirements -Path $requirementsPath

# ------------------------------------------------------------
# Practical / Project separation
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "SEPARATION" -Message "Separating Practical and Project requirements."

$Parts = Split-PracticalProjectText -Text $ExtractedText

# ------------------------------------------------------------
# Output structure
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "STRUCTURE" -Message "Creating the EXP output structure."

$outputRoot = Join-Path $DataRoot "Assignments\Output"
$Structure = New-AssignmentOutputStructure -OutputRoot $outputRoot -EXP $EXP

$expRoot = $Structure.EXPRoot
$practicalRoot = $Structure.PracticalRoot
$projectRoot = $Structure.ProjectRoot

Set-Content -LiteralPath (Join-Path $practicalRoot "Requirements.txt") `
    -Value $Parts.Practical -Encoding UTF8

Set-Content -LiteralPath (Join-Path $projectRoot "Requirements.txt") `
    -Value $Parts.Project -Encoding UTF8

# Keep a complete copy as well.
Set-Content -LiteralPath (Join-Path $expRoot "Complete-Extracted-Requirements.txt") `
    -Value $ExtractedText -Encoding UTF8

# ------------------------------------------------------------
# Existing files
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "INSPECTION" -Message "Inspecting existing assignment files."

$assignmentRoot = Join-Path $DataRoot "Assignments"
$Inventory = Get-FileInventory -Root $assignmentRoot
$inventoryPath = Join-Path $RunDirectory "Existing-File-Inventory.json"
Save-FileInventory -Inventory $Inventory -Path $inventoryPath

# ------------------------------------------------------------
# Backup existing Office documents before any modification
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "BACKUP" -Message "Backing up existing deliverables before modification."

$backupRoot = Join-Path $DataRoot "Backups"
$backupResults = @()

foreach ($item in @($Inventory)) {
    $sourcePath = $null

    if ($item -is [string]) {
        $sourcePath = $item
    } elseif ($item.PSObject.Properties["FullName"]) {
        $sourcePath = [string]$item.FullName
    } elseif ($item.PSObject.Properties["Path"]) {
        $sourcePath = [string]$item.Path
    }

    if ($sourcePath -and (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        try {
            $backupResults += Backup-File -Source $sourcePath -BackupRoot $backupRoot -Label ("EXP{0}" -f $EXP)
        } catch {
            Write-AutomaterLog "Backup failed for $sourcePath : $($_.Exception.Message)" "WARN"
        }
    }
}

$backupReportPath = Join-Path $RunDirectory "Backup-Report.json"
$backupResults | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $backupReportPath -Encoding UTF8

# ------------------------------------------------------------
# OfficeCLI inspection / validation
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "OFFICE" -Message "Inspecting existing Office documents with OfficeCLI."

$officeResults = @()
$officeExtensions = @(".docx",".xlsx",".xls",".pptx",".ppt")

foreach ($item in @($Inventory)) {
    $sourcePath = $null

    if ($item.PSObject.Properties["FullName"]) {
        $sourcePath = [string]$item.FullName
    } elseif ($item.PSObject.Properties["Path"]) {
        $sourcePath = [string]$item.Path
    }

    if (-not $sourcePath) { continue }

    $extension = [IO.Path]::GetExtension($sourcePath).ToLowerInvariant()
    if ($officeExtensions -notcontains $extension) { continue }

    try {
        $inspection = Inspect-OfficeDocument -Root $Root -Path $sourcePath
        $validation = Validate-OfficeDocument -Root $Root -Path $sourcePath

        $officeResults += [PSCustomObject]@{
            Path = $sourcePath
            Inspection = $inspection
            Validation = $validation
            Status = "OK"
        }
    } catch {
        $officeResults += [PSCustomObject]@{
            Path = $sourcePath
            Status = "FAILED"
            Error = $_.Exception.Message
        }
        Write-AutomaterLog "OfficeCLI inspection failed for $sourcePath : $($_.Exception.Message)" "WARN"
    }
}

$officeReportPath = Join-Path $RunDirectory "OfficeCLI-Report.json"
$officeResults | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $officeReportPath -Encoding UTF8

# ------------------------------------------------------------
# Requirement report
# ------------------------------------------------------------
$requirementSummary = [PSCustomObject]@{
    EXP = $EXP
    PDF = $PDFPath
    ExtractedTextFile = $textPath
    ExtractedCharacterCount = $ExtractedText.Length
    RequirementsFile = $requirementsPath
    PracticalRequirements = Join-Path $practicalRoot "Requirements.txt"
    ProjectRequirements = Join-Path $projectRoot "Requirements.txt"
    ExistingInventory = $inventoryPath
    BackupReport = $backupReportPath
    OfficeCLIReport = $officeReportPath
}

$summaryPath = Join-Path $RunDirectory "Run-Summary.json"
$requirementSummary | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------
Write-AutomaterProgress -Stage "VERIFY" -Message "Verifying generated structure and extracted data."

$requiredPaths = @(
    $expRoot,
    $practicalRoot,
    $projectRoot,
    (Join-Path $practicalRoot "Requirements.txt"),
    (Join-Path $projectRoot "Requirements.txt"),
    (Join-Path $expRoot "Complete-Extracted-Requirements.txt"),
    $requirementsPath,
    $inventoryPath,
    $summaryPath
)

$verification = Test-RequiredFiles -Paths $requiredPaths
$verificationPath = Join-Path $RunDirectory "Verification.json"
$verification | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $verificationPath -Encoding UTF8

# ------------------------------------------------------------
# Final deliverable report
# ------------------------------------------------------------
$finalReport = Get-DeliverableReport -Root $expRoot
$finalReportPath = Join-Path $RunDirectory "Final-Deliverable-Report.json"
$finalReport | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $finalReportPath -Encoding UTF8

$runReport = [PSCustomObject]@{
    EXP = $EXP
    PDF = $PDFPath
    RunDirectory = $RunDirectory
    Environment = $environmentReportPath
    PDFAnalysis = $analysisPath
    ExtractedText = $textPath
    Requirements = $requirementsPath
    OutputStructure = $expRoot
    ExistingFiles = $inventoryPath
    Backups = $backupReportPath
    OfficeCLI = $officeReportPath
    Verification = $verificationPath
    FinalDeliverables = $finalReportPath
    Completed = Get-Date
}

$runReportPath = Join-Path $DataRoot "Reports\EXP{0}-Latest-Run.json" -f $EXP
$runReport | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $runReportPath -Encoding UTF8

Write-AutomaterProgress -Stage "COMPLETE" -Message "Assignment analysis and integration workflow completed."
Write-AutomaterLog "Workflow completed for EXP$EXP."
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "ASSIGNMENT AUTOMATER RUN COMPLETE" -ForegroundColor Green
Write-Host "EXP: $EXP" -ForegroundColor Green
Write-Host "Output: $expRoot" -ForegroundColor Green
Write-Host "Run report: $runReportPath" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

return $runReport

