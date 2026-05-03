#!/usr/bin/env bash
# Blitz installer — Mac / Linux
# Usage: curl -fsSL https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main/install.sh | bash

set -euo pipefail

VERSION="0.1.0"
REPO_URL="https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main"
SKILLS_DIR="${HOME}/.claude/skills"
SKILL_NAME="blitz"

# Colors — only if stdout is a terminal
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'
  YLW=$'\033[33m'; CYN=$'\033[36m'; RST=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GRN=""; YLW=""; CYN=""; RST=""
fi

ok()    { printf '  %s✔%s %s\n' "$GRN" "$RST" "$1"; }
warn()  { printf '  %s!%s %s\n' "$YLW" "$RST" "$1"; }
fail()  { printf '  %s✘%s %s\n' "$RED" "$RST" "$1" >&2; exit 1; }
step()  { printf '\n%s▸%s %s\n' "$CYN" "$RST" "$1"; }

banner() {
  cat <<'EOF'

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

EOF
  printf '  %sPre-reset backlog runner for Claude Code%s  %sv%s%s\n\n' \
    "$BOLD" "$RST" "$DIM" "$VERSION" "$RST"
}

main() {
  banner

  step "Pre-flight checks"

  command -v claude >/dev/null 2>&1 \
    || fail "claude not found in PATH. Install Claude Code first: https://claude.ai/code"
  ok "Claude Code: $(claude --version 2>/dev/null | head -n1)"

  command -v curl >/dev/null 2>&1 || fail "curl is required"
  ok "curl available"

  step "Installing skill"

  mkdir -p "$SKILLS_DIR/$SKILL_NAME"
  ok "Created $SKILLS_DIR/$SKILL_NAME"

  if ! curl -fsSL "$REPO_URL/SKILL.md" \
       -o "$SKILLS_DIR/$SKILL_NAME/SKILL.md"; then
    fail "Failed to download SKILL.md from $REPO_URL"
  fi
  ok "Downloaded SKILL.md ($(wc -c <"$SKILLS_DIR/$SKILL_NAME/SKILL.md") bytes)"

  step "Verifying installation"

  if [ ! -s "$SKILLS_DIR/$SKILL_NAME/SKILL.md" ]; then
    fail "SKILL.md is missing or empty"
  fi
  ok "SKILL.md present and non-empty"

  if ! grep -q '^name: blitz' "$SKILLS_DIR/$SKILL_NAME/SKILL.md"; then
    warn "SKILL.md may be malformed (missing frontmatter)"
  else
    ok "Frontmatter looks correct"
  fi

  step "Done"

  cat <<EOF

  ${BOLD}Blitz v${VERSION} installed.${RST}

  Next steps:
    ${CYN}1.${RST} Open (or restart) Claude Code
    ${CYN}2.${RST} Run ${BOLD}/blitz setup${RST}   ${DIM}# one-time config (3 min)${RST}
    ${CYN}3.${RST} Run ${BOLD}/blitz add <task>${RST}   ${DIM}# queue work as it comes up${RST}
    ${CYN}4.${RST} Run ${BOLD}/blitz${RST}          ${DIM}# blitz through your backlog${RST}

  Docs:    https://github.com/ADM-NKH/claude-blitz
  Issues:  https://github.com/ADM-NKH/claude-blitz/issues

EOF
}

main "$@"
