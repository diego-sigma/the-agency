---
name: pulse
description: Triages the latest tech news/developments relevant to the user's vault projects. Searches Hacker News, Anthropic, MCP GitHub org, ArXiv, GitHub trending, Reddit, TLDR, and (optionally) X. Cross-references stories across sources, prioritizes by upvotes/likes/stars, presents each as a paragraph summary with a 0–3 rating prompt, and learns from verdicts via decaying keyword/source weights.
---

# Pulse

## Trigger

User says `/pulse`, "what's new in tech", "catch me up on tech", or "any interesting tech news?". Optional argument `N` overrides the default of 10 items (e.g. `/pulse 20`).

## Steps

### 1. Bootstrap (idempotent)

- Read vault path from the `vault=` line of `~/.claude/the-agency-config`.
- Ensure these directories exist (create any that are missing):
  - `<vault>/pulse/`
  - `<vault>/pulse/inbox/`
  - `<vault>/pulse/rated/`
- If `<vault>/pulse/interests.md` is missing, copy it from `<repo>/templates/pulse/interests.md` (the `repo=` path in `~/.claude/the-agency-config`).
- If `<vault>/pulse/x-accounts.txt` is missing, copy `<repo>/templates/pulse/x-accounts.txt.example` to `<vault>/pulse/x-accounts.txt`.

### 2. Apply weekly decay

- Compute `weeks = (now - mtime(interests.md)) / 7 days`, rounded to one decimal.
- Multiply every weight in `interests.md` (topic AND source) by `0.9 ^ weeks`. Round topic weights to nearest integer, source weights to one decimal.
- Touch `interests.md` (rewrite it) so future runs anchor on this run's time. Skip the rewrite if `weeks < 0.5` (no meaningful decay yet).

### 3. Build the topic query set

Collect project seeds:

- List `<vault>/projects/*/` directories.
- **Exclude any project whose directory name begins with `oncall`** — the user has explicitly opted these out.
- For each remaining project, read `config.md` and extract: Slack channel names (drop the `#`), repo names (drop the `org/` prefix), Jira project keys, and Jira epic IDs/titles. Tokenize each into 1–3 word phrases.

Combine with learned interests:

- Read `<vault>/pulse/interests.md` `## Topic weights`. These are signed integers.
- For each project-seed phrase that isn't already in the interests file, treat its weight as `+3` (matching a confirmed "interested" verdict).
- Drop any keyword whose effective weight is `≤ −3`.
- Sort by weight descending and keep the top **15 keywords** as the active query set.

### 4. Query each enabled source (parallel where possible)

For each source whose weight in `interests.md` is `> 0`, query for matches against the active keyword set. Capture engagement metrics where available. Skip a source silently if all its requests fail.

| Source | Approach | Engagement signal |
|---|---|---|
| `hackernews` | `https://hn.algolia.com/api/v1/search?query=<term>&tags=story&numericFilters=created_at_i>=<7 days ago>` per top-5 keyword. Top-3 hits each. | `points`, `num_comments` |
| `anthropic` | WebFetch `https://www.anthropic.com/news`, parse post links, keep those dated within the last 14 days. Loose keyword filter (Claude / MCP / API). | editorial — flag `editorial: true` |
| `mcp-org` | `gh api orgs/modelcontextprotocol/events --paginate=false` filter to ReleaseEvent + merged PullRequestEvent in the last 14 days. Title = release name or PR title; URL = HTML URL. | parent repo stars |
| `arxiv` | `https://export.arxiv.org/api/query?search_query=(cat:cs.AI+OR+cat:cs.CL)+AND+(abs:<keyword1>+OR+abs:<keyword2>+...)&sortBy=submittedDate&max_results=10` | editorial — flag `editorial: true` |
| `github-trending` | WebFetch `https://github.com/trending?since=weekly&topic=<topic>` for the top 5 topic-matched keywords. Parse the repo list. | trending-period stars |
| `reddit` | For each enabled sub (`r/ClaudeAI`, `r/LocalLLaMA`, `r/MachineLearning`, `r/dataengineering`), WebFetch `https://www.reddit.com/r/<sub>/top.json?t=week&limit=10`. Keep posts where the title or selftext matches any active keyword. | `score`, `num_comments` |
| `tldr` | WebFetch `https://tldr.tech/ai/<YYYY-MM-DD>` for the last 3 weekday issues. Parse out the linked stories. | flag `tldr_curated: true` |
| `x` | Skip if `x: 0.0` in interests OR `<vault>/pulse/x-accounts.txt` is empty/all-commented. Otherwise, for each non-comment handle, WebFetch `https://nitter.net/<handle>` with fallbacks `https://nitter.poast.org/<handle>` and `https://xcancel.com/<handle>`. Keep posts ≤7 days old; drop replies. | `like_count`, `retweet_count` if exposed |

For every candidate item, capture: `url`, `title`, `snippet` (1-2 sentences from the source), `source` name, `posted_at`, engagement metrics, and any `@handle` references found in the title/snippet.

### 5. Cross-platform aggregation

Group candidates by canonical URL:

1. **Normalize** each URL: lowercase the host, strip trailing `/`, drop UTM/tracking params (`utm_*`, `fbclid`, `gclid`, `ref`, `source`), force `https://`.
2. **Resolve aggregator links**: HN, Reddit, and TLDR usually link to an external article. For each candidate from these three sources, follow its "outbound link" (the actual story URL, not the aggregator's discussion page) and use that as `canonical_url`. The Algolia HN API exposes `url` (outbound) and `story_id` (discussion); use `url`. Reddit JSON exposes `url` similarly.
3. **Group** by `canonical_url`. Items without a resolvable canonical fall back to their own `url`.
4. **Merge** each group into one record:
   - `sources: [list of every source name in the group]`
   - `cross_platform_count: len(sources)`
   - Merge engagement metrics into one `engagement` object.
   - Pick the highest-engagement member's title + snippet as the canonical title/snippet.

### 6. Score and rank

For each merged item:

```
recency      = exp(-age_days / 3)                              # ~0.5 at 2 days, ~0.1 at 7 days
topic_match  = sum of weight for each topic_tag matching an interests keyword (signed)
source_score = sum of source_weight for each source in `sources`
engagement   = log10(1 + total_upvotes_likes_stars_comments)    # ~2 for 100, ~3 for 1k
cross_mult   = 1 + 0.5 * (cross_platform_count - 1)             # 1× → 1.5× → 2× → ...

score = recency × max(topic_match, 1) × source_score × (1 + engagement) × cross_mult
```

Drop items with `score < 1.0`.

**Dedupe** against existing items: drop any candidate whose `url` or `canonical_url` already appears in any file in `<vault>/pulse/inbox/` or `<vault>/pulse/rated/`.

Keep the top **N** (default 10; honor the user's argument if provided).

### 7. Write candidates to inbox

For each kept candidate, write `<vault>/pulse/inbox/YYYY-MM-DD-<slug>.md` where `<slug>` is a short kebab-case derivative of the title (max 60 chars).

```markdown
---
url: <canonical_url or url>
sources: [hackernews, reddit, tldr]
fetched: 2026-MM-DD
topic_tags: [mcp, oauth, claude]
engagement: {hn_points: 412, reddit_score: 187, tldr_curated: true}
score: 14.2
cross_platform_count: 3
verdict: pending
opened_source: false
mentioned_handles: ["@AnthropicAI", "@simonw"]
---

# <headline>

<paragraph summary: 4–6 sentences, ~80–120 words>

Source: <url>
```

The **paragraph summary** is written by you (the skill executor) using the title + snippet from each source. Cover, in this order:

1. **What is this?** (one sentence — concrete, specific)
2. **Why does it matter for the user's projects?** Call out the linked project by name if there's an obvious tie (e.g. "Relevant to mcp-server's SIG-93133 OAuth epic"). If it's tangential, say so explicitly.
3. **Notable claim, result, or technical detail** (1–2 sentences — what's new, what changed, what's the headline benchmark).
4. **Caveat** if applicable: paywalled, preprint, opinion piece, vendor blog, etc.

Extract `@handle` mentions from the title + snippet + summary (regex `@[A-Za-z0-9_]{1,15}`, deduped per item) into `mentioned_handles`.

### 8. Interactive triage loop

Sort `<vault>/pulse/inbox/` by `score` descending. For each item, present:

```
[<i>/<N>]  score <score> · <count> sources (<source-abbrevs>) · <top-engagement> · <age> ago
"<headline>"

<paragraph summary>

Source: <url>
```

Then call `AskUserQuestion` with a single-select:

- **3 — love it**
- **2 — interested**
- **1 — meh**
- **0 — no thanks**
- **Open source** (echo URL, loop with same item — do not advance)
- **Stop** (end loop, leave remaining items in `inbox/`)

When the user picks 0–3:

- Set the item's `verdict` to the integer.
- Move the file from `<vault>/pulse/inbox/` to `<vault>/pulse/rated/`.
- Apply weight deltas per step 9.
- Advance to the next item.

When the user picks **Open source**: print the URL on its own line so it's clickable in the terminal; set `opened_source: true` in the item's frontmatter; do not advance — re-present the same item with the question.

When the user picks **Stop**: end the loop; remaining inbox items are kept for next time.

### 9. Weight deltas (the learning step)

For each item the user rated this run, update `<vault>/pulse/interests.md`:

| Verdict | Topic weight delta (per tag) | Source weight delta (per source the item appeared in) |
|---|---|---|
| 3 | `+3` | `+0.15` |
| 2 | `+1` | `+0.05` |
| 1 | `−1` | `0` |
| 0 | `−3` | `−0.05` |

Clamp topic weights to `[−5, +10]` and source weights to `[0.1, 3.0]`.

Maintain a rolling `## Recent verdicts (last 30)` section in `interests.md` — append one line per verdict (oldest entry rotated out when at 30 entries):

```
- 2026-MM-DD: 3 · "Anthropic releases MCP 1.2 with OAuth 2.1" · tags: [mcp, oauth]
```

### 10. X-accounts auto-grow

After the triage loop:

- Across **all** items this run (rated and remaining-in-inbox), aggregate `mentioned_handles` and count occurrences per handle.
- For each handle that appears in **≥3 distinct items** AND is not already present in `<vault>/pulse/x-accounts.txt` (active or commented), append it to the file under a managed heading:

  ```
  ## Auto-added
  <handle>  # appeared in N items, 2026-MM-DD
  ```

  If the `## Auto-added` section already exists, append to it; otherwise, add the section at the bottom of the file.

- If `x: 0.0` in interests (X source disabled), **skip** auto-grow — the user hasn't opted in.

If at least one handle was added, surface one line at the end of the run:

```
Added 2 handle(s) to x-accounts.txt — @AnthropicAI (5 items), @karpathy (3 items). Set `x: 1.0` in interests.md to enable the X source.
```

### 11. Cleanup + final summary

- Prune `<vault>/pulse/rated/` items whose date in the filename is older than 60 days — their preferences are already baked into `interests.md`.
- Print a final summary:

  ```
  Triaged 7 of 10. Verdicts: 3×3, 2×2, 1×1, 1×0. 3 left in inbox.
  ```

  If items remain in `inbox/`, mention that re-running `/pulse` will continue from where you stopped.

## Notes

- The skill is **global**: it does not require a linked project. It reads from `<vault>/projects/*/` to derive topic seeds, but does not write to project vaults.
- Cross-platform aggregation deliberately favors stories with broad signal. A story on HN with 1000 points and an academic angle on ArXiv with the same author counts as 2 sources.
- Engagement is `log10` so a 10k-upvote post isn't 100× a 100-upvote post — it's about 2× — which prevents popular but off-topic items from dominating.
- The 0-vs-1 vs 2-vs-3 spread is intentional: 0 carries a strong negative signal because you actively don't want this; 1 is a mild "not interesting today" without poisoning the topic permanently.
- Nitter mirrors come and go. Treat X as best-effort. If all three mirrors fail for every handle in a single run, surface one quiet line ("X source unavailable — all Nitter mirrors failed") and continue.
