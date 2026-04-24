---
name: pause
description: Pauses automatic context gathering for a project. The background loop keeps running but each gather is a no-op until /gather-context is invoked manually.
---

# Pause

## Trigger

User says "/pause", "pause context gathering", or "pause gathers for <project>".

## Steps

### 1. Resolve the project

- If an argument is provided, use it as the project name
- Otherwise, use the linked project (from `.the-agency-sessions/<CLAUDE_SESSION_ID>`)
- If neither, list available projects and ask

### 2. Set the paused flag

- Read vault path from `.the-agency-config`
- Open `<vault>/projects/<project>/config.md`
- In the `## State` section, add or set `gathering_paused: true`
- Preserve all other state fields (`last_gathered`, etc.)

### 3. Confirm

Tell the user:

```
Gathering paused for <project>.

The background loop will continue firing, but each automatic gather will be a no-op until you run /gather-context manually. The wiki and knowledge tiers will not be modified.

Run /gather-context to resume — it will clear the paused flag and run a catch-up gather.
```

## Notes

- This is project-scoped, not session-scoped or global. Each project has its own pause state.
- The flag is persistent — it survives session restarts. Pausing once means it stays paused until `/gather-context` is invoked manually.
- To stop the background loop entirely, use `/unlink-project`.
