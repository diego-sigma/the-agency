---
name: "{{PROJECT_NAME}}"
---

## Sources

### Slack

channels:
  - "{{SLACK_CHANNEL}}"

dms:
  - "{{TEAM_MEMBER}}"

### GitHub

repos:
  - "{{GITHUB_REPO}}"

### Jira

project_key: "{{JIRA_PROJECT_KEY}}"
# Optional: scope gather-context to specific epics (and their children).
# If set, takes precedence over the project_key-wide open-sprint query.
epics:
  # - "{{JIRA_EPIC_KEY}}"

## Team

members:
  - "{{TEAM_MEMBER}}"

## State

last_gathered:
