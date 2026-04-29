---
name: team-review
description: Runs a multi-agent PR review pipeline using the project's team personas
---

# Team Review

## Trigger

User says "review PR #X for <project>", "team review PR #X", or similar.

## Steps

### 1. Resolve the project and PR

- Read vault path from `~/.claude/the-agency-config`
- Read `<vault>/projects/<project>/wiki.md`, `wiki/activity.md`, `wiki/preferences.md`, and `wiki/architecture.md`
- Fetch the PR diff: `gh pr diff <number> --repo <repo>` (repo from config.md)
- Fetch the PR description: `gh pr view <number> --repo <repo>`

### 2. Debug Bot 500 reviews (Code Reviewer)

Spawn a subagent with:
- **Persona**: read `team/debug-bot-500.md`
- **Context**: wiki.md + wiki/activity.md + wiki/preferences.md + wiki/architecture.md + PR description + PR diff
- **Task**: "Review this PR as Debug Bot 500. Focus on correctness, edge cases, security, and performance. Categorize findings by severity."

Debug Bot 500 writes its review. Save to `knowledge/github/pr-<id>-debug-bot-review.md`.

### 3. Steve reviews (Staff Engineer)

Spawn a subagent with:
- **Persona**: read `team/steve.md`
- **Context**: wiki.md + wiki/activity.md + wiki/preferences.md + wiki/architecture.md + PR description + PR diff + Debug Bot 500's review
- **Task**: "Review this PR as Steve. You have Debug Bot 500's findings. Focus on architecture, long-term implications, and anything the bot may have missed. Summarize the team's overall assessment."

Steve writes his review. Save to `knowledge/github/pr-<id>-steve-review.md`.

### 4. Present combined review

Show the user both reviews, clearly labeled by agent name:

```
## Debug Bot 500's Review (Code Reviewer)
...

## Steve's Review (Staff Engineer)
...
```

### 5. Ask about posting

Ask the user: "Want me to post this review to GitHub?" If yes, combine into a single review comment and post via `gh pr review`.
