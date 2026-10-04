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
