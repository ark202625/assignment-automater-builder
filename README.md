# Assignment Automater

Cloud-ready source repository for the Windows PowerShell 5.1 Assignment Automater.

## Runtime assignment input

Put an assignment PDF in `Assignment-Automater-Data/Assignments/Input` or set the `ASSIGNMENT_PDF` environment variable. The runtime key derives the EXP number from a filename such as `EXP9.pdf`; no assignment is hardcoded.

## Cloud state

`.builder` contains persistent project state, build queue, test state and agent rules. `Cloud-Agent.ps1` reads that state and reports the next ready task.

## Target

Windows PowerShell 5.1 with Office/OfficeCLI support.
