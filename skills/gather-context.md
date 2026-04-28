---
name: gather-context
description: Gathers latest context from Slack, GitHub, and Jira for a project, writes to the live log, compacts older tiers, and rewrites wiki/activity.md
---

# Gather Context

## Trigger

User says "gather context for <project>" or "update context for <project>".

## Steps

### 1. Resolve the project

- Read vault path from `.the-agency-config`
- Read `<vault>/projects/<project>/config.md`
- If the project doesn't exist, tell the user and list available projects

### 2. Check the paused flag

Read the State section of `config.md`:

- **If `gathering_paused: true` and running in the background loop** — exit immediately without notifying the user.
- **If `gathering_paused: true` and running in the foreground** (the user explicitly invoked `/gather-context`) — clear the flag (set to `false` or remove the line), then proceed with the gather. This is the resume path: invoking `/gather-context` manually doubles as "resume + run a catch-up gather." Tell the user gathering was paused and is now resumed.
- **If the flag is not set or `false`** — proceed normally.

### 2b. Check the user-activity marker (background loop only)

If running in the background loop (the cron-fired `/gather-context`), check the mtime of `~/.claude/.last-user-activity`:

- If the file does not exist OR its mtime is older than 1 hour, **exit immediately without notifying the user**. There is no point gathering when no one is around to use the result.
- Otherwise, proceed normally.

The marker file is touched by a `UserPromptSubmit` hook in `~/.claude/settings.json` whenever the user types a prompt (the hook filters out prompts that begin with `/gather-context` so cron-injected gathers never refresh it). See the "Setup" section below.

This step is skipped entirely in foreground (manual `/gather-context`) — manual invocation always proceeds.

### 3. Gather from each source (in parallel)

Read `last_gathered` from config.md's State section. Use this as the cursor for incremental fetches. If empty (first gather), do a full pull (last 3 days for Slack, last 7 days for GitHub/Jira).

Spawn one subagent per source, passing the `last_gathered` timestamp.

**Slack subagent:**
- Read the `channels` and `dms` lists from config.md
- For each channel, use `slack_read_channel` MCP tool to read messages since `last_gathered` (pass as `oldest` parameter). On first gather, use last 3 days.
- For each person in the `dms` list, use Slack MCP tools to read DM conversations since `last_gathered` — only extract messages relevant to this project (filter by project name, repo names, ticket keys, or related keywords)
- Digest into a structured summary:
  - Key discussions and their conclusions (from channels)
  - Relevant DM context (decisions, asks, updates exchanged with team members)
  - Decisions made
  - Action items mentioned
  - Open questions
  - Important announcements

**GitHub subagent:**
- Read the `repos` list from config.md
- For each repo, use `gh` CLI:
  - `gh pr list --state open` — list all open PRs
  - For each open PR:
    - `gh pr view <number>` — read the description, author, labels, review status, CI status
    - `gh pr diff <number>` — read the diff to understand what the PR changes
    - `gh pr view <number> --comments` — read review comments and discussion
  - `gh pr list --state merged --search "merged:>LAST_GATHERED_ISO"` — merged since last gather
  - `gh issue list --search "updated:>LAST_GATHERED_ISO"` — issues updated since last gather
- Digest into a structured summary:
  - **Open PRs** — for each: what it does (from description + diff), author, age, review status, CI status, key review comments or requested changes
  - Recently merged PRs (what landed and why)
  - Open issues by priority/label
  - Any PRs that are stale, blocked, or need attention

**Jira subagent:**
- Read the `project_key` and `epics:` list from config.md.
- Build a **scope clause** for the JQL queries:
  - If `epics:` is non-empty, scope to those epics and their children: `(key in (EPIC1, EPIC2, …) OR "Epic Link" in (EPIC1, EPIC2, …) OR parent in (EPIC1, EPIC2, …))`. This covers classic ("Epic Link") and next-gen ("parent") project types, and includes the epic tickets themselves so you can see epic-level status.
  - Else if `project_key` is set, scope to the whole project in open sprints: `project = <KEY> AND sprint in openSprints()`.
  - Else skip Jira entirely.
- Use Atlassian MCP tools (`searchJiraIssuesUsingJql`) with the scope clause:
  - `<SCOPE> AND updated >= "LAST_GATHERED_DATETIME"` — tickets updated since last gather
  - `<SCOPE> AND status = Blocked` — blocked items within scope (always fetch all)
- Digest into a structured summary:
  - Epics being tracked (from `epics:`) and their current status
  - Tickets by status (To Do / In Progress / In Review / Done) grouped by parent epic
  - Blocked items with blockers
  - Who's working on what

After all subagents complete, update `last_gathered` in config.md to the current ISO timestamp (e.g., `2026-04-11T14:30:00Z`).

### 4. Write to live log

Append the gathered data to `knowledge/live/YYYY-MM-DD.md` with a timestamp header:

```markdown
## HH:MM

### Slack
(digested slack data)

### GitHub
(digested github data)

### Jira
(digested jira data)
```

If the file doesn't exist yet, create it with a `# YYYY-MM-DD` heading first.

### 5. Fetch and refresh resources

**New links:** Review the gathered data from step 2 for any links (URLs in Slack messages, PR descriptions, Jira ticket comments, etc.). For each link:

- **Is it relevant to the project?** (design docs, RFCs, API docs, architecture diagrams, related articles — YES. Login pages, CI logs, dashboards, generic tool links — NO.)
- **Is it already saved?** Check `knowledge/resources/` for an existing file with the same URL in its frontmatter.
- If relevant and not already saved, use `WebFetch` to retrieve the content, convert to markdown, and save to `knowledge/resources/<slug>.md`
- If it can't be fetched (auth wall, 404), save a stub with the URL and reason
- Link to the resource from the live log entry: `See [[resources/<slug>]]`

**Existing resources:** Scan all files in `knowledge/resources/`. For each file that has a `url` property in its frontmatter:

- The URL is the **source of truth** — the local file is a cached copy
- Re-fetch the URL using `WebFetch`
- If the content has changed, update the markdown body and set `fetched` to today's date
- If the content is the same, skip (don't rewrite the file)
- If the fetch fails (auth wall, 404, timeout), leave the existing content and add a note: `<!-- refresh failed: YYYY-MM-DD — reason -->`

### 6. Compact older tiers

**Live → Daily:**
- Check `knowledge/live/` for files from previous days that don't have a matching `knowledge/daily/YYYY-MM-DD.md`
- For each, read the target day's live file AND 1-2 surrounding live files for context
- Spawn an agent to produce a daily summary capturing what mattered
- Write to `knowledge/daily/YYYY-MM-DD.md`

**Daily → Weekly:**
- Check if there's a completed calendar week (Mon-Sun) with daily summaries but no matching `knowledge/weekly/YYYY-WNN.md`
- Read that week's daily summaries
- Spawn an agent to produce a weekly summary
- Write to `knowledge/weekly/YYYY-WNN.md`

**Cleanup:**
- Delete `knowledge/live/` files older than 7 days

### 7. Update the wiki

The wiki is the primary context for agents, so it must reflect current state after every gather.

**Rewrite `wiki/activity.md` in full.** This page is always included when agents are spawned, so it MUST be current. Source material:
- Today's `knowledge/live/YYYY-MM-DD.md` — full granularity
- Last 7 `knowledge/daily/` files — recent summarized history
- Latest `knowledge/weekly/` file — broader context
- Recent `knowledge/sessions/` files — decisions and actions

Structure:

```markdown
# Recent Activity

*Last updated: YYYY-MM-DD HH:MM*

## This week
(synthesized from today's live log + recent daily summaries)

## Slack
(key discussions, decisions, action items)

## GitHub
(open PRs with status, recently merged work, notable issues)

## Jira
(sprint goal, ticket statuses, blockers)

## Notable sessions
(recent session notes worth surfacing — links to [[sessions/YYYY-MM-DD-slug]])
```

**Update the "Current focus" section in `wiki.md`** — a short summary of what the team is working on right now, based on the freshly gathered data.

**Review other wiki pages** and update any that have new information:
- New team members mentioned? → update `wiki/team.md`
- Architecture changes in PRs or discussions? → update `wiki/architecture.md`
- Key decisions made? → add to `wiki/decisions.md`
- New terms or acronyms used? → add to `wiki/glossary.md`
- Process changes discussed? → update `wiki/workflows.md`

If a topic doesn't fit existing pages, create a new wiki page and link it from `wiki.md`.

Wiki pages (other than `wiki/activity.md`) reflect **current state** — update in place, don't append history.

### 8. Report to user

**Only if running in the foreground** (i.e., the user explicitly asked to gather context). If this gather was triggered by a background loop, skip this step entirely — do not notify the user.

When reporting, tell the user what was gathered, any compaction that happened, wiki pages updated, and notable findings (e.g., "3 PRs awaiting review", "2 blocked tickets", "updated wiki/team.md with new member").

## Setup: user-activity hook (one-time)

For step 2b to work, `~/.claude/settings.json` must include a `UserPromptSubmit` hook that touches `~/.claude/.last-user-activity` on every human prompt **except** prompts that begin with `/gather-context` (so cron-injected gathers don't refresh the marker themselves). The `/link-project` skill installs this hook automatically; if it's missing, add this block under `hooks`:

```json
"hooks": {
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "p=$(jq -r '.prompt // \"\"'); echo \"$p\" | grep -qE '^/gather-context\\b' || touch ~/.claude/.last-user-activity"
        }
      ]
    }
  ]
}
```
