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
