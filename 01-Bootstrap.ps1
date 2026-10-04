# ============================================================
# ASSIGNMENT AUTOMATER
# SCRIPT 01 - BOOTSTRAP
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# ROOT
# ------------------------------------------------------------

$Root = $PSScriptRoot

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " ASSIGNMENT AUTOMATER - BOOTSTRAP" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Automater root:"
Write-Host $Root
Write-Host ""

# ------------------------------------------------------------
# CORE FOLDERS
# ------------------------------------------------------------

$Folders = @(
    "Assignment-Automater-Data",
    "Assignment-Automater-Data\Assignments",
    "Assignment-Automater-Data\Assignments\Input",
    "Assignment-Automater-Data\Assignments\Working",
    "Assignment-Automater-Data\Assignments\Output",
    "Assignment-Automater-Data\Assignments\Completed",
    "Assignment-Automater-Data\Backups",
    "Assignment-Automater-Data\Logs",
    "Assignment-Automater-Data\Reports",
    "Assignment-Automater-Data\Rules",
    "Assignment-Automater-Data\Templates",
    "Assignment-Automater-Data\Notes",
    "Engines",
    "Rules",
    "Templates"
)

foreach ($RelativePath in $Folders) {

    $FullPath = Join-Path $Root $RelativePath

    if (-not (Test-Path -LiteralPath $FullPath)) {

        New-Item `
            -ItemType Directory `
            -Path $FullPath `
            -Force | Out-Null

        Write-Host "[CREATED] $RelativePath" -ForegroundColor Green

    }
    else {

        Write-Host "[EXISTS ] $RelativePath" -ForegroundColor DarkGray

    }
}

# ------------------------------------------------------------
# MASTER NOTES
# ------------------------------------------------------------

$NotesPath = Join-Path `
    $Root `
    "Assignment-Automater-Data\Notes\EXP-AutoFix-Master-Notes.txt"

if (-not (Test-Path -LiteralPath $NotesPath)) {

    @"
============================================================
ASSIGNMENT AUTOMATER - MASTER NOTES
============================================================

PURPOSE
-------

This system automates college practical/project
assignments.

It is designed to:

1. Read assignment requirements.
2. Inspect existing assignment files.
3. Build missing assignments from scratch.
4. Repair incomplete assignments.
5. Back up originals before modification.
6. Verify the final files.
7. Generate reports and logs.
8. Preserve the original files.
9. Keep all generated data inside the automater's own
   data directory.

============================================================
PORTABILITY PRINCIPLE
============================================================

The automater must NOT hardcode a user's personal paths.

The location of the automater itself is determined from
the script location.

All internal data is stored beneath:

Assignment-Automater-Data\

The user should not have to manually create folders for
backups, logs, reports, working files, outputs, templates,
rules or notes.

============================================================
KEY SYSTEM
============================================================

The user will provide a Key Script.

The Key Script contains environment/run-specific
information.

The Key Script must be able to start the next automater
process automatically.

The automater itself should not repeatedly ask the user
for locations that can be derived automatically.

============================================================
ASSIGNMENT MODES
============================================================

AUTO
----

The system determines what needs to be done.

NEW
---

Build the required assignment from scratch.

EXISTING
--------

Inspect an existing assignment and repair it if required.

============================================================
FILE TYPES
============================================================

The system is intended to support:

DOCX
XLSX
PPTX
PDF

The system should prefer reliable offline/local processing
for deterministic operations.

============================================================
SAFETY
============================================================

Original files must not be overwritten without a backup.

The system must verify files after creation or modification.

The system must never claim that an external/human action
was completed when it cannot actually verify that action.

Examples:

- Google Forms
- Microsoft Forms
- Real survey responses
- Email sending
- Live websites
- Video meetings

============================================================
WORKFLOW
============================================================

START
  |
  v
LOAD KEY
  |
  v
VALIDATE KEY
  |
  v
READ ASSIGNMENT
  |
  v
DETERMINE REQUIREMENTS
  |
  +----------------------+
  |                      |
  v                      v
NEW ASSIGNMENT       EXISTING FILE
  |                      |
  v                      v
BUILD                 INSPECT
                         |
                         v
                       REPAIR
  |                      |
  +----------+-----------+
             |
             v
          BACKUP
             |
             v
          VERIFY
             |
             v
           REPORT
             |
             v
            END

============================================================
LESSONS FROM PREVIOUS EXP WORK
============================================================

- Inspect actual files before modifying them.
- Do not assume a file is correct because it opens.
- Verify formulas, tables, charts, formatting and structure.
- XML inspection can be safer than Office COM for inspection.
- Office COM should not be the default inspection mechanism.
- Preserve correct existing work.
- Fix only what the assignment requires.
- Do not fabricate external actions.
- "Ask AI:" in an assignment means generate the required
  content unless the assignment explicitly asks for the
  prompt itself to be included.
- Practical and Project deliverables are separate.
- Required folder structures must be actual folders, not
  mockups or images.

============================================================
END OF INITIAL NOTES
============================================================
"@ | Set-Content `
        -LiteralPath $NotesPath `
        -Encoding UTF8

    Write-Host "[CREATED] Master notes" -ForegroundColor Green
}

# ------------------------------------------------------------
# SYSTEM INFORMATION
# ------------------------------------------------------------

$SystemInfoPath = Join-Path `
    $Root `
    "Assignment-Automater-Data\System.json"

$SystemInfo = @{
    Name        = "Assignment Automater"
    Version     = "1.0.0"
    Root        = $Root
    DataRoot    = Join-Path $Root "Assignment-Automater-Data"
    Created     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$SystemInfo |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        -LiteralPath $SystemInfoPath `
        -Encoding UTF8

Write-Host "[CREATED] System configuration" -ForegroundColor Green

# ------------------------------------------------------------
# FINAL VERIFICATION
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " BOOTSTRAP VERIFICATION" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

$AllRequired = $true

foreach ($RelativePath in $Folders) {

    $FullPath = Join-Path $Root $RelativePath

    if (Test-Path -LiteralPath $FullPath) {

        Write-Host "[OK] $RelativePath" -ForegroundColor Green

    }
    else {

        Write-Host "[MISSING] $RelativePath" -ForegroundColor Red
        $AllRequired = $false

    }
}

if (Test-Path -LiteralPath $NotesPath) {
    Write-Host "[OK] Master notes" -ForegroundColor Green
}
else {
    Write-Host "[MISSING] Master notes" -ForegroundColor Red
    $AllRequired = $false
}

if (Test-Path -LiteralPath $SystemInfoPath) {
    Write-Host "[OK] System configuration" -ForegroundColor Green
}
else {
    Write-Host "[MISSING] System configuration" -ForegroundColor Red
    $AllRequired = $false
}

Write-Host ""

if ($AllRequired) {

    Write-Host "==============================================" -ForegroundColor Green
    Write-Host " BOOTSTRAP COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green

}
else {

    Write-Host "==============================================" -ForegroundColor Red
    Write-Host " BOOTSTRAP FAILED VERIFICATION" -ForegroundColor Red
    Write-Host "==============================================" -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "Next step: Script 02 - Key System"
Write-Host ""