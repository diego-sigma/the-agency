---
name: explain
description: Steve explains a part of the codebase in simple, approachable terms
---

# Explain

## Trigger

User says "explain <thing> in <project>", "how does <thing> work in <project>", or "walk me through <thing>".

## Steps

### 1. Resolve the project

- Read vault path from `.the-agency-config`
- Read `<vault>/projects/<project>/wiki.md`, `wiki/activity.md`, `wiki/preferences.md`, and `wiki/architecture.md` for project state
- Read `<vault>/projects/<project>/config.md` to identify the repo(s)

### 2. Gather the relevant code

Before spawning Steve, gather the code he'll need to explain:

- If the user named a specific file or function, read it directly
- If the user named a concept (e.g., "the auth flow", "how webhooks work"), use Grep and Glob to find the relevant files across the configured repo(s)
- Collect enough surrounding code for Steve to give a complete explanation — entry points, key functions, data flow

### 3. Spawn Steve

Spawn a subagent with:
- **Persona**: read `team/steve.md`
- **Context**: wiki.md + wiki/activity.md + wiki/preferences.md + wiki/architecture.md + the gathered code
- **Task**: "You are Steve. Explain <thing> to the user. Remember:
  - Start with the big picture — what does this do and why does it exist?
  - Use analogies and simple language
  - Walk through the flow step by step
  - Point out the important design decisions and why they were made
  - If there are gotchas or non-obvious behavior, highlight them
  - Reference specific files and line numbers so the user can follow along
  - Keep it conversational — you're explaining to a colleague, not writing documentation"

### 4. Present

Show Steve's explanation to the user, labeled as Steve's walkthrough.

If Steve identifies related areas the user might want to understand next, mention them at the end.
