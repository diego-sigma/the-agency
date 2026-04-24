#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_DIR/.the-agency-config"
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"
SKILLS_DIR="$REPO_DIR/skills"

echo "=== The Agency — Setup ==="
echo ""

# 1. Symlink skills as global Claude Code commands
mkdir -p "$GLOBAL_COMMANDS_DIR"
LINKED=0
SKIPPED=0
for skill in "$SKILLS_DIR"/*.md; do
  skill_name="$(basename "$skill")"
  target="$GLOBAL_COMMANDS_DIR/$skill_name"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$skill" ]; then
    SKIPPED=$((SKIPPED + 1))
  elif [ -e "$target" ]; then
    echo "  Warning: $target already exists, skipping (remove manually to re-link)"
    SKIPPED=$((SKIPPED + 1))
  else
    ln -s "$skill" "$target"
    LINKED=$((LINKED + 1))
  fi
done
if [ "$LINKED" -gt 0 ]; then
  echo "Linked $LINKED skill(s) to ~/.claude/commands/ (available globally)."
elif [ "$SKIPPED" -gt 0 ]; then
  echo "Skills already linked globally."
fi

# 2. Initialize vault if needed
if [ -f "$CONFIG_FILE" ]; then
  VAULT_PATH="$(cat "$CONFIG_FILE")"
  if [ -d "$VAULT_PATH/projects" ]; then
    echo "Vault already initialized at: $VAULT_PATH"
  else
    echo "Config exists but vault is missing. Re-initializing..."
    "$SCRIPT_DIR/init-vault.sh"
  fi
else
  echo ""
  "$SCRIPT_DIR/init-vault.sh"
fi

echo ""
echo "Setup complete. Available commands:"
echo "  ./scripts/init-project.sh <name>  — create a new project"
echo "  /gather-context                   — gather context for a project"
echo "  /team-review                      — run a team PR review"
echo "  /status                           — get a project status report"
echo "  /daily-digest                     — get a daily summary"
echo "  /explain                          — have Steve explain code"
