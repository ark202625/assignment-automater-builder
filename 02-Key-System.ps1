# ============================================================
# ASSIGNMENT AUTOMATER
# SCRIPT 02 - KEY SYSTEM
# ============================================================

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot

$DataRoot = Join-Path $Root "Assignment-Automater-Data"

# ------------------------------------------------------------
# Ensure internal folders exist
# ------------------------------------------------------------

$RequiredFolders = @(
    "Assignments\Input",
    "Assignments\Working",
    "Assignments\Output",
    "Assignments\Completed",
    "Backups",
    "Logs",
    "Reports",
    "Rules",
    "Templates",
    "Notes"
)

foreach ($Folder in $RequiredFolders) {

    $Path = Join-Path $DataRoot $Folder

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# ------------------------------------------------------------
# KEY TEMPLATE
# ------------------------------------------------------------

$TemplatePath = Join-Path $Root "KEY-TEMPLATE.ps1"

$TemplateContent = @'
# ============================================================
# ASSIGNMENT AUTOMATER - KEY
# ============================================================
#
# EDIT ONLY THE VALUES.
#
# The automater automatically creates and manages:
#
#   Assignment-Automater-Data\
#       Assignments\
#       Backups\
#       Logs\
#       Reports\
#       Rules\
#       Templates\
#       Notes\
#
# You do NOT need to specify those locations.
#
# ============================================================

$AssignmentAutomaterKey = @{

    Assignment = @{

        # ----------------------------------------------------
        # EXP NUMBER
        # ----------------------------------------------------

        EXP = 18

        # ----------------------------------------------------
        # ASSIGNMENT PDF
        # ----------------------------------------------------
        #
        # Option A:
        # Full path to PDF
        #
        # Option B:
        # Put PDF inside:
        #
        # Assignment-Automater-Data\Assignments\Input
        #
        # and provide only its filename.
        #
        # Example:
        #
        # PDF = "EXP18.pdf"
        #
        # ----------------------------------------------------

        PDF = "EXP18.pdf"
    }

    Options = @{

        # ----------------------------------------------------
        # MODE
        # ----------------------------------------------------
        #
        # AUTO     = Automater decides what is required
        # NEW      = Build assignment from scratch
        # EXISTING = Inspect/repair existing files
        #
        # ----------------------------------------------------

        Mode = "AUTO"

        # ----------------------------------------------------
        # OPERATIONS
        # ----------------------------------------------------

        BuildMissingFiles  = $true
        InspectExisting    = $true
        RepairExisting     = $true

        # ----------------------------------------------------
        # SAFETY
        # ----------------------------------------------------

        BackupBeforeModify = $true
        PreserveOriginals  = $true

        # ----------------------------------------------------
        # VERIFICATION
        # ----------------------------------------------------

        VerifyAfterBuild   = $true
    }
}

# ============================================================
# START AUTOMATER
# ============================================================

$AutomaterPath = Join-Path `
    $PSScriptRoot `
    "Assignment-Automater.ps1"

if (-not (Test-Path -LiteralPath $AutomaterPath)) {

    Write-Host ""
    Write-Host "ERROR: Main Assignment Automater has not been created yet." `
        -ForegroundColor Red

    Write-Host ""
    Write-Host "Expected:"
    Write-Host $AutomaterPath

    Write-Host ""
    Write-Host "This is normal during the initial system build."
    Write-Host "The next build script will create the main engine."
    Write-Host ""

    exit 1
}

& $AutomaterPath -Key $AssignmentAutomaterKey
'@

Set-Content `
    -LiteralPath $TemplatePath `
    -Value $TemplateContent `
    -Encoding UTF8

Write-Host "[CREATED] KEY-TEMPLATE.ps1" -ForegroundColor Green

# ------------------------------------------------------------
# CREATE DEFAULT USER KEY
# ------------------------------------------------------------

$KeyPath = Join-Path $Root "Assignment-Automater-Key.ps1"

if (-not (Test-Path -LiteralPath $KeyPath)) {

    Copy-Item `
        -LiteralPath $TemplatePath `
        -Destination $KeyPath `
        -Force

    Write-Host "[CREATED] Assignment-Automater-Key.ps1" `
        -ForegroundColor Green
}
else {

    Write-Host "[EXISTS ] Assignment-Automater-Key.ps1" `
        -ForegroundColor Yellow
}

# ------------------------------------------------------------
# CREATE KEY RUNNER
# ------------------------------------------------------------

$RunnerPath = Join-Path $Root "RUN-FROM-KEY.ps1"

$RunnerContent = @'
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
'@

Set-Content `
    -LiteralPath $RunnerPath `
    -Value $RunnerContent `
    -Encoding UTF8

Write-Host "[CREATED] RUN-FROM-KEY.ps1" -ForegroundColor Green

# ------------------------------------------------------------
# CREATE KEY README
# ------------------------------------------------------------

$ReadmePath = Join-Path $Root "KEY-README.txt"

$ReadmeContent = @'
ASSIGNMENT AUTOMATER - KEY SYSTEM
=================================

The Key Script is the only configuration normally required
from the person using the automater.

Files:

KEY-TEMPLATE.ps1
    Master template showing the correct key format.

Assignment-Automater-Key.ps1
    The actual key used for a run.

RUN-FROM-KEY.ps1
    Starts the system using the key.

IMPORTANT
=========

Do not manually create folders for:

- Backups
- Logs
- Reports
- Working files
- Output files
- Completed files
- Rules
- Templates
- Notes

The automater creates those automatically.

KEY INPUTS
==========

Normally only these values need changing:

Assignment.EXP
Assignment.PDF
Options.Mode

Everything else is controlled by the automater.

EXAMPLE
=======

$AssignmentAutomaterKey = @{

    Assignment = @{
        EXP = 18
        PDF = "EXP18.pdf"
    }

    Options = @{
        Mode = "AUTO"

        BuildMissingFiles  = $true
        InspectExisting    = $true
        RepairExisting     = $true

        BackupBeforeModify = $true
        PreserveOriginals  = $true

        VerifyAfterBuild   = $true
    }
}

The key will eventually launch the main automater
automatically.

=================================
'@

Set-Content `
    -LiteralPath $ReadmePath `
    -Value $ReadmeContent `
    -Encoding UTF8

Write-Host "[CREATED] KEY-README.txt" -ForegroundColor Green

# ------------------------------------------------------------
# VERIFICATION
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " KEY SYSTEM VERIFICATION" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

$FilesToVerify = @(
    $TemplatePath,
    $KeyPath,
    $RunnerPath,
    $ReadmePath
)

$Success = $true

foreach ($File in $FilesToVerify) {

    if (Test-Path -LiteralPath $File) {

        Write-Host "[OK] $(Split-Path $File -Leaf)" `
            -ForegroundColor Green

    }
    else {

        Write-Host "[MISSING] $File" `
            -ForegroundColor Red

        $Success = $false
    }
}

Write-Host ""

if ($Success) {

    Write-Host "==============================================" `
        -ForegroundColor Green

    Write-Host " SCRIPT 02 COMPLETED SUCCESSFULLY" `
        -ForegroundColor Green

    Write-Host "==============================================" `
        -ForegroundColor Green

}
else {

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host " SCRIPT 02 FAILED VERIFICATION" `
        -ForegroundColor Red

    Write-Host "==============================================" `
        -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "Key template is ready."
Write-Host "Main engine will be created by a later script."
Write-Host ""