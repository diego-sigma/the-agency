#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_DIR/.the-agency-config"
DEFAULT_VAULT_PATH="$REPO_DIR/vault"

echo "=== The Agency — Vault Setup ==="
echo ""

# Ask for vault path
read -r -p "Vault path [$DEFAULT_VAULT_PATH]: " VAULT_PATH
VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT_PATH}"

# Expand ~ if present
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"

# Create vault structure
mkdir -p "$VAULT_PATH/projects"

# Save vault path to config
echo "$VAULT_PATH" > "$CONFIG_FILE"

echo ""
echo "Vault created at: $VAULT_PATH"
echo "Config saved to:  $CONFIG_FILE"
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/init-project.sh <project-name> to create your first project"
echo "  2. Open $VAULT_PATH in Obsidian to browse your vault"
