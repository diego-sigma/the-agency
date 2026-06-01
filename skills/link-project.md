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

Run `/gather-context` for the project right away so the team starts with fresh data. The gather skill will also surface its sources and ask if anything new should be added to the project (see `/gather-context` step 7). After that, future gathers are auto-triggered on user interaction when `last_gathered` is >24 hours stale (see CLAUDE.md "Active project"). There is no recurring cron — no separate scheduler step here.

### 5. Check MCP requirements

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

Context gathered. Future gathers run automatically when you interact with this project after 24h of staleness — no recurring cron.
All commands will now use this project's context automatically.
Use /unlink-project to disconnect.

Required for this project (verify with /mcp):
<emit one line per required MCP from step 5, e.g.>
- claude.ai Slack — 3 channels, 2 DMs configured
- claude.ai Atlassian — Jira project SIG
- claude.ai Google Drive — N resources reference Drive docs
- gh CLI — N GitHub repos (run `gh auth status` to verify)

If a required MCP is not connected, that source will silently produce empty digests in context gathers — fix it with /mcp before relying on the data.

Run /rename <project> to rename this session.
```

Omit the "Required for this project" block entirely if no MCPs/tools are required (e.g. a brand-new project with no sources configured yet).
