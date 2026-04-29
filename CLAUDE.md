# The Agency System

This repo is a framework for running an AI engineering team inside Claude Code. Project context and agent state live in an Obsidian vault. This file teaches you how the system works.

## Active project (check first)

On every interaction, check if `~/.claude/the-agency-sessions/<current-session-id>` exists. Each Claude Code session has its own link file, so multiple sessions can be linked to the same (or different) projects simultaneously. The link file is global, so this works regardless of the current working directory.

If a link file exists for the current session, read the `project` field to get the project name. When a project is linked:

- All commands that take a project name should default to the linked project (the user doesn't need to specify it)
- Always have the project's `wiki.md` loaded as background context
- When spawning agents, use the personas from the linked project's `team/` directory
- If the user says "gather context", "review PR #123", "status", etc. without naming a project, use the linked project

If no link file exists for the current session, commands require an explicit project name.

## Vault location

Read the vault path from the line starting with `vault=` in `~/.claude/the-agency-config`. The same file's `repo=` line points at this framework repo. If the file doesn't exist, the framework hasn't been installed yet — tell the user to run `./scripts/init.sh` from the cloned repo.

## Vault structure

```
<vault>/projects/<project-name>/
  config.md         — data sources (Slack channels, GitHub repos, Jira project keys)
  wiki.md           — project wiki index (overview, stable reference)
  wiki/             — wiki pages
    activity.md     — Recent Activity (rewritten on every gather; always included in agent context)
  team/             — agent persona files
    steve.md        — Staff Engineer (architecture, big picture)
    earl.md         — Senior Engineer (implementation, design)
    debug-bot-500.md — Code Reviewer (correctness, security)
    pat.md          — Project Manager (status, coordination)
  knowledge/
    live/           — raw gathered data, one file per day, appended throughout the day (kept 7 days)
    daily/          — summarized daily digests, one per day (never deleted)
    weekly/         — summarized weekly digests, one per week (never deleted)
    sessions/       — auto-saved session notes (decisions, actions, context learned, never compacted)
    plans/          — implementation plans, architecture proposals, strategies (never compacted)
    resources/      — fetched content from links shared in the project (web pages, docs, etc.)
```

## How to resolve a project

When the user references a project by name:

1. Read the vault path from the `vault=` line of `~/.claude/the-agency-config`
2. Read `<vault>/projects/<project-name>/config.md` to understand the project's data sources
3. Read `<vault>/projects/<project-name>/wiki.md` for the project overview
4. Read `<vault>/projects/<project-name>/wiki/activity.md` for current Recent Activity

If `wiki/activity.md`'s "Last updated" timestamp is older than a day, suggest running a context gather first.

## How to gather context

When the user says "gather context for <project>":

### Step 0 — Check the paused flag

Read the State section of `config.md`:

- **Background loop + paused** — exit silently
- **Foreground + paused** — clear the flag and proceed (manual `/gather-context` doubles as resume + catch-up); tell the user gathering was paused and is now resumed
- **Not paused** — proceed normally

### Step 1 — Gather fresh data

Read the project's `config.md` to get the list of sources. For each source, spawn a parallel subagent:

Before fetching, read `last_gathered` from the project's `config.md` State section. Use this timestamp to only fetch new data. If no timestamp exists (first gather), do a full pull (last 3 days for Slack, last 7 days for GitHub/Jira).

**Slack** — For each channel and DM listed in config:
- Use Slack MCP tools (`slack_read_channel`) to read messages since `last_gathered` (pass as `oldest` parameter)
- For each person in the `dms` list, read DM conversations since `last_gathered` — only extract messages relevant to this project (filter by project name, repo names, ticket keys, or related keywords)
- Digest into a structured block: key discussions, relevant DM context, decisions, action items, open questions

**GitHub** — For each repo listed in config:
- Use `gh` CLI to list all open PRs
- For each open PR: read the description (`gh pr view`), the diff (`gh pr diff`), and review comments (`gh pr view --comments`) to fully understand what it does and where it stands
- Get recently merged PRs and issues updated since `last_gathered`: `gh pr list --state merged --search "merged:>YYYY-MM-DDTHH:MM:SS"`, `gh issue list --search "updated:>YYYY-MM-DDTHH:MM:SS"`
- Digest into a structured block: for each open PR summarize what it changes, its review status, and any outstanding comments. Also cover what landed recently and what needs attention

**Jira** — For the project key in config:
- Use Atlassian MCP tools (`searchJiraIssuesUsingJql`) with `updated >= "YYYY-MM-DD HH:MM"` using `last_gathered`
- Digest into a structured block: sprint goal, ticket statuses, blockers, who's working on what

After all sources are gathered, update `last_gathered` in `config.md` to the current timestamp.

### Step 2 — Write to live log

Append the gathered data to `knowledge/live/YYYY-MM-DD.md` with a timestamp:

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

### Step 3 — Compact older tiers

**Live → Daily:** Check if there are live files from previous days that don't have a corresponding daily summary. For each:
- Read the target day's live file AND the surrounding 1-2 live files for context
- Spawn an agent to produce a daily summary that captures what mattered, informed by surrounding days
- Write to `knowledge/daily/YYYY-MM-DD.md`

**Daily → Weekly:** Check if there's a completed calendar week (Mon-Sun) with daily summaries but no weekly summary:
- Read that week's daily summaries
- Spawn an agent to produce a weekly summary
- Write to `knowledge/weekly/YYYY-WNN.md`

**Cleanup:** Delete live files older than 7 days.

### Step 4 — Update the wiki

Update the project wiki from the freshly gathered data. The wiki is the agents' primary context, so it must reflect current state. See the "Project wiki" section below for details on what to update and how.

In particular, always rewrite `wiki/activity.md` in full from:
- Today's `knowledge/live/YYYY-MM-DD.md` (full granularity for today)
- The last 7 `knowledge/daily/` files (recent summarized history)
- The latest `knowledge/weekly/` file (broader context)
- Recent `knowledge/sessions/` files (decisions and actions)

Also update the "Current focus" section of `wiki.md` and any other wiki pages that have new relevant information.

## Project wiki

The wiki is the **primary reference** for answering questions about a project. It is designed to be read quickly and give a complete picture without digging through knowledge tiers.

### Structure

```
<vault>/projects/<project-name>/
  wiki.md           — index page: project overview with links to all wiki pages
  wiki/
    activity.md     — Recent Activity (rewritten on every gather; always included in agent context)
    architecture.md — system architecture, key components, data flow
    team.md         — who works on this, roles, responsibilities
    decisions.md    — key decisions log with rationale
    glossary.md     — project-specific terms, acronyms, naming conventions
    workflows.md    — how the team works (PR process, deploy process, on-call, etc.)
    preferences.md  — project-specific working preferences (code style, review rules, things to avoid)
    todo.md         — project to-do list (only the user can modify items)
    (additional pages as needed)
```

### wiki.md (index page)

The index page is a quick-reference overview. Structure:

```markdown
# <Project Name> Wiki

## What is this project?
(1-2 sentence summary)

## Key links
- Repo: ...
- Slack: ...
- Jira: ...

## Architecture
(2-3 sentence summary, link to [[wiki/architecture]] for details)

## Team
(list of people and roles, link to [[wiki/team]] for details)

## Current focus
(what the team is working on right now — updated from latest activity)

## Recent decisions
(last 3-5 decisions, link to [[wiki/decisions]] for full log)

## Recent activity

See [[wiki/activity]] for the latest digest of what's happening across Slack, GitHub, and Jira.

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

### wiki/activity.md

The activity page is the primary volatile context — it's rewritten in full on every context gather and is **always included when agents are spawned**. Structure:

```markdown
# Recent Activity

*Last updated: YYYY-MM-DD HH:MM*

## This week
(synthesized from today's live log + recent daily summaries)

## Slack
(key discussions, decisions, action items from recent channels and DMs)

## GitHub
(open PRs with status, recently merged work, notable issues)

## Jira
(sprint goal, ticket statuses, blockers, who's working on what)

## Notable sessions
(recent session notes worth surfacing — links to [[sessions/YYYY-MM-DD-slug]])
```

### When to update

- **During context gathering** — rewrite `wiki/activity.md` in full from the newly gathered data. Also review all other wiki pages and update any that have new information. For example: a new team member mentioned in Slack → update `wiki/team.md`. An architecture decision in a PR → update `wiki/architecture.md` and `wiki/decisions.md`. Update the "Current focus" section of `wiki.md` too.
- **During sessions** — if a conversation reveals new project knowledge (architecture details, workflow changes, terminology), update the relevant wiki page.
- **New pages** — create new wiki pages when a topic grows beyond a few lines. Add a link from wiki.md.

### How to update

- Wiki pages should be **current state, not history**. Update in place — don't append timestamped entries (that's what knowledge tiers are for).
- If a fact changes (e.g., team member leaves, architecture changes), update the wiki to reflect the new state.
- Link to knowledge files for historical context: "We switched from Redis to DynamoDB in April 2026 — see [[sessions/2026-04-05-cache-migration-decision]]"
- Keep pages concise. If a page gets too long, split it.

### wiki/preferences.md

This page stores project-specific working preferences — how the team should behave, what to avoid, code style rules, review conventions. It is the project-level equivalent of Claude Code's memory/feedback system.

- **Always read `wiki/preferences.md` before executing any task** for a linked project
- When the user gives project-specific feedback ("always do X for this project", "never touch Y", "use Z syntax"), save it to `wiki/preferences.md`
- Agents must respect preferences when reviewing, implementing, or planning

### When answering questions about a project

**Read wiki.md, wiki/preferences.md, and relevant wiki pages first.** The wiki is the fastest path to answering most project questions. Only fall back to knowledge tiers (live, daily, sessions) if the wiki doesn't have the answer or the question is about something very recent.

## How to use personas

When executing a task that involves an agent persona:

1. Read the persona file from the project's `team/` directory
2. Use the persona's full content (frontmatter + body) as the behavioral frame for a subagent
3. **Always include these three files in every agent spawn** (the baseline context):
   - `wiki.md` — project overview and stable reference
   - `wiki/activity.md` — current Recent Activity (volatile, always fresh)
   - `wiki/preferences.md` — project-specific working rules
4. Include any other wiki pages relevant to the task (e.g., `wiki/architecture.md` for code reviews, `wiki/team.md` when asking about people)
5. The subagent should respond and behave as that persona — tone, focus areas, decision-making style

Always tell the user which agent is "speaking" when relaying output from a persona.

### Agent routing

When a project is linked, route tasks to the appropriate agent(s) automatically based on what the user is asking for:

| Task | Agent(s) |
|------|----------|
| Code changes / implementation | Earl |
| Code or PR reviews | Steve + Debug Bot 500 |
| Plans (implementation plans, architecture, strategy) | Earl + Steve |
| Project questions (status, who, what, when, why) | Pat |

For multi-agent tasks, spawn each agent in sequence, passing prior agents' output as context to subsequent agents. Label each output clearly with the agent's name.

## How to run a team review

When the user says "review PR #X for <project>" or "team review PR #X":

1. Read the project's wiki.md, wiki/activity.md, wiki/preferences.md, and wiki/architecture.md
2. Fetch the PR diff (via `gh pr diff <number>` or GitHub MCP tools)
3. Run the review pipeline:

   **Step 1 — Debug Bot 500 (Code Reviewer):**
   - Spawn a subagent with Debug Bot 500's persona + project context + PR diff
   - Debug Bot 500 reviews for: correctness, edge cases, security, performance
   - Write to `knowledge/github/pr-<id>-debug-bot-review.md`

   **Step 2 — Steve (Staff Engineer):**
   - Spawn a subagent with Steve's persona + project context + PR diff + Debug Bot 500's review
   - Steve reviews for: architecture, long-term implications, cross-system impact
   - Write to `knowledge/github/pr-<id>-steve-review.md`

4. Present the combined review to the user
5. Ask the user if they want to post the review to GitHub

## How to run a team implementation

When the user says "implement <ticket> for <project>":

1. Read the project's wiki.md, wiki/activity.md, wiki/preferences.md, and wiki/architecture.md
2. Read the ticket details (from Jira MCP or user input)
3. Run the implementation pipeline:

   **Step 1 — Pat (PM):**
   - Reviews the ticket requirements
   - Writes a clear implementation brief with acceptance criteria
   - Flags any ambiguities or missing requirements

   **Step 2 — Earl (Senior Engineer):**
   - Reads Pat's brief + project context
   - Creates an implementation plan
   - Implements the code
   - Commits to a branch

   **Step 3 — Debug Bot 500:**
   - Reviews Earl's implementation
   - Reports findings by severity
   - If CRITICAL issues: loop back to Earl for fixes

   **Step 4 — Steve (Staff Engineer):**
   - Final architectural review
   - Sign-off or concerns

4. Present the result to the user

## How to get project status

When the user asks "what's the status of <project>":

1. Read the project's wiki.md and wiki/activity.md
2. Spawn Pat (PM) with her persona + wiki.md + wiki/activity.md + wiki/preferences.md
3. Pat synthesizes a status report
4. If `wiki/activity.md`'s "Last updated" timestamp is stale (>1 day), suggest gathering context first

## How to produce a daily digest

When the user says "daily digest for <project>" or "catch me up on <project>":

1. Run a context gather first (writes to live log, triggers compaction, rewrites wiki's Recent Activity)
2. Read today's `knowledge/live/YYYY-MM-DD.md` and yesterday's `knowledge/daily/` summary for comparison
3. Spawn Pat (PM) with her persona + wiki.md + wiki/activity.md + wiki/preferences.md + today's live data + yesterday's daily:
   - What happened (most important first)
   - What needs attention (blockers, stale PRs, unanswered questions)
   - What's coming up (based on current state)
4. Present the digest to the user

## How to explain code

When the user says "explain <thing> in <project>":

1. Read the project's wiki.md, wiki/activity.md, wiki/preferences.md, wiki/architecture.md, and config.md
2. Find the relevant code:
   - If the user named a specific file or function, read it directly
   - If the user named a concept (e.g., "the auth flow"), use Grep/Glob to find relevant files
3. Spawn Steve (Staff Engineer) with his persona + project context + the gathered code
4. Steve explains it in his style: big picture first, simple language, analogies, step-by-step walkthrough, with file/line references
5. Present Steve's explanation to the user

## Resources

When a link is shared during a session (by the user, or found in Slack/GitHub/Jira during context gathering), fetch its content and save it to the vault so it can be referenced later.

### When to save

- **User shares a link** during a session — always fetch and save it
- **During context gathering** — when links are found in Slack messages, PR descriptions, Jira tickets, or comments, fetch them **only if they are relevant to the project** (e.g., design docs, RFCs, architecture diagrams, API docs, related blog posts). Skip generic links (login pages, dashboards, CI logs, etc.)

### Where to save

Write to `<vault>/projects/<project>/knowledge/resources/<slug>.md`

Use a descriptive slug based on the content (e.g., `auth-rfc.md`, `api-v2-design-doc.md`, `rate-limiting-blog.md`). Do not include dates — resources are reference material, not temporal.

### How to fetch

1. Use `WebFetch` to retrieve the page content
2. Extract the meaningful content (title, body text, images if relevant)
3. Save as markdown with metadata:

```markdown
---
url: <original URL>
fetched: YYYY-MM-DD
title: <page title>
---

# <page title>

Source: <original URL>

(page content converted to markdown)
```

4. If the page can't be fetched (auth required, 404, etc.), save a stub noting the URL and why it failed — it's still useful as a reference pointer

### URL is the source of truth

If a resource file has a `url` property in its frontmatter, the URL is the **source of truth** and the local markdown file is a cached copy. During context gathering, all resources with URLs are re-fetched and updated if the content has changed. This keeps design docs, RFCs, and other living documents in sync.

### Linking

- When a resource is saved, link to it from the note that referenced it: `See [[resources/auth-rfc]]`
- Resources can be linked from live logs, session notes, plans, or the wiki

## Plans

When a project is linked and you create or update a plan (implementation plan, architecture proposal, migration strategy, etc.), save it to the vault.

### Where to save

Write to `<vault>/projects/<project>/knowledge/plans/YYYY-MM-DD-<short-slug>.md`

### What to save

```markdown
# Plan: <short description>
Date: YYYY-MM-DD
Status: draft | in-progress | completed | abandoned

## Goal
(what this plan aims to accomplish)

## Approach
(the proposed solution, broken into steps)

## Open questions
(things that need to be resolved before or during execution)

## Related
- [[sessions/YYYY-MM-DD-slug]] — session where this was discussed
- [[plans/YYYY-MM-DD-slug]] — prior plan this builds on
```

### When to save

- When you create a plan during a conversation (implementation plan, refactor strategy, etc.)
- When the user asks you to plan something
- When a plan is updated (change the status and add notes about what changed)

### Linking plans and sessions

- When a session executes a plan, the session note should link back: `Executed [[plans/YYYY-MM-DD-auth-refactor]]`
- When a plan is created during a session, the plan should link to its origin: `Created during [[sessions/YYYY-MM-DD-auth-discussion]]`
- When a plan is completed, update its status and link to the session that finished it

## Session notes (automatic)

When a project is linked (`~/.claude/the-agency-sessions/<current-session-id>` exists), you MUST save session notes to the vault automatically. This is not optional.

### When to save

- **After completing any major task** (review, implementation, context gather, status report, etc.)
- **When the user says "done", "wrap up", "that's it", "bye", or similar end-of-session signals**
- **When a significant decision is made** during conversation

### Where to save

Write to `<vault>/projects/<project>/knowledge/sessions/YYYY-MM-DD-<short-slug>.md`

Use a short descriptive slug based on what happened (e.g., `2026-04-08-pr-423-review.md`, `2026-04-08-auth-refactor-decision.md`).

### What to save

```markdown
# Session: <short description>
Date: YYYY-MM-DD

## Decisions
- (decisions made during this session)

## Actions taken
- (what was done — PRs reviewed, code written, context gathered, etc.)

## Context learned
- (new information discovered — things that weren't in the vault before)

## Open items
- (things that still need to happen, with owners if known)
```

Keep it concise. Only capture what would be useful to the team in a future session. Skip routine details — focus on decisions, discoveries, and open threads.

### Important

- Do this quietly — write the note without asking permission or announcing it
- Do not interrupt the user's flow to save a note — do it alongside your response
- If multiple tasks happen in one session, write multiple notes

## Obsidian linking

All notes in the vault MUST use Obsidian wikilinks (`[[note]]`) to reference other notes. This makes the vault navigable as a connected knowledge graph.

### Link syntax

- `[[filename]]` — link to a note (no `.md` extension needed)
- `[[folder/filename]]` — link with path relative to vault root
- `[[filename#Heading]]` — link to a specific section
- `[[filename|display text]]` — link with custom display text

### When to link

Every note should link to related notes. Specific rules:

**Live logs** (`knowledge/live/`):
- Link to any PR review files when mentioning PRs: `Reviewed [[sessions/2026-04-08-pr-423-review|PR #423]]`
- Link to previous day's live log for continuity: `Continued from [[live/2026-04-07]]`

**Daily summaries** (`knowledge/daily/`):
- Link to the live log(s) they were compacted from: `Summarized from [[live/2026-04-08]]`
- Link to relevant session notes: `See [[sessions/2026-04-08-auth-decision]]`

**Weekly summaries** (`knowledge/weekly/`):
- Link to each daily summary in the week: `[[daily/2026-04-07]]`, `[[daily/2026-04-08]]`, etc.

**Session notes** (`knowledge/sessions/`):
- Link to the live log for that day: `During [[live/2026-04-08]]`
- Link to other session notes if they're related: `Follow-up to [[sessions/2026-04-06-auth-discussion]]`
- Link to plans executed during the session: `Executed [[plans/2026-04-08-auth-refactor]]`
- Link to PR review files if relevant

**Plans** (`knowledge/plans/`):
- Link to the session where the plan was created: `Created during [[sessions/2026-04-08-auth-discussion]]`
- Link to sessions that executed or updated the plan
- Link to related plans: `Supersedes [[plans/2026-04-01-auth-v1]]`

**Resources** (`knowledge/resources/`):
- Linked from wherever the URL was found: live logs, session notes, plans
- Can link to related resources: `See also [[resources/api-v2-design-doc]]`

**Wiki** (`wiki.md` and `wiki/`):
- wiki.md links to all wiki pages: `[[wiki/architecture]]`, `[[wiki/team]]`, etc.
- Wiki pages link to knowledge files for historical context: `See [[sessions/2026-04-05-cache-migration]]`
- Wiki pages link to resources: `See [[resources/api-v2-design-doc]]`
- Other notes can link to wiki pages: `For architecture details see [[wiki/architecture]]`

**PR review files**:
- Earl's review links to Debug Bot 500's and Steve's: `See also: [[sessions/pr-423-debug-bot-review]], [[sessions/pr-423-steve-review]]`
- Each review links back to the live log entry where it was captured

### Example

```markdown
# Daily Summary: 2026-04-08

Summarized from [[live/2026-04-08]].

## Highlights
- PR #423 (auth refactor) reviewed by the team — see [[sessions/2026-04-08-pr-423-review]]
- Sprint goal updated after standup — see [[sessions/2026-04-08-sprint-update]]
- SIG-234 moved to Done, [[daily/2026-04-07|yesterday]] it was In Review
```

## General rules

- Always read wiki.md (and relevant wiki pages) before executing any project task
- Always identify which agent is speaking in your output
- Write all outputs to the vault so there's an audit trail
- Always use Obsidian wikilinks when referencing other vault notes
- When in doubt, ask the user — don't assume
- Personas in the project's `team/` directory override the templates in this repo
- **Background gathers are silent.** Scheduled/looped context gathers must run entirely in the background. Do not notify, interrupt, or show results to the user. Write to the vault silently. Only surface gathered information when the user asks for it.

## Framework maintenance rules

When working on the framework itself (this repo — not on a project in someone's vault), follow the "When making changes" checklist in `CONTRIBUTING.md`. The most important rules:

- **Always update `README.md`** when adding, removing, or renaming anything user-facing (slash commands, workflows, directories). The Commands table, the directory tree, and the usage examples are the most commonly stale sections.
- **Always add a `CHANGELOG.md` entry** under `[Unreleased]` describing the user-visible change.
- **Keep CLAUDE.md and skills in sync** — if a skill's behavior changes, the corresponding section here likely needs to change too.
- **Touch every reference** — when renaming or removing something, grep the whole repo and update every mention. The framework is small enough that this is fast.
- **Templates and existing projects diverge** — changing `templates/project/wiki.md` does not retroactively update existing projects. If the change should apply to existing projects, update `skills/update-project.md` so users can migrate.
- **Test before committing** — run `./scripts/init.sh` and exercise the affected skill end-to-end. Slash commands that don't symlink correctly are a common silent failure.

If the user asks you to make a change that requires updating multiple files but doesn't mention them all, surface the full list before you start. Better to over-communicate than ship an inconsistent state.
