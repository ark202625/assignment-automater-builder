# ============================================================
# ASSIGNMENT AUTOMATER
# SCRIPT 07 - TEST PDF ANALYZER
# ============================================================

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot

$DataRoot = Join-Path `
    $Root `
    "Assignment-Automater-Data"

$InputRoot = Join-Path `
    $DataRoot `
    "Assignments\Input"

$TestRoot = Join-Path `
    $DataRoot `
    "Assignments\Working\PDF-Analyzer-Test"

$PDFEnginePath = Join-Path `
    $Root `
    "Engines\PDF-Analyzer.ps1"

# ------------------------------------------------------------
# CHECK PDF ENGINE
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $PDFEnginePath -PathType Leaf)) {

    Write-Host ""
    Write-Host "[ERROR] PDF analyzer engine not found." `
        -ForegroundColor Red
    Write-Host $PDFEnginePath
    Write-Host ""

    exit 1
}

# ------------------------------------------------------------
# FIND PDF FILES
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $InputRoot -PathType Container)) {

    New-Item `
        -ItemType Directory `
        -Path $InputRoot `
        -Force | Out-Null
}

$PDFs = @(
    Get-ChildItem `
        -LiteralPath $InputRoot `
        -Filter "*.pdf" `
        -File `
        -ErrorAction SilentlyContinue
)

# ------------------------------------------------------------
# IF NO PDF EXISTS
# ------------------------------------------------------------

if ($PDFs.Count -eq 0) {

    Write-Host ""
    Write-Host "==============================================" `
        -ForegroundColor Cyan
    Write-Host " PDF ANALYZER TEST" `
        -ForegroundColor Yellow
    Write-Host "==============================================" `
        -ForegroundColor Cyan
    Write-Host ""

    Write-Host "[INFO] No PDF was found in:"
    Write-Host $InputRoot
    Write-Host ""

    Write-Host "Place an assignment PDF in that folder and run"
    Write-Host "this script again."
    Write-Host ""

    Write-Host "Expected location:"
    Write-Host "$InputRoot\<assignment>.pdf"
    Write-Host ""

    exit 0
}

# ------------------------------------------------------------
# LOAD PDF ENGINE
# ------------------------------------------------------------

try {

    . $PDFEnginePath

}
catch {

    Write-Host ""
    Write-Host "[ERROR] Could not load PDF analyzer engine." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""

    exit 1
}

# ------------------------------------------------------------
# CREATE TEST DIRECTORY
# ------------------------------------------------------------

if (Test-Path -LiteralPath $TestRoot) {

    Remove-Item `
        -LiteralPath $TestRoot `
        -Recurse `
        -Force
}

New-Item `
    -ItemType Directory `
    -Path $TestRoot `
    -Force | Out-Null

# ------------------------------------------------------------
# TEST EACH PDF
# ------------------------------------------------------------

$Results = @()

foreach ($PDF in $PDFs) {

    Write-Host ""
    Write-Host "----------------------------------------------" `
        -ForegroundColor DarkGray

    Write-Host "Testing:"
    Write-Host $PDF.FullName
    Write-Host ""

    $SafeName = `
        [System.IO.Path]::GetFileNameWithoutExtension(
            $PDF.Name
        )

    $PDFTestDirectory = Join-Path `
        $TestRoot `
        $SafeName

    New-Item `
        -ItemType Directory `
        -Path $PDFTestDirectory `
        -Force | Out-Null

    try {

        $Analysis = Invoke-PdfAnalysis `
            -PdfPath $PDF.FullName `
            -RunDirectory $PDFTestDirectory `
            -EXP 0

        $TextFile = Join-Path `
            $PDFTestDirectory `
            "Assignment-Extracted-Text.txt"

        $AnalysisFile = Join-Path `
            $PDFTestDirectory `
            "PDF-Analysis.json"

        $TextLength = 0

        if (Test-Path -LiteralPath $TextFile -PathType Leaf) {

            $ExtractedText = Get-Content `
                -LiteralPath $TextFile `
                -Raw `
                -Encoding UTF8

            if ($null -ne $ExtractedText) {

                $TextLength = $ExtractedText.Length
            }
        }

        $TextSuccess = `
            [bool]$Analysis.Analysis.TextExtractionSuccessful

        if ($TextSuccess) {

            Write-Host "[OK] PDF analysis completed." `
                -ForegroundColor Green

            Write-Host "[OK] Text extraction succeeded." `
                -ForegroundColor Green

            Write-Host "Extracted characters: $TextLength"

        }
        else {

            Write-Host "[WARNING] PDF analysis completed, but"
            Write-Host "text extraction was not available." `
                -ForegroundColor Yellow

        }

        $Results += [pscustomobject]@{

            FileName = $PDF.Name

            FullPath = $PDF.FullName

            SizeBytes = $PDF.Length

            TextExtractionSuccessful = $TextSuccess

            ExtractedCharacters = $TextLength

            TestDirectory = $PDFTestDirectory

            AnalysisFile = $AnalysisFile

            TextFile = $TextFile
        }

    }
    catch {

        Write-Host "[FAILED] PDF analysis failed." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message

        $Results += [pscustomobject]@{

            FileName = $PDF.Name

            FullPath = $PDF.FullName

            SizeBytes = $PDF.Length

            TextExtractionSuccessful = $false

            ExtractedCharacters = 0

            TestDirectory = $PDFTestDirectory

            AnalysisFile = ""

            TextFile = ""

        }
    }
}

# ------------------------------------------------------------
# SAVE TEST REPORT
# ------------------------------------------------------------

$ReportPath = Join-Path `
    $TestRoot `
    "PDF-Analyzer-Test-Report.json"

$Results |
    ConvertTo-Json -Depth 10 |
    Set-Content `
        -LiteralPath $ReportPath `
        -Encoding UTF8

# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------

$Successful = @(
    $Results |
        Where-Object {
            $_.TextExtractionSuccessful -eq $true
        }
).Count

$Failed = @(
    $Results |
        Where-Object {
            $_.TextExtractionSuccessful -ne $true
        }
).Count

Write-Host ""
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host " PDF ANALYZER TEST COMPLETE" `
    -ForegroundColor Green
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host ""

Write-Host "PDF files tested : $($Results.Count)"
Write-Host "Text extraction  : $Successful succeeded"
Write-Host "Text unavailable : $Failed"
Write-Host ""

Write-Host "Test results:"
Write-Host $TestRoot
Write-Host ""

Write-Host "Report:"
Write-Host $ReportPath
Write-Host ""

Write-Host "SCRIPT 07 COMPLETED" `
    -ForegroundColor Green
Write-Host ""