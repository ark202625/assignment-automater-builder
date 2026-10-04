# ============================================================
# ASSIGNMENT AUTOMATER
# SCRIPT 08 - SAFE PDF ANALYZER
# ============================================================

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot

$EngineRoot = Join-Path `
    $Root `
    "Engines"

$PDFEnginePath = Join-Path `
    $EngineRoot `
    "PDF-Analyzer.ps1"

# ------------------------------------------------------------
# CREATE ENGINE DIRECTORY
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $EngineRoot -PathType Container)) {

    New-Item `
        -ItemType Directory `
        -Path $EngineRoot `
        -Force | Out-Null
}

# ------------------------------------------------------------
# SAFE PDF ANALYZER ENGINE
# ------------------------------------------------------------

$EngineContent = @'
# ============================================================
# ASSIGNMENT AUTOMATER
# PDF ANALYZER ENGINE
# SAFE VERSION
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

function Find-PdfToText {

    $Candidates = @()

    # --------------------------------------------------------
    # PATH
    # --------------------------------------------------------

    $Command = Get-Command `
        "pdftotext.exe" `
        -ErrorAction SilentlyContinue

    if ($null -ne $Command) {

        $Candidates += $Command.Source
    }

    # --------------------------------------------------------
    # COMMON INSTALLATION LOCATIONS
    # --------------------------------------------------------

    $Candidates += @(
        "${env:ProgramFiles}\poppler\Library\bin\pdftotext.exe",
        "${env:ProgramFiles}\poppler\bin\pdftotext.exe",
        "${env:ProgramFiles(x86)}\poppler\Library\bin\pdftotext.exe",
        "${env:ProgramFiles(x86)}\poppler\bin\pdftotext.exe",
        "${env:LOCALAPPDATA}\Programs\poppler\Library\bin\pdftotext.exe",
        "${env:LOCALAPPDATA}\Programs\poppler\bin\pdftotext.exe"
    )

    foreach ($Candidate in $Candidates) {

        if (
            -not [string]::IsNullOrWhiteSpace($Candidate) -and
            (Test-Path -LiteralPath $Candidate -PathType Leaf)
        ) {

            return (Get-Item -LiteralPath $Candidate).FullName
        }
    }

    return $null
}

function Get-PdfText {

    param(
        [Parameter(Mandatory = $true)]
        [string]$PdfPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputTextPath
    )

    $PdfToText = Find-PdfToText

    # --------------------------------------------------------
    # NO EXTERNAL EXTRACTOR
    #
    # IMPORTANT:
    # We deliberately DO NOT fall back to Word COM.
    # Word COM previously caused the automation to hang.
    # --------------------------------------------------------

    if ($null -eq $PdfToText) {

        Set-Content `
            -LiteralPath $OutputTextPath `
            -Value "" `
            -Encoding UTF8

        return [ordered]@{
            Success = $false
            Method  = "No safe PDF text extractor available"
            Text    = $null
        }
    }

    # --------------------------------------------------------
    # EXTRACT USING PDFTOTEXT
    # --------------------------------------------------------

    $TempOutput = $OutputTextPath + ".tmp"

    if (Test-Path -LiteralPath $TempOutput) {

        Remove-Item `
            -LiteralPath $TempOutput `
            -Force
    }

    try {

        # Start-Process is used instead of invoking through a
        # shell so the executable and arguments remain explicit.

        $Process = Start-Process `
            -FilePath $PdfToText `
            -ArgumentList @(
                "-layout",
                "`"$PdfPath`"",
                "`"$TempOutput`""
            ) `
            -Wait `
            -PassThru `
            -WindowStyle Hidden

        if ($Process.ExitCode -ne 0) {

            Set-Content `
                -LiteralPath $OutputTextPath `
                -Value "" `
                -Encoding UTF8

            return [ordered]@{
                Success = $false
                Method  = "pdftotext failed"
                Text    = $null
            }
        }

        if (-not (Test-Path -LiteralPath $TempOutput -PathType Leaf)) {

            Set-Content `
                -LiteralPath $OutputTextPath `
                -Value "" `
                -Encoding UTF8

            return [ordered]@{
                Success = $false
                Method  = "pdftotext produced no output"
                Text    = $null
            }
        }

        $Text = Get-Content `
            -LiteralPath $TempOutput `
            -Raw `
            -Encoding UTF8

        if ([string]::IsNullOrWhiteSpace($Text)) {

            Set-Content `
                -LiteralPath $OutputTextPath `
                -Value "" `
                -Encoding UTF8

            Remove-Item `
                -LiteralPath $TempOutput `
                -Force `
                -ErrorAction SilentlyContinue

            return [ordered]@{
                Success = $false
                Method  = "pdftotext returned empty text"
                Text    = $null
            }
        }

        Set-Content `
            -LiteralPath $OutputTextPath `
            -Value $Text `
            -Encoding UTF8

        Remove-Item `
            -LiteralPath $TempOutput `
            -Force `
            -ErrorAction SilentlyContinue

        return [ordered]@{
            Success = $true
            Method  = "pdftotext"
            Text    = $Text
        }
    }
    catch {

        Remove-Item `
            -LiteralPath $TempOutput `
            -Force `
            -ErrorAction SilentlyContinue

        Set-Content `
            -LiteralPath $OutputTextPath `
            -Value "" `
            -Encoding UTF8

        return [ordered]@{
            Success = $false
            Method  = "pdftotext execution error"
            Text    = $null
        }
    }
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

    $Extraction = Get-PdfText `
        -PdfPath $PdfPath `
        -OutputTextPath $TextPath

    $TextAvailable = `
        [bool]$Extraction.Success

    $Analysis = [ordered]@{

        EXP = $EXP

        PDF = $Information

        Analysis = [ordered]@{

            TextExtractionAttempted = $true

            TextExtractionSuccessful = $TextAvailable

            ExtractionMethod = $Extraction.Method

            ExtractedTextFile = $TextPath

            RequiresVisualInspection = (-not $TextAvailable)

            WordCOMUsed = $false

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

# ------------------------------------------------------------
# BACKUP CURRENT PDF ENGINE
# ------------------------------------------------------------

$BackupDirectory = Join-Path `
    $Root `
    "Assignment-Automater-Data\Backups"

if (-not (Test-Path -LiteralPath $BackupDirectory -PathType Container)) {

    New-Item `
        -ItemType Directory `
        -Path $BackupDirectory `
        -Force | Out-Null
}

if (Test-Path -LiteralPath $PDFEnginePath -PathType Leaf) {

    $BackupPath = Join-Path `
        $BackupDirectory `
        (
            "PDF-Analyzer-before-safe-version-" +
            (Get-Date -Format "yyyyMMdd-HHmmss") +
            ".ps1"
        )

    Copy-Item `
        -LiteralPath $PDFEnginePath `
        -Destination $BackupPath `
        -Force

    Write-Host ""
    Write-Host "[BACKUP] Previous PDF analyzer saved:" `
        -ForegroundColor Yellow
    Write-Host $BackupPath
}

# ------------------------------------------------------------
# INSTALL SAFE ENGINE
# ------------------------------------------------------------

Set-Content `
    -LiteralPath $PDFEnginePath `
    -Value $EngineContent `
    -Encoding UTF8

# ------------------------------------------------------------
# VERIFY
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $PDFEnginePath -PathType Leaf)) {

    Write-Host ""
    Write-Host "[ERROR] Safe PDF analyzer was not created." `
        -ForegroundColor Red
    Write-Host ""

    exit 1
}

$VerifyContent = Get-Content `
    -LiteralPath $PDFEnginePath `
    -Raw `
    -Encoding UTF8

$Checks = @(
    @{
        Name = "Get-PdfBasicInformation"
        Test = $VerifyContent.Contains("function Get-PdfBasicInformation")
    },
    @{
        Name = "Get-PdfText"
        Test = $VerifyContent.Contains("function Get-PdfText")
    },
    @{
        Name = "Invoke-PdfAnalysis"
        Test = $VerifyContent.Contains("function Invoke-PdfAnalysis")
    },
    @{
        Name = "No Word COM automation"
        Test = (-not $VerifyContent.Contains("New-Object -ComObject Word.Application"))
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

if ($Failed) {

    Write-Host ""
    Write-Host "[ERROR] Safe PDF analyzer verification failed." `
        -ForegroundColor Red
    Write-Host ""

    exit 1
}

Write-Host ""
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host " SAFE PDF ANALYZER INSTALLED" `
    -ForegroundColor Green
Write-Host "==============================================" `
    -ForegroundColor Cyan
Write-Host ""

Write-Host "Engine:"
Write-Host $PDFEnginePath
Write-Host ""

Write-Host "[OK] Word COM fallback has been removed."
Write-Host "[OK] The analyzer will not launch Microsoft Word."
Write-Host "[OK] Existing EXP9.pdf can now be used for testing."
Write-Host ""

Write-Host "SCRIPT 08 COMPLETED SUCCESSFULLY" `
    -ForegroundColor Green
Write-Host ""
