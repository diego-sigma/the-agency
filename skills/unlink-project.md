---
name: unlink-project
description: Unlinks the current session from a project
---

# Unlink Project

## Trigger

User says "/unlink-project", "unlink project", or "stop working on <project>".

## Steps

1. Check if `.the-agency-sessions/${CLAUDE_SESSION_ID}` exists
2. If it does, read the project name, delete the file, and confirm: "Unlinked from <project>."
3. If it doesn't, tell the user: "No project is currently linked to this session."
