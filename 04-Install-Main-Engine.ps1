# ============================================================
# ASSIGNMENT AUTOMATER
# SCRIPT 04 - INSTALL MAIN ENTRY POINT
# ============================================================

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot

$Source = Join-Path $Root "03-Main-Engine.ps1"
$Destination = Join-Path $Root "Assignment-Automater.ps1"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " INSTALLING MAIN AUTOMATER ENTRY POINT" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $Source)) {

    Write-Host "ERROR: 03-Main-Engine.ps1 was not found." -ForegroundColor Red
    exit 1
}

Copy-Item `
    -LiteralPath $Source `
    -Destination $Destination `
    -Force

if (-not (Test-Path -LiteralPath $Destination)) {

    Write-Host "ERROR: Main entry point was not created." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Assignment-Automater.ps1 created." -ForegroundColor Green
Write-Host ""

Write-Host "Main entry point:"
Write-Host $Destination
Write-Host ""

Write-Host "The automater can now be started through the Key System."
Write-Host ""

Write-Host "==============================================" -ForegroundColor Green
Write-Host " SCRIPT 04 COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""