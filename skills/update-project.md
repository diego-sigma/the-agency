---
name: update-project
description: Propagates changes from the-agency repo templates to an existing project in the vault
argument-hint: "[project-name]"
---

# Update Project

## Trigger

User says "/update-project", "/update-project <project>", or "update project".

## Steps

### 1. Resolve the project

- If an argument is provided, use it as the project name
- Otherwise, use the linked project (from `~/.claude/the-agency-sessions/`)
- If neither, list available projects and ask

### 2. Read vault path

- Read vault path from `~/.claude/the-agency-config`
- Confirm the project exists at `<vault>/projects/<project>/`

### 3. Sync personas

For each persona in `templates/personas/`:
- If the file does NOT exist in the project's `team/` directory, copy it (new agent added to the framework)
- If the file exists, **do not overwrite** — the project copy may have been customized

Report: "Added N new persona(s)" or "All personas up to date"

### 4. Sync directory structure

Ensure all required directories exist in the project. Create any that are missing:

```
team/
wiki/
knowledge/
  live/
  daily/
  weekly/
  sessions/
  plans/
  resources/
```

Report which directories were created, if any.

### 5. Sync wiki pages

For each standard wiki page (architecture, team, decisions, glossary, workflows, preferences, todo):
- If the page does NOT exist in the project's `wiki/` directory, create it with the default template
- If the page exists, **do not overwrite**
- If `wiki.md` exists, check that it links to all standard pages — add any missing links

Report: "Added N new wiki page(s)" or "All wiki pages up to date"

### 6. Sync config sections

Read the project's `config.md` and check for missing sections. Add any that are missing with empty defaults:
- `dms:` under Slack
- `GitHub` section with `repos:`
- `Jira` section with `project_key:`
- `Team` section with `members:`
- `State` section with `last_gathered:`

**Do not overwrite existing values** — only add missing sections.

### 7. Report

Summarize what was updated:
```
Updated <project>:
- Added personas: steve.md (new)
- Created directories: knowledge/resources/, knowledge/plans/
- Added wiki pages: todo.md, preferences.md
- Added config sections: State
```

Or: "Project <project> is already up to date."
