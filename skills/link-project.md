---
name: link-project
description: Links the current Claude Code session to a project so all tasks automatically use that project's team and context
---

# Link Project

## Trigger

User says "/link-project <project>", "link to <project>", or "work on <project>".

## Steps

### 1. Resolve the project

- Read vault path from `~/.claude/the-agency-config`
- Check that `<vault>/projects/<project>/` exists
- If not, list available projects and ask the user to pick one

### 2. Write the session link

Create the `~/.claude/the-agency-sessions/` directory if it doesn't exist.

Write a file `~/.claude/the-agency-sessions/${CLAUDE_SESSION_ID}` with:

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

### 5. Start background context loop (one schedule per project, not per session)

The auto-gather schedule is **project-scoped**: only one session at a time should own the cron for a given project. Without this, two sessions linked to the same project would both fire the gather every hour and duplicate the work.

Coordinate via a lease file at `~/.claude/the-agency-sessions/<project>.scheduler` containing two lines:

```
owner_session=<session-id>
last_heartbeat=<ISO 8601 UTC>
```

**Before scheduling, check the lease:**

- If the file exists and `owner_session == $CLAUDE_SESSION_ID`, we already own it — refresh `last_heartbeat` to now and skip creating a new cron (one already exists for us).
- If the file exists, owner is a different session, and `last_heartbeat` is **within the last 24 hours**, **another live session owns the schedule** — do NOT create a cron in this session. Tell the user in step 7: "Auto-gather already scheduled by another session for this project — this session will share the data."
- If the file is missing, OR owner is another session but `last_heartbeat` is older than 24 hours (the previous owner's session probably ended), claim the lease ourselves: rewrite the file with `owner_session=$CLAUDE_SESSION_ID` and `last_heartbeat=<now>`, then create the cron below.

**Cron expression** (respects quiet hours and weekends — no gathers between 8 pm and 6 am local, or on Sat/Sun):

- `cron`: `13 6-19 * * 1-5` (hourly at :13, weekdays only, 6 am – 7 pm local)
- `prompt`: `/gather-context <project>`
- `recurring`: `true`

Use `CronCreate` directly. The /loop skill only accepts duration intervals like `60m`, not hour/day-restricted cron expressions.

The cron MUST run entirely in the background:

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

### 5c. Check MCP requirements

Compute the list of MCPs this project depends on, based on `config.md` + `knowledge/resources/`:

| Source signal in config.md or vault | Required MCP / tool |
|---|---|
| `Slack` → `channels:` non-empty OR `dms:` non-empty | claude.ai Slack |
| `Jira` → `project_key:` set OR `epics:` non-empty | claude.ai Atlassian |
| `GitHub` → `repos:` non-empty | `gh` CLI authenticated (not an MCP — verify with `gh auth status`) |
| Any file in `knowledge/resources/` has a Drive URL OR `drive_file_id` in frontmatter | claude.ai Google Drive |

For each required MCP, surface a line in the confirmation message (step 7). Do NOT attempt to programmatically connect — Claude Code routes connector auth through `/mcp`, which is interactive. Just tell the user what to verify.

If `gh auth status` exits non-zero, flag it explicitly: "GitHub repos are configured but `gh` is not authenticated — run `gh auth login`."

If a required MCP is in the surfaced list, the user should run `/mcp` and confirm each one shows as authenticated. Sources whose MCP isn't connected will silently produce empty digests during gathers.

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

Required for this project (verify with /mcp):
<emit one line per required MCP from step 5c, e.g.>
- claude.ai Slack — 3 channels, 2 DMs configured
- claude.ai Atlassian — Jira project SIG
- claude.ai Google Drive — N resources reference Drive docs
- gh CLI — N GitHub repos (run `gh auth status` to verify)

If a required MCP is not connected, that source will silently produce empty digests in context gathers — fix it with /mcp before relying on the data.

Run /rename <project> to rename this session.
```

Omit the "Required for this project" block entirely if no MCPs/tools are required (e.g. a brand-new project with no sources configured yet).
