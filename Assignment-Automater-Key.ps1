# Assignment Automater runtime key
$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$InputRoot = Join-Path $Root "Assignment-Automater-Data\Assignments\Input"
$pdfOverride = [Environment]::GetEnvironmentVariable("ASSIGNMENT_PDF")
if ([string]::IsNullOrWhiteSpace($pdfOverride)) {
    $pdf = Get-ChildItem -LiteralPath $InputRoot -Filter "*.pdf" -File | Sort-Object Name | Select-Object -First 1
    if (-not $pdf) { throw "No assignment PDF was supplied. Put a PDF in the input directory or set ASSIGNMENT_PDF." }
    $pdfPath = $pdf.FullName
} else {
    $pdfPath = (Resolve-Path -LiteralPath $pdfOverride -ErrorAction Stop).Path
}
$match = [regex]::Match([IO.Path]::GetFileNameWithoutExtension($pdfPath),'(?i)\bEXP\s*[-_ ]?(\d+)\b')
if (-not $match.Success) { throw "Could not derive EXP number from PDF filename '$([IO.Path]::GetFileName($pdfPath))'." }
$exp = [int]$match.Groups[1].Value
$AssignmentAutomaterKey = @{
    Assignment = @{ EXP = $exp; PDF = $pdfPath }
    Options = @{
        Mode="AUTO"; BuildMissingFiles=$true; InspectExisting=$true; RepairExisting=$true
        BackupBeforeModify=$true; PreserveOriginals=$true; VerifyAfterBuild=$true
    }
}
$AutomaterPath=Join-Path $Root "Assignment-Automater.ps1"
if (!(Test-Path -LiteralPath $AutomaterPath -PathType Leaf)) { throw "Main Assignment Automater was not found: $AutomaterPath" }
& $AutomaterPath -Key $AssignmentAutomaterKey
