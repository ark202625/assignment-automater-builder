# Assignment Automater Cloud Architecture

GitHub is the source of truth for source code, rules, engines and persistent builder state.

Assignment PDFs are runtime/test inputs supplied through Assignment-Automater-Data/Assignments/Input or ASSIGNMENT_PDF.

A cloud controller reads .builder state and the build queue. A Windows runner executes PowerShell 5.1 and Office tooling. The AI controller diagnoses failures and prepares changes. Successful changes are tested before completion.

Assignment identity is discovered from runtime input rather than hardcoded.
