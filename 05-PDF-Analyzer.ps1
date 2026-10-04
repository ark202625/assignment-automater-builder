# ============================================================
# ASSIGNMENT AUTOMATER
# SCRIPT 05 - PDF ANALYZER
# ============================================================

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot

$DataRoot = Join-Path `
    $Root `
    "Assignment-Automater-Data"

$EngineRoot = Join-Path `
    $Root `
    "Engines"

$PDFEnginePath = Join-Path `
    $EngineRoot `
    "PDF-Analyzer.ps1"

# ------------------------------------------------------------
# Create engine directory
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $EngineRoot)) {

    New-Item `
        -ItemType Directory `
        -Path $EngineRoot `
        -Force | Out-Null
}

# ------------------------------------------------------------
# PDF ANALYZER ENGINE
# ------------------------------------------------------------

$EngineContent = @'
# ============================================================
# PDF ANALYZER ENGINE
# ============================================================

$ErrorActionPreference = "Stop"

function Get-PdfBasicInformation {

    param(
        [Parameter(Mandatory = $true)]
        [string]$PdfPath
    )

    if (-not (Test-Path -LiteralPath $PdfPath -PathType Leaf)) {

        throw "PDF file not found: $PdfPath"
    }

    $File = Get-Item -LiteralPath $PdfPath

    if ($File.Extension.ToLowerInvariant() -ne ".pdf") {

        throw "The supplied assignment file is not a PDF."
    }

    return [ordered]@{
        FileName     = $File.Name
        FullPath     = $File.FullName
        SizeBytes    = $File.Length
        LastModified = $File.LastWriteTime.ToString(
            "yyyy-MM-dd HH:mm:ss"
        )
    }
}

function Get-PdfText {

    param(
        [Parameter(Mandatory = $true)]
        [string]$PdfPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputTextPath
    )

    # --------------------------------------------------------
    # Method 1:
    # Use Windows PowerShell/.NET where possible.
    #
    # A PDF is not guaranteed to expose readable text through
    # the basic Windows APIs, so this function first checks
    # whether pdftotext is already available.
    # --------------------------------------------------------

    $PdfToText = Get-Command `
        "pdftotext.exe" `
        -ErrorAction SilentlyContinue

    if ($null -ne $PdfToText) {

        & $PdfToText.Source `
            "-layout" `
            $PdfPath `
            $OutputTextPath

        if (Test-Path -LiteralPath $OutputTextPath) {

            $Text = Get-Content `
                -LiteralPath $OutputTextPath `
                -Raw `
                -Encoding UTF8

            if (-not [string]::IsNullOrWhiteSpace($Text)) {

                return $Text
            }
        }
    }

    # --------------------------------------------------------
    # Method 2:
    # Search for Microsoft Word installation and use Word's
    # PDF opening capability if available.
    #
    # This is only a fallback.
    # --------------------------------------------------------

    $WordCandidates = @(
        "${env:ProgramFiles}\Microsoft Office\root\Office16\WINWORD.EXE",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\WINWORD.EXE",
        "${env:ProgramFiles}\Microsoft Office\Office16\WINWORD.EXE",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\WINWORD.EXE"
    )

    $WordPath = $null

    foreach ($Candidate in $WordCandidates) {

        if ($Candidate -and (Test-Path -LiteralPath $Candidate)) {

            $WordPath = $Candidate
            break
        }
    }

    if ($null -ne $WordPath) {

        try {

            $Word = New-Object -ComObject Word.Application

            $Word.Visible = $false

            $Document = $Word.Documents.Open(
                $PdfPath,
                $false,
                $true
            )

            $Text = $Document.Content.Text

            $Document.Close($false)

            $Word.Quit()

            if (-not [string]::IsNullOrWhiteSpace($Text)) {

                Set-Content `
                    -LiteralPath $OutputTextPath `
                    -Value $Text `
                    -Encoding UTF8

                return $Text
            }
        }
        catch {

            try {
                if ($null -ne $Word) {
                    $Word.Quit()
                }
            }
            catch {
            }
        }
    }

    # --------------------------------------------------------
    # No extractor available.
    # --------------------------------------------------------

    Set-Content `
        -LiteralPath $OutputTextPath `
        -Value "" `
        -Encoding UTF8

    return $null
}

function Invoke-PdfAnalysis {

    param(
        [Parameter(Mandatory = $true)]
        [string]$PdfPath,

        [Parameter(Mandatory = $true)]
        [string]$RunDirectory,

        [Parameter(Mandatory = $true)]
        [int]$EXP
    )

    if (-not (Test-Path -LiteralPath $RunDirectory)) {

        New-Item `
            -ItemType Directory `
            -Path $RunDirectory `
            -Force | Out-Null
    }

    $TextPath = Join-Path `
        $RunDirectory `
        "Assignment-Extracted-Text.txt"

    $AnalysisPath = Join-Path `
        $RunDirectory `
        "PDF-Analysis.json"

    $Information = Get-PdfBasicInformation `
        -PdfPath $PdfPath

    $ExtractedText = Get-PdfText `
        -PdfPath $PdfPath `
        -OutputTextPath $TextPath

    $TextAvailable = (
        -not [string]::IsNullOrWhiteSpace($ExtractedText)
    )

    $Analysis = [ordered]@{

        EXP = $EXP

        PDF = $Information

        Analysis = [ordered]@{

            TextExtractionAttempted = $true

            TextExtractionSuccessful = $TextAvailable

            ExtractedTextFile = $TextPath

            ExtractionMethod = if ($TextAvailable) {
                "Available PDF text extraction method"
            }
            else {
                "No usable text extraction method available"
            }

            RequiresVisualInspection = (-not $TextAvailable)
        }

        Created = (
            Get-Date
        ).ToString("yyyy-MM-dd HH:mm:ss")
    }

    $Analysis |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -LiteralPath $AnalysisPath `
            -Encoding UTF8

    return $Analysis
}
'@

Set-Content `
    -LiteralPath $PDFEnginePath `
    -Value $EngineContent `
    -Encoding UTF8

# ------------------------------------------------------------
# VERIFY ENGINE
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $PDFEnginePath)) {

    Write-Host ""
    Write-Host "ERROR: PDF analyzer engine was not created." `
        -ForegroundColor Red
    Write-Host ""

    exit 1
}

Write-Host ""
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host " PDF ANALYZER ENGINE INSTALLED" `
    -ForegroundColor Green
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host ""

Write-Host "Engine:"
Write-Host $PDFEnginePath
Write-Host ""

Write-Host "The PDF analyzer is ready for connection to the main"
Write-Host "Assignment Automater engine."
Write-Host ""

Write-Host "IMPORTANT:"
Write-Host "Do not run the PDF analyzer directly yet."
Write-Host "The next integration script will connect it to the"
Write-Host "main startup pipeline."
Write-Host ""