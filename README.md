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

Tasks are routed to the right agent automatically:

| Task | Agent(s) |
|------|----------|
| Code changes / implementation | Earl |
| Code or PR reviews | Debug Bot 500 → Steve |
| Plans (implementation, architecture, strategy) | Earl + Steve |
| Project questions (status, who, what, when, why) | Pat |

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
git clone https://github.com/diego-sigma/the-agency.git
cd the-agency

# 2. Run init (installs slash commands globally + initializes vault)
./scripts/init.sh
```

Then open Claude Code in any directory and create your first project:

```
/new-project mcp-server
```

When prompted, give it your Slack channels, GitHub repos, Jira project key, and team members. Then link your session and you're ready:

```
/link-project mcp-server
```

That's it. From here you interact through commands and natural language.

## Commands

Once installed, the following commands are available globally — start Claude Code from any directory and type `/`.

### Working with a project

| Command | What it does |
|---------|--------------|
| `/new-project <name>` | Create a new project. Asks for sources (Slack, GitHub, Jira) and team members, scaffolds the vault layout, and offers to link the session. |
| `/link-project <name>` | Bind the current session to a project. Loads the wiki as agent context, runs an immediate context gather, and starts a silent hourly background refresh. All other commands default to this project. |
| `/unlink-project` | Disconnect the current session from its project. |
| `/update-project [name]` | Sync framework updates (new personas, new wiki pages, new directories) into an existing project without touching your customizations. |

### Refreshing project knowledge

| Command | What it does |
|---------|--------------|
| `/gather-context [name]` | Pull fresh data from Slack, GitHub, and Jira. Appends to the live log, compacts older tiers, and rewrites `wiki/activity.md`. Runs automatically every hour while a session is linked, but you can run it manually any time. |
| `/daily-digest [name]` | Pat synthesizes a short daily summary — what happened, what needs attention, what's coming up. Gathers fresh data first. |

### Understanding the project

| Command | What it does |
|---------|--------------|
| `/status [name]` | Pat gives a structured status report from the wiki: headline, workstreams, blockers, risks, action items. |
| `/explain <thing>` | Steve reads the relevant code and walks you through it in simple terms — big picture first, analogies, file/line references. Works for files, functions, or concepts ("the auth flow"). |

### Doing the work

| Command | What it does |
|---------|--------------|
| `/team-review <PR>` | Run a PR through the multi-agent review pipeline: Debug Bot 500 (correctness/security/edge cases) → Steve (architecture/long-term implications). Reviews are saved to the vault and you decide whether to post to GitHub. |
| `/todo` | List the project's to-do items so you can pick what to work on. |
| `/todo <task>` | Add a new to-do. Agents never modify to-dos — only you can. |

### Natural language too

You don't have to use slash commands. Once linked to a project, you can just ask:

- "what's the status?"
- "review PR #423"
- "explain the auth flow"
- "catch me up"
- "implement SIG-123"

Claude Code routes these to the right skill and the right agent.

## How it works

**Two layers:**

1. **This repo** (shareable) — agent personas, skills, scripts, and the CLAUDE.md that teaches Claude Code how to use them
2. **Your vault** (local) — project configs, gathered knowledge, the wiki, session notes

When you give a project task to Claude Code, it reads the relevant wiki pages and personas from your vault, spawns subagents with those personas as context, and writes results back to the vault.

```
the-agency/                         ← this repo (shareable)
  CLAUDE.md                         ← instructions for Claude Code
  templates/personas/               ← default personas
  templates/project/                ← project scaffolding
  skills/                           ← slash command definitions
  scripts/                          ← setup scripts
  vault/                            ← your vault (local, gitignored)
    projects/mcp-server/
      config.md                     ← Slack channels, repos, Jira keys
      wiki.md                       ← project wiki index
      wiki/
        activity.md                 ← Recent Activity (rewritten on every gather; always in agent context)
        architecture.md             ← system architecture
        team.md                     ← who works on this
        decisions.md                ← decisions log
        glossary.md                 ← project terms
        workflows.md                ← how the team works
        preferences.md              ← project working rules (always in agent context)
        todo.md                     ← to-do list (only you can modify)
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

### What agents see

Every agent spawn includes three files as the baseline context:

- `wiki.md` — project overview and stable reference
- `wiki/activity.md` — current Recent Activity (rewritten on every context gather)
- `wiki/preferences.md` — project-specific working rules

Task-specific spawns add more (e.g., `wiki/architecture.md` for code reviews). Agents do not get raw knowledge tiers by default — those exist as the source material the wiki is built from.

### Knowledge tiers

Project data is stored in three tiers that compact over time:

- **Live** — raw gathered data, appended throughout the day with timestamps. Kept for 7 days.
- **Daily** — summarized from live data. An agent reads surrounding live files to produce a summary that captures what mattered. Never deleted.
- **Weekly** — summarized from daily summaries. One file per calendar week. Never deleted.

Compaction happens automatically during context gathering. Session notes, plans, and resources are never compacted.

## Customization

### Edit personas

Personas are copied to each project's `team/` directory. Edit them there to customize per project — the project copy takes precedence over the template.

### Add new agents

Create a new `.md` file in `templates/personas/` (or directly in a project's `team/` directory). Follow the format of the existing personas: frontmatter with name/role/capabilities, then the system prompt.

### Add data sources

Edit a project's `config.md` to add or change Slack channels, GitHub repos, Jira project keys, or team members.

### Set project preferences

Tell Claude Code working rules during a session ("always use Postgres syntax for this project", "never touch the legacy auth module"). They get saved to `wiki/preferences.md` and respected automatically by every agent on that project.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The framework is intentionally minimal — adding new skills follows the existing pattern.
