---
name: daily-digest
description: Pat produces a short daily summary of what changed across all sources
---

# Daily Digest

## Trigger

User says "daily digest for <project>", "what happened today on <project>", or "catch me up on <project>".

## Steps

### 1. Resolve the project

- Read vault path from `.the-agency-config`
- Read `<vault>/projects/<project>/config.md` to get sources

### 2. Gather fresh data

Run a context gather first (this writes to the live log and triggers compaction of older tiers).

### 3. Read tiered context

- Read today's `knowledge/live/YYYY-MM-DD.md` for full detail of today's activity
- Read yesterday's `knowledge/daily/` summary for comparison (what changed since yesterday)

### 4. Spawn Pat for synthesis

Spawn a subagent with:
- **Persona**: read `team/pat.md`
- **Context**: wiki.md + wiki/activity.md + wiki/preferences.md + today's live data + yesterday's daily summary
- **Task**: "You are Pat. Write a daily digest for this project. Keep it short — this should take under 2 minutes to read. Format:

```
## Daily Digest: <project> — YYYY-MM-DD

### What happened
- (bullet points, most important first)

### What needs attention
- (blockers, stale PRs, unanswered questions)

### Coming up
- (what's expected tomorrow based on current state)
```
"

### 5. Present

Show the digest to the user.
