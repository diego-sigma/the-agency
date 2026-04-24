---
name: status
description: Pat synthesizes a project status report from the wiki
---

# Status

## Trigger

User says "what's the status of <project>", "status for <project>", or "how's <project> going".

## Steps

### 1. Resolve the project

- Read vault path from `.the-agency-config`
- Read `<vault>/projects/<project>/wiki.md` and `<vault>/projects/<project>/wiki/activity.md`
- If `wiki/activity.md`'s `Last updated` timestamp is older than 1 day, suggest running `gather context for <project>` first

### 2. Spawn Pat

Spawn a subagent with:
- **Persona**: read `team/pat.md`
- **Context**: wiki.md + wiki/activity.md + wiki/preferences.md (plus wiki/team.md if relevant)
- **Task**: "You are Pat. Give a status report for this project based on the wiki. Follow your standard reporting format: headline, workstreams, blockers, risks, action items."

### 3. Present the report

Show Pat's status report to the user. Label it clearly as Pat's assessment.

If Pat identifies gaps in the wiki (e.g., "I don't have recent Slack data"), note that and suggest a context gather.
