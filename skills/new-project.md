---
name: new-project
description: Creates a new project in the vault with team personas and source configuration
---

# New Project

## Trigger

User says "/new-project <name>", "create project <name>", or "new project <name>".

## Steps

### 1. Get project name

If the user didn't provide a name, ask for one.

### 2. Check vault

- Read vault path from `~/.claude/the-agency-config`
- If the vault isn't initialized, run `./scripts/init.sh` first
- Check if `<vault>/projects/<name>/` already exists — if so, tell the user and stop

### 3. Ask for sources and team

Ask the user for:
- **Slack channels** (e.g., #mcp-server, #mcp-alerts)
- **GitHub repos** (e.g., org/repo)
- **Jira project key** (e.g., MCP)
- **Team members** (e.g., @alice, @bob) — people working on this project whose Slack DMs may contain relevant context

Any of these can be left blank — not every project uses all three sources, and team members are optional.

### 4. Create directory structure

Create the following directories:
```
<vault>/projects/<name>/
  team/
  knowledge/
    live/
    daily/
    weekly/
    sessions/
    plans/
    resources/
```

### 5. Copy personas

Copy all persona files from `templates/personas/` into the project's `team/` directory.

### 6. Write config.md

Write `<vault>/projects/<name>/config.md` with the sources the user provided:

```markdown
---
name: "<project-name>"
---

## Sources

### Slack

channels:
  - "#channel-name"

dms:
  - "@alice"
  - "@bob"

### GitHub

repos:
  - "org/repo"

### Jira

project_key: "KEY"

## Team

members:
  - "@alice"
  - "@bob"
```

Omit any source section the user left blank. The `dms` list under Slack should mirror the team members list.

### 7. Write wiki.md and initial wiki pages

Create `wiki.md` at the project root and a `wiki/` directory with starter pages. `wiki/activity.md` is the volatile agent context — it is rewritten on every gather and always included when agents are spawned.

Starter `wiki.md`:

```markdown
# <Project Name> Wiki

## What is this project?
(short description — ask the user or leave placeholder)

## Key links
(from config.md — Slack channels, repos, Jira key)

## Architecture
(to be populated — see [[wiki/architecture]])

## Team
(to be populated — see [[wiki/team]])

## Current focus
(to be populated from latest gather)

## Recent decisions
(to be populated — see [[wiki/decisions]])

## Recent activity

See [[wiki/activity]] for the latest digest.

## Pages
- [[wiki/activity]]
- [[wiki/architecture]]
- [[wiki/team]]
- [[wiki/decisions]]
- [[wiki/glossary]]
- [[wiki/workflows]]
- [[wiki/preferences]]
- [[wiki/todo]]
```

Starter pages to create in `wiki/`:

- `wiki/activity.md` — placeholder saying "*Last updated: never — run `/gather-context` to populate*"
- `wiki/architecture.md` — empty, populated on first context gather
- `wiki/team.md` — populated with team members from step 3 if provided
- `wiki/decisions.md` — empty decisions log
- `wiki/glossary.md` — empty glossary
- `wiki/workflows.md` — empty workflows page
- `wiki/preferences.md` — project-specific working preferences (code style, review rules, things to avoid)
- `wiki/todo.md` — empty to-do list

### 8. Confirm and offer to link

Tell the user the project was created and what's in it. Then ask:

"Want me to link this session to <project>?"

If yes, run the link-project flow.
