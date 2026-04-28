---
name: link-project
description: Links the current Claude Code session to a project so all tasks automatically use that project's team and context
---

# Link Project

## Trigger

User says "/link-project <project>", "link to <project>", or "work on <project>".

## Steps

### 1. Resolve the project

- Read vault path from `.the-agency-config`
- Check that `<vault>/projects/<project>/` exists
- If not, list available projects and ask the user to pick one

### 2. Write the session link

Create the `.the-agency-sessions/` directory if it doesn't exist.

Write a file `.the-agency-sessions/${CLAUDE_SESSION_ID}` with:

```
project: <project-name>
linked_at: YYYY-MM-DD HH:MM
session_id: ${CLAUDE_SESSION_ID}
```

This allows multiple sessions to be linked to the same project (or different projects) simultaneously.

### 3. Load project context

- Read `<vault>/projects/<project>/wiki.md` and `<vault>/projects/<project>/wiki/activity.md`
- Read all persona files from `<vault>/projects/<project>/team/`
- Present a brief summary to the user:
  - Project name
  - Configured sources (from config.md)
  - Activity freshness (`wiki/activity.md` "Last updated" timestamp)
  - Team members available

### 4. Gather context immediately

Run `/gather-context` for the project right away so the team starts with fresh data.

### 5. Start background context loop

Run `/loop 60m /gather-context` to keep context fresh throughout the session. This MUST run entirely in the background:

- Use `run_in_background: true` for all gather subagents
- Do NOT notify the user when a background gather starts or finishes
- Do NOT show progress, results, or summaries from background gathers
- Write outputs silently to the vault (live log, wiki updates, compaction)
- Only surface information if the user explicitly asks for it

The user should never be interrupted by a background gather.

### 5b. Install the user-activity hook (idempotent)

Background gathers skip when the user has been idle for over an hour. This requires a `UserPromptSubmit` hook in `~/.claude/settings.json` that touches `~/.claude/.last-user-activity` on every human prompt (filtering out cron-injected `/gather-context` prompts).

- Read `~/.claude/settings.json`
- If `hooks.UserPromptSubmit` already includes a hook with `~/.claude/.last-user-activity` in its command, do nothing
- Otherwise, add the following entry to `hooks.UserPromptSubmit` (creating the parent objects if needed). Preserve any existing hooks under that event:

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "p=$(jq -r '.prompt // \"\"'); echo \"$p\" | grep -qE '^/gather-context\\b' || touch ~/.claude/.last-user-activity"
    }
  ]
}
```

Do this silently — do not surface to the user unless the edit fails.

### 6. Rename the session

Tell the user to rename the session by running:

```
/rename <project-name>
```

Claude cannot rename sessions programmatically — the user must run this command themselves. Include it in the confirmation message so they can copy-paste it.

### 7. Confirm

Tell the user:
```
Linked to <project>. The team is ready:
- Steve (Staff Engineer)
- Earl (Senior Engineer)  
- Debug Bot 500 (Code Reviewer)
- Pat (Project Manager)

Context gathered. Auto-refreshing every hour.
All commands will now use this project's context automatically.
Use /unlink-project to disconnect.

Run /rename <project> to rename this session.
```
