---
name: earl-learn
description: Mine the user's merged PRs in a target repo for accepted review-comment patterns and write the result to <vault>/earl-lessons/<repo>.md. Bootstraps on first run; incremental refresh thereafter (uses the sibling .analyzed.json manifest as cursor). Earl reads the lessons file whenever he's spawned on a task touching that repo.
---

# Earl Learns

## Trigger

User says `/earl-learn`, `/earl-learn <repo>`, "refresh Earl's lessons", "mine review comments for Earl". Optional argument: a repo short name (e.g. `slate`, `mono-node`); if omitted, refresh every repo that already has a lessons file under `<vault>/earl-lessons/`.

## Steps

### 1. Resolve scope

- Read vault path from the `vault=` line of `~/.claude/the-agency-config`.
- Get the user's GitHub login: `gh api user --jq .login`. This is the author filter (only mine the user's own PRs — reviews on someone else's PRs aren't Earl's mistakes).
- Determine the target repo(s):
  - If a `<repo>` argument was given, use it (resolve to `sigmacomputing/<repo>` for known short names).
  - Else, list every `<vault>/earl-lessons/*.md` and refresh each (skip the README if any).
  - If neither, ask the user which repo to mine.

### 2. Read the manifest (cursor for incremental refresh)

For each repo:

- Look at `<vault>/earl-lessons/<repo>.analyzed.json`. If it exists, read `newest_merged_at` and `pr_numbers`.
- If it doesn't exist, this is a cold start — proceed with no cursor.

### 3. List candidate PRs

**Important gotcha:** `gh pr list --author X --search "merged:>=..."` causes `--search` to override `--author` and returns *every* PR matching the search across the repo. Always put the author filter INSIDE the search query, OR use `--author` alone and filter by date client-side.

Prefer this single-query form:

```
gh pr list --repo sigmacomputing/<repo> \
  --state merged \
  --search "author:<user-login> merged:>=<cursor-or-2026-01-01>" \
  --limit 500 \
  --json number,title,mergedAt,body,reviewDecision,comments
```

Filter the results client-side:
- Drop PRs whose number is already in the manifest's `pr_numbers` (defense-in-depth dedup).
- Drop PRs with `comments.totalCount == 0` (no review feedback to mine).
- Verify each result's `author.login == <user-login>` — belt-and-suspenders in case the search syntax shifts.

If the candidate list is empty, tell the user "No new merged PRs to mine for <repo>" and skip to step 7.

### 4. Pull review threads via GraphQL

For each candidate PR, fetch resolved-thread state from the GraphQL API:

```
gh api graphql -f query='
  query($owner:String!,$name:String!,$num:Int!){
    repository(owner:$owner,name:$name){
      pullRequest(number:$num){
        reviewThreads(first:100){
          nodes{
            isResolved
            comments(first:20){
              nodes{ author{login} body path line }
            }
          }
        }
      }
    }
  }
' -F owner=sigmacomputing -F name=<repo> -F num=<num>
```

### 5. Identify "accepted" threads

A thread is **accepted** if all of:

1. Opening comment author is NOT the user (so it's a reviewer's flag, not the user's own note).
2. `isResolved == true`.
3. No user reply in the thread contains pushback phrasing (case-insensitive match against: "won't fix", "out of scope", "follow-up", "followup", "leaving as is", "leaving as-is", "not in this pr", "intentional", "by design").

(Criterion 4 from the original spec — "a commit after the thread opened" — is optional; skip it for cost reasons unless you already have the commit timestamps loaded.)

Track each accepted thread as `{pr, file, line, opening_comment, reviewer}`.

### 6. Cluster, merge, write

- Cluster accepted threads into **themes**. Each theme: a short name, "what Earl should do next time" (imperative), why reviewers care, one representative quote (anonymized — strip `@-mentions`), example PR numbers, and a "detect during diff review" pattern.
- Drop themes with fewer than 3 distinct PRs.
- **If a lessons file already exists**: merge new themes with existing ones. A theme matches an existing one if its detection pattern overlaps substantially. Merge by: appending new PR numbers to "Example PRs", bumping the count, and updating the quote if the new one is clearer. Add genuinely new themes at the end (or in frequency order). Keep the file capped at ~15 themes — if a theme has slipped to fewer than 3 PRs over the lifetime, drop it (with a one-line "retired YYYY-MM-DD" comment so the user knows).
- **If the file doesn't exist**: write a fresh one. Header template:

```markdown
# Earl lessons — sigmacomputing/<repo>

*Mined from <user>'s merged PRs in sigmacomputing/<repo> from 2026-01-01 onward. Accepted-comment criteria: thread is resolved AND no pushback reply.*

## Stats

- Last refreshed: <ISO date>
- PRs analyzed: <total>
- Accepted threads: <total>
- Themes: <count>

## Themes

### 1. <theme name> (<X> PRs)

**What to do next time:** ...

**Why reviewers care:** ...

**Representative comment:**
> ...

**Example PRs:** #1234, #5678, #9012

**Detect during diff review:** ...
```

### 7. Update the manifest

Write `<vault>/earl-lessons/<repo>.analyzed.json`:

```json
{
  "repo": "sigmacomputing/<repo>",
  "generated_at": "<ISO timestamp>",
  "user_login": "<github username>",
  "since": "2026-01-01",
  "pr_numbers": [<all PR numbers ever analyzed, including this run>],
  "newest_merged_at": "<merged_at of the newest PR in this run, or unchanged from prior manifest if no new PRs>",
  "accepted_thread_count": <total across all runs>,
  "themes_count": <current theme count in the lessons file>
}
```

The `pr_numbers` field is the authoritative dedup list — extend it, don't overwrite. `newest_merged_at` is the cursor used by step 3's `--search merged:>=` filter on the next run.

### 8. Report

Tell the user briefly:

```
Earl's slate lessons refreshed.
  Scanned: 12 new PRs (3 already analyzed, skipped)
  New accepted threads: 8
  Themes: +1 added ("avoid try/catch around RAC effects"), 2 reinforced (PR count bumped)
  File: <vault>/earl-lessons/slate.md
```

## Notes

- This skill mines **only the user's own PRs**. Reviews on someone else's PRs aren't Earl's mistakes; they belong elsewhere.
- The bootstrap (no manifest) can be slow if the user has many merged PRs this year. The incremental path (manifest cursor) is cheap and should be the default mode after the first run.
- Lessons are **repo-scoped, not project-scoped**. Earl reads `<vault>/earl-lessons/<repo>.md` whenever he's spawned on a task that touches that repo, regardless of which agency project is linked (see `CLAUDE.md` "How to use personas" step 5).
- To reset a repo's lessons, delete both `<repo>.md` and `<repo>.analyzed.json`; the next `/earl-learn` will rebuild from scratch.
