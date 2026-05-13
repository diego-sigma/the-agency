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
4. **Cancel this session's cron** for that project: `CronList` and `CronDelete` any job whose prompt is exactly `/gather-context <project>`.
5. **Release the scheduler lease** if owned: if `~/.claude/the-agency-sessions/<project>.scheduler` exists and `owner_session == $CLAUDE_SESSION_ID`, delete it. This frees up scheduling for other linked sessions immediately.
6. Delete the link file `~/.claude/the-agency-sessions/${CLAUDE_SESSION_ID}`.
7. Confirm: "Unlinked from <project>." Mention briefly if the lease was released so the user knows another linked session (if any) will pick up scheduling.
