# The Agency

An AI engineering team for your projects, powered by Claude Code and organized in Obsidian.

Define agent personas with distinct personalities, point them at your project's Slack, GitHub, and Jira, and let them gather context, review PRs, and help drive implementation — all from within Claude Code.

## The team

| Agent | Role | Personality |
|-------|------|-------------|
| **Steve** | Staff Engineer | Friendly, 30+ years experience. Explains complex things simply. Thinks in decades. |
| **Earl** | Senior Engineer | Energetic, opinionated, thorough. Drives implementation. Bias toward action. |
| **Debug Bot 500** | Code Reviewer | Relentless review machine. Categorizes findings by severity. Zero emotion. |
| **Pat** | Project Manager | Calm, organized, always knows what's going on. Keeps the team aligned. |

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and configured
- MCP connections for the sources you want to use:
  - **Slack** — Slack MCP tools for reading channels
  - **GitHub** — `gh` CLI authenticated
  - **Jira** — Atlassian MCP tools for reading tickets
- [Obsidian](https://obsidian.md) (optional, but recommended for browsing your vault)

## Quick start

```bash
# 1. Clone the repo
git clone <repo-url> the-agency
cd the-agency

# 2. Run init (links skills as slash commands + initializes vault)
./scripts/init.sh
```

Then open Claude Code in the `the-agency/` directory:

```
/new-project mcp-server
```

## Usage

Open Claude Code in the `the-agency/` directory and use natural language:

```
gather context for mcp-server
```
Reads your Slack channels, GitHub repos, and Jira board. Writes digested summaries to your vault and rebuilds the project briefing.

```
review PR #423 for mcp-server
```
Runs the PR through the full team review pipeline: Earl (implementation) → Debug Bot 500 (correctness/security) → Steve (architecture). Each agent's review is saved to the vault.

```
what's the status of mcp-server?
```
Pat reads the project context and gives you a status report with blockers, risks, and action items.

```
implement JIRA-123 for mcp-server
```
Pat clarifies requirements, Earl builds it, Debug Bot 500 reviews, Steve signs off.

```
daily digest for mcp-server
```
Gathers the last 24 hours of activity and Pat produces a short summary — what happened, what needs attention, what's coming up.

```
explain the auth flow in mcp-server
```
Steve reads the relevant code and walks you through it in simple, approachable terms with analogies and concrete examples.

## How it works

**Two layers:**

1. **This repo** (shareable) — agent personas, skills, scripts, and the CLAUDE.md that teaches Claude Code how to use them
2. **Your vault** (local) — project configs, gathered knowledge, assembled context, execution outputs

When you ask Claude Code to do something for a project, it reads the relevant personas and project context from your vault, spawns subagents with those personas, and writes results back to the vault.

```
the-agency/                         ← this repo (shareable)
  CLAUDE.md                         ← instructions for Claude Code
  templates/personas/               ← default personas
  templates/project/                ← project scaffolding
  skills/                           ← workflow definitions
  scripts/                          ← setup scripts
  vault/                            ← your vault (local, gitignored)
    projects/mcp-server/
      config.md                     ← Slack channels, repos, Jira keys
      wiki.md                       ← project wiki + Recent Activity (primary agent context)
      wiki/                         ← wiki pages (architecture, team, decisions, etc.)
      team/                         ← personas (customize per project)
      knowledge/
        live/                       ← raw data, one file per day (kept 7 days)
        daily/                      ← daily summaries (never deleted)
        weekly/                     ← weekly summaries (never deleted)
        sessions/                   ← session notes (never deleted)
        plans/                      ← implementation plans (never deleted)
        resources/                  ← fetched content from shared links
```

The vault defaults to `vault/` inside the repo (gitignored). You can point it to an external Obsidian vault during `init.sh` if you prefer.

### Knowledge tiers

Knowledge is stored in three tiers that compact over time:

- **Live** — raw gathered data, appended throughout the day with timestamps. Kept for 7 days.
- **Daily** — summarized from live data. An agent reads 2-3 surrounding live files to produce a summary that captures what mattered. Never deleted.
- **Weekly** — summarized from daily summaries. One file per calendar week. Never deleted.

Compaction happens automatically during context gathering. Session notes are never compacted.

## Customization

### Edit personas

Personas are copied to each project's `team/` directory. Edit them there to customize per project — the project copy takes precedence over the template.

### Add new agents

Create a new `.md` file in `templates/personas/` (or directly in a project's `team/` directory). Follow the format of the existing personas: frontmatter with name/role/capabilities, then the system prompt.

### Add data sources

Edit a project's `config.md` to add or change Slack channels, GitHub repos, or Jira project keys.

### Create new projects

```
/new-project <project-name>
```

Each project gets its own team, context, and knowledge — fully independent.

## Optional: heartbeat scheduling

Once you're happy with the manual workflow, you can automate context gathering with a cron job:

```bash
# Gather context every 30 minutes
*/30 * * * * cd /path/to/the-agency && claude -p "gather context for mcp-server"
```

Or use Claude Code's built-in `/schedule` command. The agents and vault structure don't change — the only difference is what triggers the gather.
