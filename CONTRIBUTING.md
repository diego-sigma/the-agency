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
4. Add an entry to `CHANGELOG.md` under `[Unreleased]` in the appropriate section (Added / Changed / Deprecated / Removed / Fixed / Security)
5. Open a PR

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
