# ============================================================
# ASSIGNMENT AUTOMATER
# SCRIPT 03 - MAIN ENGINE / STARTUP CORE
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# ROOT
# ------------------------------------------------------------

$Root = $PSScriptRoot

$DataRoot = Join-Path $Root "Assignment-Automater-Data"

# ------------------------------------------------------------
# FUNCTION: Write Log
# ------------------------------------------------------------

function Write-AutomaterLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $LogDirectory = Join-Path $DataRoot "Logs"

    if (-not (Test-Path -LiteralPath $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }

    $LogFile = Join-Path `
        $LogDirectory `
        ("Automater_" + (Get-Date -Format "yyyyMMdd") + ".log")

    $Line = "[{0}] [{1}] {2}" -f `
        (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
        $Level,
        $Message

    Add-Content `
        -LiteralPath $LogFile `
        -Value $Line `
        -Encoding UTF8

    if ($Level -eq "ERROR") {
        Write-Host $Line -ForegroundColor Red
    }
    elseif ($Level -eq "WARNING") {
        Write-Host $Line -ForegroundColor Yellow
    }
    elseif ($Level -eq "SUCCESS") {
        Write-Host $Line -ForegroundColor Green
    }
    else {
        Write-Host $Line
    }
}

# ------------------------------------------------------------
# FUNCTION: Stop With Error
# ------------------------------------------------------------

function Stop-Automater {
    param(
        [string]$Message
    )

    Write-AutomaterLog -Message $Message -Level "ERROR"

    Write-Host ""
    Write-Host "==============================================" `
        -ForegroundColor Red
    Write-Host " AUTOMATER STOPPED" `
        -ForegroundColor Red
    Write-Host "==============================================" `
        -ForegroundColor Red
    Write-Host ""

    exit 1
}

# ------------------------------------------------------------
# FUNCTION: Test Required Structure
# ------------------------------------------------------------

function Test-AutomaterStructure {

    $RequiredFolders = @(
        "Assignment-Automater-Data",
        "Assignment-Automater-Data\Assignments",
        "Assignment-Automater-Data\Assignments\Input",
        "Assignment-Automater-Data\Assignments\Working",
        "Assignment-Automater-Data\Assignments\Output",
        "Assignment-Automater-Data\Assignments\Completed",
        "Assignment-Automater-Data\Backups",
        "Assignment-Automater-Data\Logs",
        "Assignment-Automater-Data\Reports",
        "Assignment-Automater-Data\Rules",
        "Assignment-Automater-Data\Templates",
        "Assignment-Automater-Data\Notes",
        "Engines",
        "Rules",
        "Templates"
    )

    foreach ($Folder in $RequiredFolders) {

        $Path = Join-Path $Root $Folder

        if (-not (Test-Path -LiteralPath $Path)) {

            Write-AutomaterLog `
                -Message "Missing required folder: $Folder" `
                -Level "WARNING"

            New-Item `
                -ItemType Directory `
                -Path $Path `
                -Force | Out-Null

            Write-AutomaterLog `
                -Message "Created missing folder: $Folder" `
                -Level "SUCCESS"
        }
    }
}

# ------------------------------------------------------------
# FUNCTION: VALIDATE KEY
# ------------------------------------------------------------

function Test-Key {
    param(
        [hashtable]$Key
    )

    if ($null -eq $Key) {
        Stop-Automater "No Assignment Automater Key was supplied."
    }

    if (-not $Key.ContainsKey("Assignment")) {
        Stop-Automater "Key is missing the 'Assignment' section."
    }

    if (-not $Key.ContainsKey("Options")) {
        Stop-Automater "Key is missing the 'Options' section."
    }

    $Assignment = $Key.Assignment
    $Options = $Key.Options

    if (-not $Assignment.ContainsKey("EXP")) {
        Stop-Automater "Key is missing Assignment.EXP."
    }

    $EXP = $Assignment.EXP

    if ($EXP -isnot [int] -and $EXP -isnot [long]) {

        if (-not [int]::TryParse(
            [string]$EXP,
            [ref]$ParsedEXP
        )) {
            Stop-Automater "Assignment.EXP must be a number."
        }

        $EXP = [int]$ParsedEXP
    }

    if ($EXP -lt 1) {
        Stop-Automater "Assignment.EXP must be greater than zero."
    }

    if (-not $Assignment.ContainsKey("PDF")) {
        Stop-Automater "Key is missing Assignment.PDF."
    }

    $PDF = [string]$Assignment.PDF

    if ([string]::IsNullOrWhiteSpace($PDF)) {
        Stop-Automater "Assignment.PDF cannot be empty."
    }

    if (-not $Options.ContainsKey("Mode")) {
        Stop-Automater "Key is missing Options.Mode."
    }

    $Mode = ([string]$Options.Mode).ToUpperInvariant()

    $AllowedModes = @(
        "AUTO",
        "NEW",
        "EXISTING"
    )

    if ($Mode -notin $AllowedModes) {
        Stop-Automater `
            "Invalid mode '$Mode'. Allowed modes: AUTO, NEW, EXISTING."
    }

    Write-AutomaterLog `
        -Message "Key validation successful." `
        -Level "SUCCESS"

    return $true
}

# ------------------------------------------------------------
# FUNCTION: RESOLVE PDF
# ------------------------------------------------------------

function Resolve-AssignmentPDF {
    param(
        [string]$PDFValue
    )

    # --------------------------------------------------------
    # First: treat supplied value as a full/relative path
    # --------------------------------------------------------

    if (Test-Path -LiteralPath $PDFValue -PathType Leaf) {

        return (Resolve-Path -LiteralPath $PDFValue).Path
    }

    # --------------------------------------------------------
    # Second: check the automater Input folder
    # --------------------------------------------------------

    $InputFolder = Join-Path `
        $DataRoot `
        "Assignments\Input"

    $InputCandidate = Join-Path `
        $InputFolder `
        $PDFValue

    if (Test-Path -LiteralPath $InputCandidate -PathType Leaf) {

        return (Resolve-Path -LiteralPath $InputCandidate).Path
    }

    # --------------------------------------------------------
    # Third: check relative to automater root
    # --------------------------------------------------------

    $RootCandidate = Join-Path `
        $Root `
        $PDFValue

    if (Test-Path -LiteralPath $RootCandidate -PathType Leaf) {

        return (Resolve-Path -LiteralPath $RootCandidate).Path
    }

    return $null
}

# ------------------------------------------------------------
# FUNCTION: CREATE RUN INFORMATION
# ------------------------------------------------------------

function New-RunInformation {
    param(
        [hashtable]$Key,
        [string]$PDFPath
    )

    $EXP = [int]$Key.Assignment.EXP
    $Mode = ([string]$Key.Options.Mode).ToUpperInvariant()

    $RunID = "{0}_EXP{1}_{2}" -f `
        (Get-Date -Format "yyyyMMdd_HHmmss"),
        $EXP,
        $Mode

    $RunDirectory = Join-Path `
        $DataRoot `
        ("Assignments\Working\" + $RunID)

    New-Item `
        -ItemType Directory `
        -Path $RunDirectory `
        -Force | Out-Null

    $RunInfo = [ordered]@{
        RunID       = $RunID
        EXP         = $EXP
        Mode        = $Mode
        AutomaterRoot = $Root
        DataRoot    = $DataRoot
        AssignmentPDF = $PDFPath
        Started     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    $RunInfoPath = Join-Path `
        $RunDirectory `
        "Run-Information.json"

    $RunInfo |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -LiteralPath $RunInfoPath `
            -Encoding UTF8

    return $RunInfo
}

# ============================================================
# MAIN STARTUP
# ============================================================

Write-Host ""
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host " ASSIGNMENT AUTOMATER" `
    -ForegroundColor Cyan
Write-Host " MAIN ENGINE / STARTUP CORE" `
    -ForegroundColor Cyan
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host ""

Write-AutomaterLog `
    -Message "Assignment Automater startup initiated."

Test-AutomaterStructure

# ------------------------------------------------------------
# Check whether a key was supplied
# ------------------------------------------------------------

if (-not $Key) {

    Write-AutomaterLog `
        -Message "No key supplied." `
        -Level "ERROR"

    Write-Host ""
    Write-Host "NO KEY WAS SUPPLIED." -ForegroundColor Red
    Write-Host ""
    Write-Host "Use the key system:"
    Write-Host ""
    Write-Host "    .\RUN-FROM-KEY.ps1"
    Write-Host ""
    Write-Host "or call Assignment-Automater.ps1 with a key."
    Write-Host ""

    exit 1
}

# ------------------------------------------------------------
# Validate key
# ------------------------------------------------------------

Test-Key -Key $Key | Out-Null

$EXP = [int]$Key.Assignment.EXP
$Mode = ([string]$Key.Options.Mode).ToUpperInvariant()
$PDFValue = [string]$Key.Assignment.PDF

Write-Host ""
Write-Host "KEY INFORMATION" -ForegroundColor Cyan
Write-Host "----------------"
Write-Host "EXP  : $EXP"
Write-Host "Mode : $Mode"
Write-Host "PDF  : $PDFValue"
Write-Host ""

Write-AutomaterLog `
    -Message "Key loaded. EXP=$EXP Mode=$Mode"

# ------------------------------------------------------------
# Resolve PDF
# ------------------------------------------------------------

$PDFPath = Resolve-AssignmentPDF -PDFValue $PDFValue

if ($null -eq $PDFPath) {

    Write-AutomaterLog `
        -Message "Assignment PDF could not be found: $PDFValue" `
        -Level "ERROR"

    Write-Host ""
    Write-Host "ASSIGNMENT PDF NOT FOUND" -ForegroundColor Red
    Write-Host ""
    Write-Host "The key specified:"
    Write-Host $PDFValue
    Write-Host ""
    Write-Host "The system checked:"
    Write-Host "1. Supplied path"
    Write-Host "2. Assignment-Automater-Data\Assignments\Input"
    Write-Host "3. Automater root"
    Write-Host ""

    exit 1
}

Write-AutomaterLog `
    -Message "Assignment PDF found: $PDFPath" `
    -Level "SUCCESS"

# ------------------------------------------------------------
# Create run information
# ------------------------------------------------------------

$RunInfo = New-RunInformation `
    -Key $Key `
    -PDFPath $PDFPath

# ------------------------------------------------------------
# Startup summary
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" `
    -ForegroundColor Green
Write-Host " STARTUP VALIDATION SUCCESSFUL" `
    -ForegroundColor Green
Write-Host "==============================================" `
    -ForegroundColor Green
Write-Host ""

Write-Host "EXP:"
Write-Host $RunInfo.EXP

Write-Host ""
Write-Host "MODE:"
Write-Host $RunInfo.Mode

Write-Host ""
Write-Host "PDF:"
Write-Host $RunInfo.AssignmentPDF

Write-Host ""
Write-Host "AUTOMATER ROOT:"
Write-Host $RunInfo.AutomaterRoot

Write-Host ""
Write-Host "DATA ROOT:"
Write-Host $RunInfo.DataRoot

Write-Host ""
Write-Host "RUN ID:"
Write-Host $RunInfo.RunID

Write-Host ""

Write-AutomaterLog `
    -Message "Startup validation completed successfully." `
    -Level "SUCCESS"

# ------------------------------------------------------------
# CURRENT STAGE
# ------------------------------------------------------------

Write-Host "CURRENT PIPELINE STAGE:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. KEY LOADING       [DONE]" -ForegroundColor Green
Write-Host "2. KEY VALIDATION    [DONE]" -ForegroundColor Green
Write-Host "3. PDF RESOLUTION    [DONE]" -ForegroundColor Green
Write-Host "4. RUN INITIALIZATION [DONE]" -ForegroundColor Green
Write-Host "5. PDF ANALYSIS      [NEXT]"
Write-Host "6. REQUIREMENT ENGINE [NEXT]"
Write-Host "7. BUILD/INSPECT     [NEXT]"
Write-Host "8. BACKUP            [NEXT]"
Write-Host "9. VERIFY            [NEXT]"
Write-Host ""

Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host " MAIN STARTUP CORE READY" `
    -ForegroundColor Green
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host ""

Write-AutomaterLog `
    -Message "Main startup core completed."