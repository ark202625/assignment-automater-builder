# ============================================================
# ASSIGNMENT AUTOMATER
# SCRIPT 06 - CONNECT PDF ANALYZER
# ============================================================

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot

$MainEnginePath = Join-Path `
    $Root `
    "Assignment-Automater.ps1"

$PDFEnginePath = Join-Path `
    $Root `
    "Engines\PDF-Analyzer.ps1"

# ------------------------------------------------------------
# CHECK REQUIRED FILES
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $MainEnginePath -PathType Leaf)) {

    Write-Host ""
    Write-Host "[ERROR] Main engine not found:" -ForegroundColor Red
    Write-Host $MainEnginePath
    Write-Host ""
    exit 1
}

if (-not (Test-Path -LiteralPath $PDFEnginePath -PathType Leaf)) {

    Write-Host ""
    Write-Host "[ERROR] PDF analyzer engine not found:" -ForegroundColor Red
    Write-Host $PDFEnginePath
    Write-Host ""
    exit 1
}

# ------------------------------------------------------------
# READ MAIN ENGINE
# ------------------------------------------------------------

$MainContent = Get-Content `
    -LiteralPath $MainEnginePath `
    -Raw `
    -Encoding UTF8

# ------------------------------------------------------------
# PREVENT DUPLICATE INSTALLATION
# ------------------------------------------------------------

if ($MainContent.Contains(
    "# PDF ANALYZER INTEGRATION - SCRIPT 06"
)) {

    Write-Host ""
    Write-Host "[INFO] PDF analyzer is already connected." `
        -ForegroundColor Yellow
    Write-Host ""

    exit 0
}

# ------------------------------------------------------------
# BACKUP MAIN ENGINE BEFORE MODIFICATION
# ------------------------------------------------------------

$BackupDirectory = Join-Path `
    $Root `
    "Assignment-Automater-Data\Backups"

if (-not (Test-Path -LiteralPath $BackupDirectory)) {

    New-Item `
        -ItemType Directory `
        -Path $BackupDirectory `
        -Force | Out-Null
}

$BackupPath = Join-Path `
    $BackupDirectory `
    (
        "Assignment-Automater-before-PDF-integration-" +
        (Get-Date -Format "yyyyMMdd-HHmmss") +
        ".ps1"
    )

Copy-Item `
    -LiteralPath $MainEnginePath `
    -Destination $BackupPath `
    -Force

# ------------------------------------------------------------
# PDF ENGINE LOADING BLOCK
# ------------------------------------------------------------

$IntegrationBlock = @'

# ============================================================
# PDF ANALYZER INTEGRATION - SCRIPT 06
# ============================================================

$PDFAnalyzerPath = Join-Path `
    $Root `
    "Engines\PDF-Analyzer.ps1"

if (-not (Test-Path -LiteralPath $PDFAnalyzerPath -PathType Leaf)) {

    Stop-Automater `
        "PDF analyzer engine not found: $PDFAnalyzerPath"
}

try {

    . $PDFAnalyzerPath

}
catch {

    Stop-Automater `
        "Unable to load PDF analyzer engine. $($_.Exception.Message)"
}

'@

# ------------------------------------------------------------
# FIND A SAFE INSERTION POINT
#
# Instead of relying on the exact formatting of DataRoot,
# insert the PDF loader immediately before the first main
# function. At this point $Root and $DataRoot already exist.
# ------------------------------------------------------------

$FunctionMarker = "function Write-AutomaterLog"

$FunctionPosition = $MainContent.IndexOf(
    $FunctionMarker,
    [StringComparison]::OrdinalIgnoreCase
)

if ($FunctionPosition -lt 0) {

    Write-Host ""
    Write-Host "[ERROR] Could not find Write-AutomaterLog function." `
        -ForegroundColor Red
    Write-Host ""
    Write-Host "The main engine was NOT modified."
    Write-Host ""

    exit 1
}

$NewMainContent = `
    $MainContent.Insert(
        $FunctionPosition,
        $IntegrationBlock
    )

# ------------------------------------------------------------
# PDF ANALYSIS EXECUTION BLOCK
# ------------------------------------------------------------

$AnalysisBlock = @'

# ============================================================
# PDF ANALYSIS
# ============================================================

Write-AutomaterLog `
    "Starting PDF analysis."

try {

    $PDFAnalysis = Invoke-PdfAnalysis `
        -PdfPath $PDFPath `
        -RunDirectory $RunDirectory `
        -EXP $EXP

    $TextAvailable = `
        $PDFAnalysis.Analysis.TextExtractionSuccessful

    if ($TextAvailable) {

        Write-AutomaterLog `
            "PDF text extraction completed successfully."

        Write-Host ""
        Write-Host "[OK] PDF analysis completed." `
            -ForegroundColor Green
        Write-Host ""

    }
    else {

        Write-AutomaterLog `
            "PDF text extraction was not available."

        Write-Host ""
        Write-Host "[WARNING] PDF text extraction was not available." `
            -ForegroundColor Yellow
        Write-Host ""

        Write-Host "The assignment may require visual PDF inspection."
        Write-Host ""
    }

}
catch {

    Write-AutomaterLog `
        "PDF analysis failed: $($_.Exception.Message)"

    Stop-Automater `
        "PDF analysis failed. $($_.Exception.Message)"
}

'@

# ------------------------------------------------------------
# FIND EXISTING PDF ANALYSIS PLACEHOLDER
# ------------------------------------------------------------

$AnalysisMarkers = @(
    "PDF analysis next",
    "PDF ANALYSIS NEXT",
    "PDF analysis",
    "PDF ANALYSIS"
)

$AnalysisInserted = $false

foreach ($Marker in $AnalysisMarkers) {

    if ($NewMainContent.Contains($Marker)) {

        $MarkerPosition = $NewMainContent.IndexOf($Marker)

        # Find the beginning of the line containing the marker.
        $LineStart = $NewMainContent.LastIndexOf(
            [Environment]::NewLine,
            $MarkerPosition
        )

        if ($LineStart -lt 0) {
            $LineStart = 0
        }
        else {
            $LineStart += [Environment]::NewLine.Length
        }

        # Find the end of the marker line.
        $LineEnd = $NewMainContent.IndexOf(
            [Environment]::NewLine,
            $MarkerPosition
        )

        if ($LineEnd -lt 0) {
            $LineEnd = $NewMainContent.Length
        }

        # Replace the placeholder line.
        $NewMainContent =
            $NewMainContent.Substring(0, $LineStart) +
            $AnalysisBlock +
            $NewMainContent.Substring($LineEnd)

        $AnalysisInserted = $true

        break
    }
}

# ------------------------------------------------------------
# IF NO PLACEHOLDER WAS FOUND
# ------------------------------------------------------------

if (-not $AnalysisInserted) {

    Write-Host ""
    Write-Host "[WARNING] Existing PDF analysis placeholder was not found." `
        -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The PDF engine loader will still be installed."
    Write-Host "The analysis execution will be connected in the next"
    Write-Host "integration step."
    Write-Host ""
}

# ------------------------------------------------------------
# WRITE MODIFIED MAIN ENGINE
# ------------------------------------------------------------

Set-Content `
    -LiteralPath $MainEnginePath `
    -Value $NewMainContent `
    -Encoding UTF8

# ------------------------------------------------------------
# VERIFY MAIN ENGINE
# ------------------------------------------------------------

$VerifyContent = Get-Content `
    -LiteralPath $MainEnginePath `
    -Raw `
    -Encoding UTF8

$Checks = @(
    @{
        Name = "PDF integration marker"
        Test = $VerifyContent.Contains(
            "# PDF ANALYZER INTEGRATION - SCRIPT 06"
        )
    },
    @{
        Name = "PDF analyzer engine path"
        Test = $VerifyContent.Contains(
            "Engines\PDF-Analyzer.ps1"
        )
    },
    @{
        Name = "PDF analyzer function reference"
        Test = $VerifyContent.Contains(
            "Invoke-PdfAnalysis"
        )
    }
)

$Failed = $false

foreach ($Check in $Checks) {

    if ($Check.Test) {

        Write-Host `
            "[OK] $($Check.Name)" `
            -ForegroundColor Green
    }
    else {

        Write-Host `
            "[FAILED] $($Check.Name)" `
            -ForegroundColor Red

        $Failed = $true
    }
}

# ------------------------------------------------------------
# FAILURE HANDLING
# ------------------------------------------------------------

if ($Failed) {

    Write-Host ""
    Write-Host "[ERROR] PDF analyzer integration failed." `
        -ForegroundColor Red
    Write-Host ""

    Write-Host "Restoring original main engine..."

    Copy-Item `
        -LiteralPath $BackupPath `
        -Destination $MainEnginePath `
        -Force

    Write-Host "[OK] Original main engine restored." `
        -ForegroundColor Green
    Write-Host ""

    exit 1
}

# ------------------------------------------------------------
# SUCCESS
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host " PDF ANALYZER CONNECTED" `
    -ForegroundColor Green
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host ""

Write-Host "Main engine:"
Write-Host $MainEnginePath
Write-Host ""

Write-Host "PDF engine:"
Write-Host $PDFEnginePath
Write-Host ""

Write-Host "Backup created:"
Write-Host $BackupPath
Write-Host ""

if ($AnalysisInserted) {

    Write-Host "[OK] PDF analysis execution connected." `
        -ForegroundColor Green
}
else {

    Write-Host "[WARNING] PDF engine loaded, but analysis execution"
    Write-Host "will be connected separately."
}

Write-Host ""
Write-Host "SCRIPT 06 COMPLETED SUCCESSFULLY" `
    -ForegroundColor Green
Write-Host ""