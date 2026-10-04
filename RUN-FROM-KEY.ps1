# ============================================================
# ASSIGNMENT AUTOMATER - RUN FROM KEY
# ============================================================

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot

$KeyPath = Join-Path `
    $Root `
    "Assignment-Automater-Key.ps1"

if (-not (Test-Path -LiteralPath $KeyPath)) {

    Write-Host ""
    Write-Host "KEY FILE NOT FOUND" -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected:"
    Write-Host $KeyPath
    Write-Host ""

    exit 1
}

Write-Host ""
Write-Host "Loading Assignment Automater Key..." `
    -ForegroundColor Cyan

& $KeyPath
