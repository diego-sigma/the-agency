# Contributing

Thanks for your interest in The Agency. This doc covers how to propose changes.

## Development setup

1. Clone the repo
2. Run `./scripts/init.sh` to set up symlinks and a local vault
3. Start Claude Code in any directory and the slash commands will be available globally

## Proposing a change

1. Open an issue describing the change (especially for new skills or breaking changes)
2. Fork or branch
3. Make your change
4. Run through the "When making changes" checklist below
5. Add an entry to `CHANGELOG.md` under `[Unreleased]` in the appropriate section (Added / Changed / Deprecated / Removed / Fixed / Security)
6. Open a PR

## When making changes

Every change should leave the framework internally consistent. Before opening a PR, walk through this checklist:

### Always

- **`README.md`** — keep it accurate. If your change adds, removes, or renames anything user-facing (a slash command, a workflow, a directory), update the README. The Commands table, the directory tree, and the usage examples are the most common places to update.
- **`CHANGELOG.md`** — add an entry under `[Unreleased]` describing the user-visible change.
- **Test it locally** — run `./scripts/init.sh` and try the affected skill end-to-end before committing.

### When you change a skill

- Update the skill's frontmatter (`name`, `description`) if its behavior or trigger changed
- Update the relevant section in `CLAUDE.md` if the change affects what context agents receive or how they behave
- Update the Commands table in `README.md` if the description in the README is now out of date
- If the skill is new, ensure `scripts/init.sh` will symlink it (it picks up everything in `skills/`)

### When you add or change a persona

- Update `templates/personas/<name>.md`
- Update the team table in `README.md`
- Update the agent-routing table in `CLAUDE.md` if the persona owns a new task type
- Existing projects don't auto-update — users run `/update-project <name>` to copy the new persona into their `team/` directory

### When you change vault structure

- Update the vault tree in `CLAUDE.md` ("Vault structure" section near the top)
- Update the vault tree in `README.md` ("How it works" section)
- Update `templates/project/` if templates need to change
- Update `scripts/init-project.sh` if directory creation needs to change
- Update `skills/new-project.md` so new projects follow the new structure
- Update `skills/update-project.md` so existing projects can migrate
- This is almost always a MAJOR version bump

### When you change agent context (what gets sent to subagents)

- Update `CLAUDE.md`'s "How to use personas" baseline list
- Update each task-specific spawn section that adds extra files
- Update the relevant skill files

### When in doubt

Search the repo for the thing you changed and update everywhere it's referenced. The framework is small enough that grep is the right tool.

## Versioning

This project uses [Semantic Versioning](https://semver.org/). Use this table to decide how a change affects the version:

| Change | Version bump |
|--------|--------------|
| Vault structure changes requiring migration (renamed dirs, removed fields) | MAJOR |
| Skill renamed or removed | MAJOR |
| `CLAUDE.md` behavior changes that break existing flows | MAJOR |
| New skill added | MINOR |
| New persona added | MINOR |
| New optional config section with defaults | MINOR |
| Typo fix or clarified wording | PATCH |
| Bug fix in a skill | PATCH |

The maintainer bumps `VERSION` and releases with a git tag.

## Commit style

Conventional Commits are encouraged but not required:

- `feat:` new skill or capability
- `fix:` bug fix
- `docs:` documentation only
- `refactor:` internal restructure
- `chore:` non-functional changes (gitignore, tooling)

Use `feat!:` or `fix!:` for a breaking change, and call it out in the PR description.

## Scope of contributions

Good fits:
- New skills that follow the existing pattern
- Improvements to existing skills or persona definitions
- Better handling of edge cases in `gather-context` (e.g., new data sources)
- Documentation and examples

Less likely to merge:
- Changes that couple The Agency to a specific company's internal tooling
- Major restructures without prior discussion in an issue
