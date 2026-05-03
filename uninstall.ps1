# Blitz uninstaller — Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main/uninstall.ps1 | iex

$ErrorActionPreference = 'Continue'

$SkillsDir  = Join-Path $env:USERPROFILE '.claude\skills\blitz'
$ConfigFile = Join-Path $env:USERPROFILE '.claude\blitz.json'
$RunnerPS   = Join-Path $env:USERPROFILE '.claude\blitz-runner.ps1'
$OutputDir  = Join-Path $env:USERPROFILE 'blitz'

function Write-Step($msg)  { Write-Host ""; Write-Host "▸ $msg" -ForegroundColor Cyan }
function Write-OK($msg)    { Write-Host "  ✔ $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "  ! $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  Uninstalling Blitz" -ForegroundColor White

Write-Step "Removing scheduled tasks"
foreach ($name in @('Blitz-Weekly', 'Blitz-Session')) {
  $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
  if ($task) {
    Unregister-ScheduledTask -TaskName $name -Confirm:$false
    Write-OK "Removed scheduled task: $name"
  } else {
    Write-OK "No task found: $name"
  }
}

Write-Step "Removing skill files"
if (Test-Path $SkillsDir) {
  Remove-Item -Recurse -Force $SkillsDir
  Write-OK "Removed $SkillsDir"
} else {
  Write-Warn2 "Skill directory not found"
}

if (Test-Path $RunnerPS) {
  Remove-Item -Force $RunnerPS
  Write-OK "Removed runner script"
}

Write-Step "Preserving your data"
if (Test-Path $ConfigFile) { Write-Warn2 "Kept config:  $ConfigFile" }
if (Test-Path $OutputDir)  { Write-Warn2 "Kept outputs: $OutputDir" }

Write-Host ""
Write-Host "  Blitz uninstalled." -ForegroundColor White
Write-Host ""
Write-Host "  Your backlog and run history were preserved."
Write-Host "  To remove them too:"
Write-Host "    Remove-Item '$ConfigFile'"
Write-Host "    Remove-Item -Recurse '$OutputDir'"
Write-Host ""
