---
name: gather-context
description: Pulls fresh data from a project's configured sources (Slack, GitHub, Jira, Drive resources), writes to the live log, compacts older tiers, rewrites wiki/activity.md, and prompts the user to add any new sources. Auto-triggered when a linked session is active and last_gathered is >24h stale; otherwise invoked manually.
---

# Gather Context

## Trigger

- User says "gather context for <project>" or "update context for <project>".
- Auto-triggered from the framework's CLAUDE.md "Active project" rule when a linked session has `last_gathered` older than 24 hours (see CLAUDE.md). Auto and manual flows are identical.

## Steps

### 1. Resolve the project

- Read vault path from the `vault=` line of `~/.claude/the-agency-config`.
- Read `<vault>/projects/<project>/config.md`.
- If the project doesn't exist, tell the user and list available projects.

### 2. Gather from each source (in parallel)

Read `last_gathered` from `config.md`'s State section. Use this as the cursor for incremental fetches. If empty (first gather), do a full pull (last 3 days for Slack, last 7 days for GitHub/Jira).

Spawn one subagent per **configured** source (skip sources that are empty in `config.md` — no point spawning a Slack subagent if `channels:` and `dms:` are both empty).

**Slack subagent:**
- Read the `channels` and `dms` lists from config.md.
- For each channel, use `slack_read_channel` MCP tool to read messages since `last_gathered` (pass as `oldest`). On first gather, use last 3 days.
- For each person in `dms`, use Slack MCP tools to read DM conversations since `last_gathered` — only extract messages relevant to this project (filter by project name, repo names, ticket keys, related keywords).
- Digest into a structured summary: key discussions + decisions, relevant DM context, action items, open questions, important announcements.

**GitHub subagent:**
- Read the `repos` list from config.md.
- For each repo, use `gh` CLI:
  - `gh pr list --state open` — list all open PRs
  - For each open PR: `gh pr view <num>` (description, author, labels, review status, CI), `gh pr diff <num>`, `gh pr view <num> --comments`
  - `gh pr list --state merged --search "merged:>LAST_GATHERED_ISO"`
  - `gh issue list --search "updated:>LAST_GATHERED_ISO"`
- Digest: open PRs (what each does + review status + key comments), recently merged, open issues by priority/label, stale/blocked PRs.

**Jira subagent:**
- Read `project_key` and `epics:` from config.md.
- Build scope clause:
  - If `epics:` non-empty: `(key in (E1, E2, …) OR "Epic Link" in (E1, …) OR parent in (E1, …))`
  - Else if `project_key` set: `project = <KEY> AND sprint in openSprints()`
  - Else skip Jira entirely.
- `searchJiraIssuesUsingJql` with `<SCOPE> AND updated >= "LAST_GATHERED_DATETIME"` plus `<SCOPE> AND status = Blocked` for all blockers.
- Digest: epics + statuses, tickets grouped by status, blockers + who's working on what.

After all subagents complete, update `last_gathered` in `config.md` to the current ISO timestamp (e.g. `2026-05-31T14:30:00Z`). **This timestamp is what gates the 24-hour auto-trigger** — keep it accurate.

### 3. Write to live log

Append to `<vault>/projects/<project>/knowledge/live/YYYY-MM-DD.md` with a timestamp header:

```markdown
## HH:MM

### Slack
(digested slack data)

### GitHub
(digested github data)

### Jira
(digested jira data)
```

Create the file with a `# YYYY-MM-DD` heading if it doesn't exist.

### 4. Fetch and refresh resources

**New links:** scan the gathered data for URLs. For each that's relevant (design docs, RFCs, API docs, architecture diagrams — not login pages / dashboards / CI logs) and not already saved:

- **Google Drive URL** (`docs.google.com/document/d/<id>`, `drive.google.com/file/d/<id>`, etc.): extract `<id>`, call `mcp__claude_ai_Google_Drive__get_file_metadata` for `modifiedTime`, then `mcp__claude_ai_Google_Drive__read_file_content` for the body. Save with `drive_file_id` and `drive_modified_time` in frontmatter alongside `url` and `fetched`.
- **Otherwise**: use `WebFetch`.

If unfetchable (auth wall, 404), save a stub with the URL and reason. Link from the live log: `See [[resources/<slug>]]`.

**Existing resources:** for each file in `knowledge/resources/` with a `url` property:

- **If `drive_file_id` is in frontmatter**: call `get_file_metadata` with `excludeContentSnippets: true`. If `modifiedTime == drive_modified_time`, **skip** (no fetch, no rewrite). Otherwise `read_file_content`, update body, update both `drive_modified_time` and `fetched`.
- **Otherwise (non-Drive URL)**: `WebFetch`. If content changed, update body + `fetched`. If same, skip.
- On fetch failure, leave existing content and add a note: `<!-- refresh failed: YYYY-MM-DD — reason -->`.

### 5. Compact older tiers

**Live → Daily:** for any `knowledge/live/YYYY-MM-DD.md` from a previous day without a matching `knowledge/daily/YYYY-MM-DD.md`: read it + 1–2 surrounding live files, spawn an agent to produce a daily summary, write to `knowledge/daily/YYYY-MM-DD.md`.

**Daily → Weekly:** if a completed calendar week (Mon–Sun) has dailies but no `knowledge/weekly/YYYY-WNN.md`: read the week's dailies, spawn an agent to summarize, write to `knowledge/weekly/YYYY-WNN.md`.

**Cleanup:** delete `knowledge/live/` files older than 7 days.

### 6. Update the wiki

**Rewrite `<vault>/projects/<project>/wiki/activity.md` in full.** This page is always included when agents spawn, so it MUST be current. Source material:

- Today's `knowledge/live/YYYY-MM-DD.md` — full granularity
- Last 7 `knowledge/daily/` files
- Latest `knowledge/weekly/` file
- Recent `knowledge/sessions/` files

Structure:

```markdown
# Recent Activity

*Last updated: YYYY-MM-DD HH:MM*

## This week
(synthesized from today's live log + recent daily summaries)

## Slack
## GitHub
## Jira
## Notable sessions
```

**Update `wiki.md` "Current focus"** — short summary of what the team is working on now.

**Review other wiki pages** and update any with new info: new team members → `wiki/team.md`; architecture changes → `wiki/architecture.md`; key decisions → `wiki/decisions.md`; new terms → `wiki/glossary.md`; process changes → `wiki/workflows.md`. Wiki pages reflect current state; don't append history.

### 7. Report sources and ask about additions

Tell the user where context was gathered FROM, then ask if anything new should be tracked. Format:

```
Context refreshed for <project>. Pulled from:

  Slack:  #channel1, #channel2, #channel3
          DMs: @alice, @bob
  GitHub: org/repo1, org/repo2
  Jira:   project SIG (epics: SIG-100, SIG-101)

  <if any source was empty in config.md, mention it as missing — e.g.
   "Slack: (none configured)">

Anything new to add to this project? For example:
  - new Slack channel or DM (e.g. someone joined the team, a new
    incident channel)
  - new GitHub repo this project touches
  - new Jira epic to scope to, or a project_key if missing
  - new team members whose DMs should be mined for context

Reply "no" / "skip" if nothing's new. Otherwise, describe what to
add and I'll update <vault>/projects/<project>/config.md.
```

If the user names additions, edit `config.md` directly — preserve existing values, only append. Confirm the additions in plain text afterwards.

### Notes

- There is **no recurring cron** for this skill. Auto-triggers come from CLAUDE.md's "Active project" rule on every user interaction in a linked session, gated by the 24-hour staleness check.
- `gathering_paused` config field is no longer read or written. Existing inert lines in project configs are harmless.
- The `~/.claude/.last-user-activity` marker and the `UserPromptSubmit` hook that maintains it are no longer used (cron-era artifacts). They're harmless if left in place; the hook can be removed from `~/.claude/settings.json` at the user's discretion.
- The per-project scheduler lease at `~/.claude/the-agency-sessions/<project>.scheduler` is no longer read or written. Stale lease files can be deleted manually; they have no effect.
