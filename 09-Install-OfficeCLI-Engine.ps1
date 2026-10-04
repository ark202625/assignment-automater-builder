$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$EnginePath = Join-Path $Root "Engines\OfficeCLI-Engine.ps1"
$ReportPath = Join-Path $Root "Assignment-Automater-Data\Reports\OfficeCLI-Report.json"

New-Item -ItemType Directory -Force -Path (Split-Path $EnginePath -Parent) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $ReportPath -Parent) | Out-Null

$Exe = Join-Path $env:LOCALAPPDATA "OfficeCLI\officecli.exe"

if (-not (Test-Path -LiteralPath $Exe)) { throw "OfficeCLI was not found: $Exe" }

$Version = (& $Exe --version 2>&1 | Out-String).Trim()

$engine = @(
'$ErrorActionPreference = "Stop"'
'function Get-OfficeCLIPath {'
'    $p = Join-Path $env:LOCALAPPDATA "OfficeCLI\officecli.exe"'
'    if (-not (Test-Path -LiteralPath $p)) { throw "OfficeCLI not found." }'
'    return $p'
'}'
'
'function Invoke-OfficeCLI {'
'    param([Parameter(Mandatory)][string[]]$Arguments)'
'    $exe = Get-OfficeCLIPath'
'    $result = & $exe @Arguments 2>&1'
'    if ($LASTEXITCODE -ne 0) { throw ($result -join [Environment]::NewLine) }'
'    return $result'
'}'
'
'function Test-OfficeDocument {'
'    param([Parameter(Mandatory)][string]$Path)'
'    return Invoke-OfficeCLI @("validate",$Path)'
'}'
'
'function Get-OfficeDocumentText {'
'    param([Parameter(Mandatory)][string]$Path)'
'    return Invoke-OfficeCLI @("view",$Path,"text")'
'}'
'
'function Get-OfficeCLIInfo {'
'    $exe = Get-OfficeCLIPath'
'    [PSCustomObject]@{ Installed=$true; Path=$exe; Version=((& $exe --version 2>&1 | Out-String).Trim()) }'
'}'
)

$engine -join [Environment]::NewLine | Set-Content -LiteralPath $EnginePath -Encoding UTF8

@{
    Installed = $true
    Path = $Exe
    Version = $Version
    Engine = $EnginePath
    Formats = @(".docx",".xlsx",".pptx")
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ReportPath -Encoding UTF8

Write-Host "[OK] OfficeCLI detected" -ForegroundColor Green
Write-Host "[OK] Engine created: $EnginePath" -ForegroundColor Green
Write-Host "[OK] Report created: $ReportPath" -ForegroundColor Green
Write-Host "[OK] Version: $Version" -ForegroundColor Green
