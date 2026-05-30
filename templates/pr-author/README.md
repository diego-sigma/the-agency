# PR Author profiles

Per-repo profiles consumed by **Parker** (the PR specialist persona — `templates/personas/parker.md`) when drafting PR descriptions and pre-flighting diffs.

Each profile is a markdown file named after the short repo name (the last segment of `<org>/<repo>`):

```
templates/pr-author/
  slate.md        # for sigmacomputing/slate
  mono-node.md    # for sigmacomputing/mono-node
  <repo>.md       # add more as needed
```

## Profile structure

Every profile has two top-level sections:

### 1. PR description style

The "house style" Parker mimics when drafting a description. Should include:

- **Typical structure**: section headings in order of frequency (e.g., `## Summary`, `## Test plan`, `## Screenshots`, `## Risk`).
- **Length**: median word count for descriptions, range, what "long" vs "short" looks like in this repo.
- **Ticket links**: format (e.g. `SIG-XXXXX`), frequency.
- **Code blocks / screenshots / videos**: when and how they appear.
- **Reviewer mentions / cc lists**: convention for tagging.
- **Labels**: commonly applied labels and their meanings.
- **Anti-patterns**: things to avoid.
- **Skeleton**: a fill-in-the-blanks template Parker can clone.

### 2. Best-practice critiques

A list of recurring critique patterns reviewers leave in this repo, each with:

- **Theme name** (e.g. "Missing tests", "Feature flag wrapping").
- **What reviewers typically say** (1–2 representative quotes).
- **How to detect it in a diff** (file glob, language feature, code pattern).
- **Severity** Parker should assign when found (block PR / flag for reviewer / nit).

Patterns appearing ≥3 times across the analyzed PR sample qualify. Ranked by frequency.

## Refreshing a profile

Each profile has a sibling manifest `<repo>.analyzed.json` that records exactly which PRs were sampled, so refreshes can be **incremental** instead of repeating the same work.

### Manifest format (`<repo>.analyzed.json`)

```json
{
  "repo": "sigmacomputing/slate",
  "generated_at": "2026-05-29T20:00:00Z",
  "methodology": {
    "description_sample": "500 most recently merged PRs ...",
    "comment_sample": "Top 100 by (reviewThreads + comments) ..."
  },
  "description_sample": {
    "count": 500,
    "lowest_pr_number": 63530,
    "highest_pr_number": 64932,
    "newest_merged_at": "...",       // mono-node only — slate manifest is by PR number
    "pr_numbers": [63530, 63531, ...]
  },
  "comment_sample": {
    "count": 100,
    "pr_numbers": [63552, 63738, ...]
  }
}
```

The manifest is the source of truth for "what's already in the profile". Hand-edit it only to remove PRs (e.g. you discover a sample was contaminated by a botched force-push); don't hand-edit new PRs in — let the refresh do it.

### Incremental refresh workflow

When you ask Claude to "refresh the slate profile":

1. Read the manifest's `highest_pr_number` (or `newest_merged_at` if present). That's the cursor.
2. Fetch PRs merged **after** the cursor (`gh pr list --search "merged:>YYYY-MM-DD"` or `--state merged` then filter by number > cursor).
3. Re-run the description-style and best-practice analyses on the new PRs (typically far fewer than 500).
4. Merge findings into the existing profile — update counts in the "raw counts" section, add new themes if any cleared the ≥3-PR threshold, decay old ones if they no longer show up.
5. Update the manifest: extend `pr_numbers`, bump `highest_pr_number` / `newest_merged_at`, set a fresh `generated_at`.

### Full re-analysis (when to do it)

Re-do the full 500-PR sample when:

- The original sample window is >6 months old and the codebase has shifted significantly.
- A major tooling or process change (new test framework, new lint rule, new PR template) makes the old best-practice critiques stale.
- You want to broaden the comment sample (e.g. top 200 by review activity instead of top 100).

Hand-edits to the profile are honored. The manifest is regenerated cleanly each run, so hand-edits there will be overwritten.
