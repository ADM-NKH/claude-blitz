# Blitz installer — Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$Version    = '0.1.0'
$RepoUrl    = 'https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main'
$SkillsDir  = Join-Path $env:USERPROFILE '.claude\skills'
$SkillName  = 'blitz'

function Write-Step($msg)  { Write-Host ""; Write-Host "▸ $msg" -ForegroundColor Cyan }
function Write-OK($msg)    { Write-Host "  ✔ $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Fail($msg)  { Write-Host "  ✘ $msg" -ForegroundColor Red; exit 1 }

function Show-Banner {
@'

   ▄▄▄▄    ██▓     ██▓▄▄▄█████▓▒███████▒
  ▓█████▄ ▓██▒    ▓██▒▓  ██▒ ▓▒▒ ▒ ▒ ▄▀░
  ▒██▒ ▄██▒██░    ▒██▒▒ ▓██░ ▒░░ ▒ ▄▀▒░
  ▒██░█▀  ▒██░    ░██░░ ▓██▓ ░   ▄▀▒   ░
  ░▓█  ▀█▓░██████▒░██░  ▒██▒ ░ ▒███████▒
  ░▒▓███▀▒░ ▒░▓  ░░▓    ▒ ░░   ░▒▒ ▓░▒░▒
  ▒░▒   ░ ░ ░ ▒  ░ ▒ ░    ░    ░░▒ ▒ ░ ▒
   ░    ░   ░ ░    ▒ ░  ░      ░ ░ ░ ░ ░
   ░          ░  ░ ░             ░ ░
        ░                      ░

'@ | Write-Host -ForegroundColor White

  Write-Host "  Pre-reset backlog runner for Claude Code  " -NoNewline -ForegroundColor White
  Write-Host "v$Version" -ForegroundColor DarkGray
  Write-Host ""
}

Show-Banner

# Pre-flight
Write-Step "Pre-flight checks"

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
  Write-Fail "claude not found in PATH. Install Claude Code first: https://claude.ai/code"
}
$claudeVer = & claude --version 2>$null | Select-Object -First 1
Write-OK "Claude Code: $claudeVer"

# Install
Write-Step "Installing skill"

$targetDir = Join-Path $SkillsDir $SkillName
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Write-OK "Created $targetDir"

$targetFile = Join-Path $targetDir 'SKILL.md'
try {
  Invoke-WebRequest -Uri "$RepoUrl/SKILL.md" -OutFile $targetFile -UseBasicParsing
} catch {
  Write-Fail "Failed to download SKILL.md: $($_.Exception.Message)"
}
$bytes = (Get-Item $targetFile).Length
Write-OK "Downloaded SKILL.md ($bytes bytes)"

# Verify
Write-Step "Verifying installation"

if ((Get-Item $targetFile).Length -eq 0) {
  Write-Fail "SKILL.md is empty"
}
Write-OK "SKILL.md present and non-empty"

if (-not (Select-String -Path $targetFile -Pattern '^name: blitz' -Quiet)) {
  Write-Warn2 "SKILL.md may be malformed (missing frontmatter)"
} else {
  Write-OK "Frontmatter looks correct"
}

# Done
Write-Step "Done"
Write-Host ""
Write-Host "  Blitz v$Version installed." -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:"
Write-Host "    1. Open (or restart) Claude Code"
Write-Host "    2. Run /blitz setup       # one-time config (3 min)"
Write-Host "    3. Run /blitz add <task>  # queue work as it comes up"
Write-Host "    4. Run /blitz             # blitz through your backlog"
Write-Host ""
Write-Host "  Docs:   https://github.com/ADM-NKH/claude-blitz"
Write-Host "  Issues: https://github.com/ADM-NKH/claude-blitz/issues"
Write-Host ""
