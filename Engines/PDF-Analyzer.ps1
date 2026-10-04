function Get-PdfBasicInformation {
    param([Parameter(Mandatory=$true)][string]$PdfPath)

    if (-not (Test-Path -LiteralPath $PdfPath)) {
        throw "PDF file not found: $PdfPath"
    }

    $Item = Get-Item -LiteralPath $PdfPath

    [ordered]@{
        FullPath      = $Item.FullName
        FileName      = $Item.Name
        Extension     = $Item.Extension
        Length        = $Item.Length
        LastWriteTime = $Item.LastWriteTime
    }
}

function Find-PdfToText {
    $Command = Get-Command "pdftotext.exe" -ErrorAction SilentlyContinue

    if ($Command) {
        return $Command.Source
    }

    $Candidates = @(
        "C:\Program Files\Git\ucrt64\bin\pdftotext.exe",
        "C:\Program Files\Git\mingw64\bin\pdftotext.exe",
        "C:\Program Files\Git\usr\bin\pdftotext.exe",
        "$env:LOCALAPPDATA\Programs\Git\ucrt64\bin\pdftotext.exe",
        "$env:LOCALAPPDATA\Programs\Git\mingw64\bin\pdftotext.exe",
        "$env:LOCALAPPDATA\Programs\Git\usr\bin\pdftotext.exe"
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate) {
            return $Candidate
        }
    }

    return $null
}

function Get-PdfText {
    param([Parameter(Mandatory=$true)][string]$PdfPath)

    if (-not (Test-Path -LiteralPath $PdfPath)) {
        throw "PDF file not found: $PdfPath"
    }

    $PdfToTextPath = Find-PdfToText

    if (-not $PdfToTextPath) {
        return [ordered]@{
            Success     = $false
            Extractor   = "None"
            WordCOMUsed = $false
            Text        = ""
            Message     = "pdftotext.exe was not found."
        }
    }

    $TempText = [System.IO.Path]::Combine(
        [System.IO.Path]::GetTempPath(),
        ([System.Guid]::NewGuid().ToString() + ".txt")
    )

    try {
        $Process = Start-Process `
            -FilePath $PdfToTextPath `
            -ArgumentList @(
                "-layout",
                $PdfPath,
                $TempText
            ) `
            -Wait `
            -PassThru `
            -NoNewWindow

        if ($Process.ExitCode -ne 0) {
            return [ordered]@{
                Success     = $false
                Extractor   = "pdftotext"
                WordCOMUsed = $false
                Text        = ""
                Message     = "pdftotext.exe failed with exit code $($Process.ExitCode)."
            }
        }

        $Text = ""

        if (Test-Path -LiteralPath $TempText) {
            $Text = Get-Content -LiteralPath $TempText -Raw -ErrorAction SilentlyContinue
        }

        return [ordered]@{
            Success     = $true
            Extractor   = "pdftotext"
            ExtractorPath = $PdfToTextPath
            WordCOMUsed = $false
            Text        = $Text
            Message     = "PDF text extraction completed."
        }
    }
    finally {
        if (Test-Path -LiteralPath $TempText) {
            Remove-Item -LiteralPath $TempText -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-PdfAnalysis {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PdfPath,

        [string]$OutputDirectory
    )

    if (-not (Test-Path -LiteralPath $PdfPath)) {
        throw "PDF file not found: $PdfPath"
    }

    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        $OutputDirectory = Split-Path -Parent $PdfPath
    }

    if (-not (Test-Path -LiteralPath $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }

    $Basic = Get-PdfBasicInformation -PdfPath $PdfPath
    $TextResult = Get-PdfText -PdfPath $PdfPath

    $ExtractedTextPath = Join-Path $OutputDirectory "Assignment-Extracted-Text.txt"
    $AnalysisJsonPath = Join-Path $OutputDirectory "PDF-Analysis.json"

    $TextResult.Text |
        Set-Content -LiteralPath $ExtractedTextPath -Encoding UTF8

    $Analysis = [ordered]@{
        BasicInformation = $Basic
        Extraction       = $TextResult
        WordCOMUsed      = $false
        AnalysisStatus   = if ($TextResult.Success) {
            "Text extracted"
        }
        else {
            "Text extraction unavailable"
        }
    }

    $Analysis |
        ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $AnalysisJsonPath -Encoding UTF8

    return $Analysis
}
