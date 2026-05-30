---
name: pause
description: Cancels the scheduled auto-gather cron job for a project. The daily morning background gather stops firing until /gather-context is run manually, which both runs a catch-up gather and recreates the cron.
---

# Pause

## Trigger

User says "/pause", "pause context gathering", or "pause gathers for <project>".

## Steps

### 1. Resolve the project

- If an argument is provided, use it as the project name
- Otherwise, use the linked project (from `~/.claude/the-agency-sessions/<CLAUDE_SESSION_ID>`)
- If neither, list available projects and ask

### 2. Cancel the scheduled gather job

- Use `CronList` to enumerate active cron jobs in this session
- For each job whose `prompt` is exactly `/gather-context <project>` (using the project name from step 1), call `CronDelete` with the job ID
- Track how many jobs were cancelled (typically 0 or 1)

### 2b. Release the scheduler lease (if this session owns it)

If `~/.claude/the-agency-sessions/<project>.scheduler` exists and `owner_session == $CLAUDE_SESSION_ID`, delete the file. Releasing the lease lets another linked session pick up scheduling immediately instead of waiting 24 hours for the heartbeat to go stale.

If the lease is missing or owned by another session, do nothing.

### 3. Confirm

If at least one job was cancelled:

```
Auto-gathering for <project> cancelled.

The daily morning cron has been removed from this session. Run /gather-context manually whenever you want to refresh — it will run a catch-up gather AND recreate the cron, restarting the auto-loop.

To stop entirely without resuming on next /gather-context, use /unlink-project.
```

If no matching job existed:

```
No auto-gather was scheduled for <project> in this session. Nothing to cancel.
```

## Notes

- Cron jobs are **session-scoped** — they only exist within this Claude Code session. Pausing in one session does not affect a different session linked to the same project.
- This skill no longer touches `config.md`. The previous `gathering_paused` flag is no longer used.
- To stop the loop AND unbind the session, use `/unlink-project`.
