#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$HOME/.claude/the-agency-config"
TEMPLATES_DIR="$REPO_DIR/templates"

# Check vault is initialized
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Vault not initialized. Run ./scripts/init.sh first."
  exit 1
fi

VAULT_PATH="$(grep '^vault=' "$CONFIG_FILE" | head -1 | cut -d= -f2-)"
if [ -z "$VAULT_PATH" ]; then
  echo "Error: Could not read vault path from $CONFIG_FILE. Run ./scripts/init.sh to repair."
  exit 1
fi

# Check for project name argument
if [ -z "${1:-}" ]; then
  echo "Usage: ./scripts/init-project.sh <project-name>"
  echo "Example: ./scripts/init-project.sh mcp-server"
  exit 1
fi

PROJECT_NAME="$1"
PROJECT_DIR="$VAULT_PATH/projects/$PROJECT_NAME"

# Check if project already exists
if [ -d "$PROJECT_DIR" ]; then
  echo "Error: Project '$PROJECT_NAME' already exists at $PROJECT_DIR"
  exit 1
fi

echo "=== The Agency — Project Setup: $PROJECT_NAME ==="
echo ""

# Gather source configuration
read -r -p "Slack channel(s) (comma-separated, e.g. #mcp-server,#mcp-alerts): " SLACK_CHANNELS
read -r -p "GitHub repo(s) (comma-separated, e.g. org/repo): " GITHUB_REPOS
read -r -p "Jira project key (e.g. MCP): " JIRA_KEY

# Create directory structure
mkdir -p "$PROJECT_DIR"/{team,wiki,knowledge/{live,daily,weekly,sessions,plans,resources}}

# Copy persona templates
cp "$TEMPLATES_DIR/personas/"*.md "$PROJECT_DIR/team/"

# Create config.md
cat > "$PROJECT_DIR/config.md" << EOF
---
name: "$PROJECT_NAME"
---

## Sources

### Slack

channels:
$(echo "$SLACK_CHANNELS" | tr ',' '\n' | sed 's/^ *//' | while read -r ch; do echo "  - \"$ch\""; done)

### GitHub

repos:
$(echo "$GITHUB_REPOS" | tr ',' '\n' | sed 's/^ *//' | while read -r repo; do echo "  - \"$repo\""; done)

### Jira

project_key: "$JIRA_KEY"
EOF

# Create starter wiki.md
sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TEMPLATES_DIR/project/wiki.md" > "$PROJECT_DIR/wiki.md"

echo ""
echo "Project created at: $PROJECT_DIR"
echo ""
echo "Structure:"
echo "  $PROJECT_DIR/"
echo "    config.md          — source configuration"
echo "    wiki.md            — project wiki + Recent Activity (primary agent context)"
echo "    wiki/              — wiki pages (architecture, team, decisions, etc.)"
echo "    team/              — agent personas (customize per project)"
echo "    knowledge/         — gathered context from sources"
echo ""
echo "Next steps:"
echo "  1. Review and customize the personas in $PROJECT_DIR/team/"
echo "  2. Open Claude Code and run: gather context for $PROJECT_NAME"
echo "  3. Open $VAULT_PATH in Obsidian to browse"
