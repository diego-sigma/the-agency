#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
CONFIG_FILE="$CLAUDE_DIR/the-agency-config"
SESSIONS_DIR="$CLAUDE_DIR/the-agency-sessions"
GLOBAL_COMMANDS_DIR="$CLAUDE_DIR/commands"
GLOBAL_CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SKILLS_DIR="$REPO_DIR/skills"
LEGACY_CONFIG="$REPO_DIR/.the-agency-config"
LEGACY_SESSIONS="$REPO_DIR/.the-agency-sessions"

mkdir -p "$CLAUDE_DIR"

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

# 2. Migrate legacy in-repo config to ~/.claude/the-agency-config (key=value)
if [ -f "$CONFIG_FILE" ] && grep -q '^vault=' "$CONFIG_FILE"; then
  # Already in new format — make sure repo= matches current REPO_DIR
  CURRENT_REPO="$(grep '^repo=' "$CONFIG_FILE" | head -1 | cut -d= -f2-)"
  if [ "$CURRENT_REPO" != "$REPO_DIR" ]; then
    VAULT_PATH="$(grep '^vault=' "$CONFIG_FILE" | head -1 | cut -d= -f2-)"
    cat > "$CONFIG_FILE" <<EOF
vault=$VAULT_PATH
repo=$REPO_DIR
EOF
    echo "Updated repo path in $CONFIG_FILE to $REPO_DIR."
  fi
elif [ -f "$LEGACY_CONFIG" ]; then
  VAULT_PATH="$(cat "$LEGACY_CONFIG")"
  cat > "$CONFIG_FILE" <<EOF
vault=$VAULT_PATH
repo=$REPO_DIR
EOF
  rm -f "$LEGACY_CONFIG"
  echo "Migrated config from $LEGACY_CONFIG → $CONFIG_FILE."
fi

# 3. Migrate legacy session links
mkdir -p "$SESSIONS_DIR"
if [ -d "$LEGACY_SESSIONS" ]; then
  MOVED=0
  for f in "$LEGACY_SESSIONS"/*; do
    [ -e "$f" ] || continue
    mv "$f" "$SESSIONS_DIR/"
    MOVED=$((MOVED + 1))
  done
  rmdir "$LEGACY_SESSIONS" 2>/dev/null || true
  if [ "$MOVED" -gt 0 ]; then
    echo "Migrated $MOVED session link(s) to $SESSIONS_DIR."
  fi
fi

# 4. Initialize vault if needed
if [ -f "$CONFIG_FILE" ]; then
  VAULT_PATH="$(grep '^vault=' "$CONFIG_FILE" | head -1 | cut -d= -f2-)"
  if [ -n "$VAULT_PATH" ] && [ -d "$VAULT_PATH/projects" ]; then
    echo "Vault already initialized at: $VAULT_PATH"
  else
    echo "Config exists but vault is missing. Re-initializing..."
    "$SCRIPT_DIR/init-vault.sh"
  fi
else
  echo ""
  "$SCRIPT_DIR/init-vault.sh"
fi

# 5. Inject the managed framework block into ~/.claude/CLAUDE.md (idempotent)
BEGIN_MARKER="<!-- BEGIN the-agency framework -->"
END_MARKER="<!-- END the-agency framework -->"
BLOCK=$(cat <<EOF
$BEGIN_MARKER
## The Agency framework

If \`~/.claude/the-agency-sessions/<your current session id>\` exists, this session is linked to an Agency project. In that case:

1. Read the project name from the link file.
2. Load and follow the framework's instructions from the \`repo=\` path in \`~/.claude/the-agency-config\` (specifically, that repo's \`CLAUDE.md\`). It defines agent personas (Steve, Earl, Debug Bot 500, Pat), task-routing rules, and vault layout.
3. Treat the framework's CLAUDE.md as authoritative for any project-scoped work, regardless of current working directory.

If no link file exists for this session, ignore this block — behave as vanilla Claude Code.
$END_MARKER
EOF
)

if [ ! -f "$GLOBAL_CLAUDE_MD" ]; then
  printf '%s\n' "$BLOCK" > "$GLOBAL_CLAUDE_MD"
  echo "Created $GLOBAL_CLAUDE_MD with the framework block."
elif grep -qF "$BEGIN_MARKER" "$GLOBAL_CLAUDE_MD"; then
  # Replace existing block in place. Use a temp file for the block so awk
  # can read it via getline (avoids passing multi-line strings via -v).
  BLOCK_FILE="$(mktemp)"
  printf '%s\n' "$BLOCK" > "$BLOCK_FILE"
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v block_file="$BLOCK_FILE" '
    index($0, begin) {
      while ((getline line < block_file) > 0) print line
      close(block_file)
      skipping = 1
      next
    }
    skipping && index($0, end) { skipping = 0; next }
    !skipping { print }
  ' "$GLOBAL_CLAUDE_MD" > "$GLOBAL_CLAUDE_MD.tmp" && mv "$GLOBAL_CLAUDE_MD.tmp" "$GLOBAL_CLAUDE_MD"
  rm -f "$BLOCK_FILE"
  echo "Refreshed framework block in $GLOBAL_CLAUDE_MD."
else
  printf '\n%s\n' "$BLOCK" >> "$GLOBAL_CLAUDE_MD"
  echo "Appended framework block to $GLOBAL_CLAUDE_MD."
fi

echo ""
echo "Setup complete. Available commands (work from any cwd):"
echo "  ./scripts/init-project.sh <name>  — create a new project"
echo "  /link-project <name>              — link this session to a project"
echo "  /gather-context                   — gather context for a project"
echo "  /team-review                      — run a team PR review"
echo "  /status                           — get a project status report"
echo "  /daily-digest                     — get a daily summary"
echo "  /explain                          — have Steve explain code"
