---
name: unlink-project
description: Unlinks the current session from a project
---

# Unlink Project

## Trigger

User says "/unlink-project", "unlink project", or "stop working on <project>".

## Steps

1. Check if `~/.claude/the-agency-sessions/${CLAUDE_SESSION_ID}` exists.
2. If it doesn't, tell the user: "No project is currently linked to this session." Then stop.
3. Read the project name from the link file.
4. Delete the link file `~/.claude/the-agency-sessions/${CLAUDE_SESSION_ID}`.
5. Confirm: "Unlinked from `<project>`. This session will no longer auto-gather or route tasks through the project's personas."

## Notes

- There is no recurring cron to cancel — gathers are triggered on user interaction by the CLAUDE.md "Active project" rule, not by a scheduled job.
- If a stale `~/.claude/the-agency-sessions/<project>.scheduler` file exists from the previous cron-based design, it's inert. The user can delete it manually if they want a clean directory.
