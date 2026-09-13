#!/bin/sh
# Master ~/.codex/AGENTS.md → every other CLI global rules file. Claude Code excluded (own CLAUDE.md).
# New CLI: add one sync line. Arg 2 = frontmatter to prepend.
set -e
M=~/.codex/AGENTS.md
sync() {
  mkdir -p "$(dirname "$1")"
  { [ -n "$2" ] && printf '%s\n\n' "$2"; cat "$M"; } > "$1.tmp" && mv "$1.tmp" "$1"
  echo "synced $1"
}
sync ~/.grok/rules/AGENTS.md
sync ~/.codebuddy/CODEBUDDY.md
sync ~/.cursor/rules/always.mdc '---
description: Machine-global CLI agent rules
alwaysApply: true
---'
