#!/usr/bin/env bash
# Blitz uninstaller — Mac / Linux
# Usage: curl -fsSL https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main/uninstall.sh | bash

set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills/blitz"
CONFIG_FILE="${HOME}/.claude/blitz.json"
OUTPUT_DIR="${HOME}/blitz"

if [ -t 1 ]; then
  BOLD=$'\033[1m'; GRN=$'\033[32m'; YLW=$'\033[33m'; CYN=$'\033[36m'; RST=$'\033[0m'
else
  BOLD=""; GRN=""; YLW=""; CYN=""; RST=""
fi

ok()   { printf '  %s✔%s %s\n' "$GRN" "$RST" "$1"; }
warn() { printf '  %s!%s %s\n' "$YLW" "$RST" "$1"; }
step() { printf '\n%s▸%s %s\n' "$CYN" "$RST" "$1"; }

printf '\n  %sUninstalling Blitz%s\n' "$BOLD" "$RST"

step "Removing scheduled cron jobs (if any)"
if crontab -l 2>/dev/null | grep -q '# Blitz'; then
  crontab -l 2>/dev/null | grep -v '# Blitz' | grep -v "claude -p '/blitz auto'" | crontab -
  ok "Removed Blitz entries from crontab"
else
  ok "No Blitz cron entries found"
fi

step "Removing skill files"
if [ -d "$SKILLS_DIR" ]; then
  rm -rf "$SKILLS_DIR"
  ok "Removed $SKILLS_DIR"
else
  warn "Skill directory not found"
fi

step "Preserving your data"
if [ -f "$CONFIG_FILE" ]; then
  warn "Kept config:  $CONFIG_FILE"
fi
if [ -d "$OUTPUT_DIR" ]; then
  warn "Kept outputs: $OUTPUT_DIR"
fi

cat <<EOF

  ${BOLD}Blitz uninstalled.${RST}

  Your backlog and run history were preserved.
  To remove them too:
    rm -f $CONFIG_FILE
    rm -rf $OUTPUT_DIR

EOF
