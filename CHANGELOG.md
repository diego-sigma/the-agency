# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-04-24

### Added
- Initial framework release
- Four agent personas: Steve (Staff Engineer), Earl (Senior Engineer), Debug Bot 500 (Code Reviewer), Pat (Project Manager)
- Per-project Obsidian vault with tiered knowledge storage (live → daily → weekly)
- Wiki-based agent context with `wiki/activity.md` as the volatile primary reference
- Slash commands: `/new-project`, `/link-project`, `/unlink-project`, `/update-project`, `/gather-context`, `/status`, `/daily-digest`, `/explain`, `/team-review`, `/todo`
- Incremental context gathering via `last_gathered` timestamp
- Background auto-refresh loop (silent, hourly)
- Resource auto-fetch from shared URLs with source-of-truth updates
- Session notes, plans, and per-project preferences
- Agent routing by task type (code changes → Earl, reviews → Steve + Debug Bot 500, plans → Earl + Steve, project questions → Pat)
