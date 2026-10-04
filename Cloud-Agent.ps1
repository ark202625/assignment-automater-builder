Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$Root=Split-Path -Parent $MyInvocation.MyCommand.Path
$Builder=Join-Path $Root ".builder"
if (!(Test-Path -LiteralPath $Builder -PathType Container)) { throw ".builder directory not found." }
$State=Get-Content (Join-Path $Builder "PROJECT-STATE.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$Queue=Get-Content (Join-Path $Builder "BUILD-QUEUE.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$Ready=@($Queue.tasks | Where-Object {$_.status -eq "READY"} | Sort-Object priority -Descending)
[ordered]@{
 controller="Assignment Automater Cloud Agent"
 timestamp=(Get-Date).ToUniversalTime().ToString("o")
 project=$State.project
 status=$State.status
 nextTask=if($Ready.Count -gt 0){$Ready[0]}else{$null}
} | ConvertTo-Json -Depth 20
