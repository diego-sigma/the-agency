# `sigmacomputing/mono-node` — PR author profile

Built from the 500 most recently merged PRs (sample window ends 2026-05-29) plus reviewer/issue comments on the 100 most-discussed PRs from that window. 100/100 PR comment threads were fetched without error.

Raw counts cited inline are out of n=500 (descriptions) or n=100 (comment-thread sample) unless noted.

## 1. PR description style profile

### Canonical skeleton

mono-node has a single dominant PR template — three H2 headings in fixed order:

```
## What is the purpose of this PR?
## What should reviewers focus on?
## How is this PR tested?

Resolves [SIG-XXXXX]
```

- 361/500 PRs use `## What is the purpose of this PR?` verbatim.
- 317/500 use `## What should reviewers focus on?`.
- 315/500 use `## How is this PR tested?`.
- 298/500 (59.6%) hit all three together — that's the "full template" rate.

There is a secondary short-form skeleton, used heavily by Claude Code / Cursor automations:

```
## Purpose
## How to Try
## Reviewer Focus
## Testing

🏗️ Generated for Sigma by Claude Code
```

- 85/500 use `## Purpose`, 74 `## How to Try`, 72 `## Reviewer Focus`, 76 `## Testing`.
- 272/500 bodies end with the `🏗️ Generated for Sigma by …` signature line; 207 say "Claude Code", 63 say "Cursor".
- 21/500 wrap the body in `<!-- CURSOR_AGENT_PR_BODY_BEGIN/END -->` markers (Cursor agent output).

Other headings are long-tail and rare: `## Approach` (8), `## Stack` / `## The stack` (8 combined, used for stacked PRs), `## Test plan` (5), `## Summary` (4). The headings `## Risk` and `## Screenshots` essentially do not exist as section titles here.

### Length

Body word counts (n=500):

|            | All | Human-authored (no `🏗️`) | Bot-generated (`🏗️`) |
|------------|-----|---------------------------|-----------------------|
| count      | 500 | 228                       | 272                   |
| P25        | 89  | 51                        | 152                   |
| Median     | 159 | 91                        | 229                   |
| P75        | 257 | 147                       | 325                   |
| Max        | 976 | —                         | —                     |
| Empty (<2) | 4   | 4                         | 0                     |
| <30 words  | 40  | mostly human              | ~0                    |

So: "short" PR is ~50 words (one paragraph + Resolves footer); "median" is ~150 words; "long" is 300+. Bot-drafted bodies trend ~2.5× longer than human-drafted ones. Human-authored PRs frequently consist of a single sentence under each heading — terse is normal.

### Ticket links

- 265/500 bodies reference at least one `SIG-XXXXX` ticket; 122 unique tickets cited overall.
- 176/500 link explicitly to `sigmacomputing.atlassian.net/browse/SIG-...`.
- Zero Linear, very rare Confluence (1).
- The dominant footer is a literal Markdown reference-style link, typically last line:
  ```
  Resolves [SIG-XXXXX]
  ```
  with a corresponding `[SIG-XXXXX]: https://sigmacomputing.atlassian.net/browse/SIG-XXXXX?...` reference at the bottom. 178 PRs use this footer; 14 use the placeholder `Resolves N/A` when there's no ticket.
- Titles: 60/500 titles contain `[SIG-XXXXX]` as a prefix tag; 409/500 use *some* bracket prefix like `[fix]`, `[exports]`, `[search]`, `[mcp]`, `[API]`, `[maint]`, `[crypto]` (component or change-type). Title average length 60 chars, max 113. Conventional-commits style (`chore:`, `feat:`) is rare (~13 PRs).

### Code blocks, screenshots, video

- 32/500 PRs contain at least one fenced code block; total of ~80 fenced blocks across the corpus. Code blocks are mostly used for: example HTTP requests (`POST /v2/...`), example error messages, GraphQL/protobuf snippets, jest assertions, and diff/snippet illustrations.
- 35/500 bodies contain an `<img …>` tag, but the vast majority of those are Cursor's "Open in Web / Open in Cursor" buttons appended automatically. Genuine inline screenshots are very rare — `private-user-images` count = 0, only 17 use `user-attachments`. 27/500 mention the word "screenshot" in passing. **There is effectively no Loom / video / GIF culture in this repo.**
- Bullet lists with bolded key terms (`- **Tool-results migration**: …`) are the dominant body shape inside `## What is the purpose`.

### Reviewer mentions, cc lists, labels

- 61/500 bodies contain an `@-mention`. No PR uses a `cc:` block — review requests are done via GitHub's reviewers UI, not the body.
- Labels are sparse: only ~40 labels applied across 500 PRs. Most common: `crossover-migration` (6), `export / scheduling` (5), `App Writeback` (5), `reporting` (4), `mergequeue` (4), `type:BugFix` (2), `risk:M` (2), `complexity:M` / `complexity:L` (1 each), `code-quality` (1). Labels are not load-bearing; they tag area and rarely change-type. Most PRs ship with zero labels.
- 492/500 PRs target `master`. The other 8 stack onto feature branches (`diego/...`, `claude/...`, `SIG-XXXXX-followup-...`, etc.). 23/500 bodies reference a stack (`📚 Part of a stack`, `## The stack`, `Stacked on #NNNNN`), so stacked-PR culture exists but is a clear minority.

### Cross-repo / external links

- 30/500 link to `github.com/sigmacomputing/slate` (mono-node ↔ slate coupling is constantly being managed in descriptions).
- 14/500 link to Slack threads as Slack-link rationale (`https://sigmacomputing.slack.com/...`).
- 2/500 link to mono-go.
- Confluence/Wiki references are rare.

### Anti-patterns (things to avoid)

- **No** dedicated `## Summary` / `## Test plan` / `## Risk` / `## Screenshots` section headings. The "GitHub-default" PR template is *not* the house style. Use the Sigma template above.
- **No** Loom / video / animated GIF embedding convention.
- **No** `cc: @x @y @z` lists.
- **No** conventional-commit prefixes on titles (chore/feat/fix). Use `[bracket-tag]` prefixes instead.
- Author signatures: only AI-generated PRs use `🏗️ Generated for Sigma by …`. A human-authored PR should *not* fake this. Cursor agent additionally wraps the body with `CURSOR_AGENT_PR_BODY` HTML comments — also don't add these unless Cursor really wrote it.
- Bodies under 30 words are accepted (40/500) but generally only for trivial fixes (typo / one-line gate flip / dep bump). Anything with logic changes should fill all three sections.
- Inline `<!-- comment placeholder -->` snippets from the raw template (`<!-- Explain the intended outcome(s)… -->`) are commonly left in human-authored PRs (71/500 contain `<!--`) — not strictly an anti-pattern, but cleaner PRs strip them.

### House-style skeleton (fill-in-the-blanks)

For a typical change, write:

```markdown
## What is the purpose of this PR?

<1–3 sentences explaining the user-visible or system-level outcome. If a Slack
thread / trace / staging link motivated this, link it here. For multi-part
changes, follow with a bulleted list of `- **<change-name>**: <one-sentence
description>` items.>

## What should reviewers focus on?

<Bulleted list of decisions you actively want feedback on: gate placement,
naming, scope boundaries, type-shape choices, follow-up split, etc. One bullet
per concern. Mention specifically what's *out of scope*.>

## How is this PR tested?

<Bulleted list of automated tests added or updated, with file paths. Mention
yarn tsc / lint status if it might be non-obvious. Note any manual /
post-merge validation (deploy + Datadog check, etc.).>

Resolves [SIG-XXXXX]

[SIG-XXXXX]: https://sigmacomputing.atlassian.net/browse/SIG-XXXXX
```

For titles: `[<component>] <imperative, lowercase, ≤80 chars>` is the modal form. `[SIG-XXXXX]` prefix in the title is also accepted (60 PRs).

## 2. Best-practice critiques mined from review comments

Themes are ranked by the number of *distinct PRs* (out of 100 sampled) in which the pattern appears in a review or issue comment. Patterns under 3 PRs were dropped.

### 1. Slate/crossover drift — "this is duplicated in slate, where does it live?" (44 PRs)

What reviewers say:
> "changes here looks same as in slate, is there anyway to have the changes in **one place**? May be some package?"
> "we have these types identically defined in slate as well right? Agree … we should just consolidate the types in entities"
> "yea I think you can put a shared function in entities, and that way we can also add specific tests around this function instead of just relying on the e2e"

Detect in a diff:
- New code in `crossover/src/svc/` or `crossover/src/types/` that *looks like* code in `slate/`. Especially: parsers, serializers, type aliases, codecs.
- Type definitions added to `crossover/src/types/*.ts` or `lib/crossover-types/*.ts` that shadow a slate type.
- Any logic that re-implements a slate utility instead of importing from `@mononode/entities` / shared packages.
- Trigger: PR title contains both crossover and slate references, or PR description mentions a parallel slate PR.

Severity: **Flag for reviewer** (block PR if the duplication is large or affects a public type).

### 2. GraphQL schema deletion / slate-pin breakage (60 PRs — high signal, partially inflated)

What reviewers (often the schema-deletion bot itself) say:
> "Don't delete a GraphQL field directly — Slate clients pin to specific mono-node SHAs. Mark it @deprecated, then in a separate PR ship the Slate change… 4-week soak, traffic verification via api.request.count, and schema-deletion bot acknowledgement happen operator-side."
> "We've changed the shape of this so that it now includes agentKind, does GraphQL just drop it or does it error?"
> "⚠️ GraphQL Schema Deletion Warning … This PR contains N line deletion(s) in `crossover-graphql/schema.graphql`."

Detect in a diff:
- Deletions in `crossover-graphql/schema.graphql` or any `*.graphql` file. Even nullable→non-nullable shape changes count.
- Changes to `crossover-graphql/src/graphql.generated.ts` (built artifact — usually shouldn't be in the diff).
- Protobuf schema changes (`*.proto`) without explicit migration plan.
- Field renames in any type that surfaces to GraphQL resolvers (`crossover/src/schema/**/*.ts`).
- Companion concern: bumping mono-node SHA in slate; the PR description should call out the soak / sequencing.

Severity: **Block PR** (deletion or shape change to a GraphQL field).

### 3. Permissions & auth-context gating (50 PRs)

What reviewers say:
> "what are the permission gates for this endpoint? is it possible that someone wouldn't have access to the SQL in the element but does have access to the workbook?"
> "Do we expect this to ever be called by a non human like in embedding or scheduled tasks etc? `mkServiceContextWithHumanUserDelegateAuthContext` throws if `authCtx.contextType === 'delegate'` which could be problematic"
> "let's make this error message a bit more actionable. Maybe the message can be conditional on if the auth context user is an admin."

Detect in a diff:
- New handler in `crossover/src/public/v{2,3alpha}/**/handlers.ts`, new GraphQL resolver in `crossover/src/schema/`, or new public REST route without a visible `await ensureHasInodeGrant(...)` / `ensureCan...` / `requirePermission` call.
- New code paths reachable from embeds, scheduled tasks, or service contexts (`mkServiceContext...`) that throw on non-human contexts.
- Org-level admin settings being read without a tenancy check (`org.isAdmin`, `authContext.userId`).

Severity: **Block PR**.

### 4. Pagination / unbounded queries / mysql timeouts (20 PRs)

What reviewers say:
> "I mean we shouldn't create a function that's not bounded and likely cause mySQL to timeout when the result is too large."
> "can you update this function to take only one ruleId? with list of ids, we cannot guarantee the number is bounded"
> "We can either change this to paginated version or set a limit on the number of assignments"
> "can you update to follow this example? we do a `lodash.chunk`"

Detect in a diff:
- `.query(ctx).where(...)` / `.delete()` / `.update()` on a table without a `LIMIT` and without `lodash.chunk` / `do { } while (cursor)`.
- New batch helpers that accept `ids: UUID[]` parameters with no documented upper bound.
- DataLoader batchers without a 1:1 key-result mapping.
- Background tasks that fan out over an org's data without a per-page cap.

Severity: **Block PR** (unbounded query against a large table) or **Flag for reviewer** (bounded list with no documented cap).

### 5. Extract / share / push validation higher (33 PRs combined)

What reviewers say:
> "if handler for workbooks is similar can we modify workbook's handler so both report and (future) data model endpoints can use it"
> "I think this validation should sit at a higher layer, not exclusive to workbook cloud exports"
> "perhaps an extracted validation method. Fine for a followup, but … so we don't end up in the same place we started"
> "can we create a helper type for { archivedPath: string[]; archivedInodeId: UUID_t }"

Detect in a diff:
- Endpoint handler bodies that look similar to a sibling handler (workbook ↔ report, dataset ↔ data model, …).
- Local helper types/functions that mirror existing exports from `lib/crossover-types` or `lib/entities`.
- Validation embedded inside a leaf handler when the same shape exists elsewhere — push to a route-level middleware or a shared helper.

Severity: **Flag for reviewer**.

### 6. Feature-flag hygiene (23 PRs)

What reviewers say:
> "should we have these changes behind a FF? Exports is a delicate area. We need control to enable/disable the changes"
> "do we want to just gate all these by `agentSourceSwap` gate and yeet the connector specific ones?"
> "Should we be adding new mentions of this flag? it's fully rolled out so doesn't feel like we need to"
> "might not be a necessary test? this flag is fully rolled out and we honestly should remove it pretty soon here."
> "comment feels extensive. feel like we should be adding a TODO or an automation reminder to actually delete these feature flags mentioned."

Detect in a diff:
- New behavior with no `isEnabled(`/`useFeature(`/`getFlag(`/`hasFeature(` guard, in code paths that touch user-facing data (exports, AI, public API).
- New code that adds a *new mention* of an already-launched flag (you may be reviving zombie gating).
- Long-tail flags referenced in code that have no removal TODO.
- `kill switch` / "stopgap" comments without an explicit follow-up issue.

Severity: **Flag for reviewer** (block if a delicate area like exports / public API has no FF).

### 7. Observability — traces, tags, metrics (31 PRs)

What reviewers say:
> "nit: how useful is this trace event? I feel like our tracing will already capture the `configV2` field in the task request itself"
> "Mark is the chart type. We only set `specOutcome.mark` on the 'unsupported-mark' reason… We tag it on the trace so we can see which mark Cortex picked that we're dropping."
> "[Security] traces can persist customer warehouse sample values and query text into observability/Langfuse → Remove raw `ddl`/`sql` trace tags and emit only bounded metadata"
> "Eventually we should probably write down how many rows total is in progress…"

Detect in a diff:
- New `trace.addTags({…})` / `span.setAttribute(…)` / `dogstatsd.increment(…)` calls. Check for: (a) duplicating a tag already on the parent span; (b) tagging raw customer data (SQL, DDL, sample rows, PII); (c) missing per-surface tags on cross-cutting code.
- New code path that's externally visible but emits no metric.
- Removal of a metric/trace tag that is part of a public dashboard.

Severity: **Block PR** (PII / raw customer data tagged on traces) — otherwise **Flag for reviewer**.

### 8. Error message & error class quality (24 PRs combined)

What reviewers say:
> "let's make this error message a bit more actionable. Maybe the message can be conditional on if the auth context user is an admin."
> "I don't really understand this format of error expecting. I feel like if the test name is 'throws internal' then we should check for a more specific error."
> "I'd prefer if we kept the error message more concise. This doesn't have to give advice it should just tell us where/what went wrong imo."
> "Tightened … to assert the error class as well, so the test name and assertion are aligned: `).rejects.toMatchObject({ name: 'Application#INTERNAL', … })`"

Detect in a diff:
- New `throw new Error(...)` without an `Application#` error class.
- Test that asserts on partial message substring instead of error name + structured fields.
- User-facing error strings that lack remediation guidance for the role most likely to see them.

Severity: **Flag for reviewer**.

### 9. API versioning / endpoint shape (20 PRs)

What reviewers say:
> "Unfortunately we can't just delete an endpoint :( Fortunately, `dbt_core_integration` is only enabled for ~15 orgs… I think we would keep this around and hide it"
> "Just to confirm, are we moving out of private beta?"
> "Hide the endpoint"
> "this now diverges from the workbook/data model equivalents (`POST /v2/workbooks/tag` and `POST /v2/dataModels/tag`)"

Detect in a diff:
- Deletion of a route in `crossover/src/public/v{2,3alpha}/`.
- New v2 endpoint that has no v3alpha counterpart (or vice-versa).
- Field renames on request/response shapes of an endpoint that's already public.
- New endpoint missing `hidden: true` / "private beta" gating in `operation_ids/*.ts`.

Severity: **Block PR** (route deletion or breaking-shape change to a public endpoint).

### 10. API documentation prose quality (especially Claude-written descriptions) (9 PRs)

What reviewers say:
> "claude is bad at writing. ```suggestion 'When `true`, include `parentSourceUrlId` for documents deployed from a parent organization. Only applies for tenant organizations, otherwise ignored. Defaults to `false`.'```"
> "i think we can be more concise here, the notes/scenarios repeat this info"
> "what does opaque mean in this context? is there an example format we can provide?"
> "maybe we can make the second sentence a bit simpler, like 'This is useful for exporting specific report pages, navigating large reports, or displaying specific pages in other applications'"

Detect in a diff:
- New entries in `crossover/src/public/v*/**/types.ts` `description:` fields.
- Long, multi-sentence API descriptions with repeated/scenario-style content.
- "Allows users to …" / "Enables …" boilerplate phrasing.

Severity: **Nit** (but reviewers care — clean these up before pushing).

### 11. Type drift / type-safety (13 PRs)

What reviewers say:
> "I think this type should be used everywhere in place of `archivedPath: string[] | null` and `archivedInodeId: UUID_t | null`"
> "can we changed this to {archivedInodeId, archivedPath } rather than two separate vars? we should expect both to be defined or the whole object to be null right?"
> "I'd be in favor of making a followup ticket to fix this interface by using branded types (eg `BrandedRpcService_t`) to force callers"
> "can you use `jest.MockedFunction<typeof publishInputTables>` ? I know its a test but still"
> "Could you use `Promise<AiDataStorage_t>` as the return type? That guards against type drift better"

Detect in a diff:
- Function params with multiple correlated optional/nullable fields that should be a discriminated union.
- New `as any` / `as unknown` / `// @ts-expect-error` (4 explicit `as any` mentions in sample).
- Return types declared as `Promise<any>` / `unknown` or inferred when the surrounding code uses branded types.
- Test mocks typed as `jest.fn()` instead of `jest.MockedFunction<typeof …>`.

Severity: **Flag for reviewer**.

### 12. Test missing / test weak (18 PRs)

What reviewers say:
> "I don't think the new test ensures that this change adds the behavior we want here"
> "Pls test against the expected string, it's more useful than something like `endsWith('\\n\\nwhat is ARR?')`. If this string ever changes, we want these tests to identify where there will be a breaking change."
> "to alleviate Diego's fears, can we have a test here that — sets mapping for org 1, sets mapping for org 2, clears mapping for org 1, checks org 1 is gone, checks org 2 is still here"

Detect in a diff:
- Logic change to a model / handler with no test addition in a matching `__tests__` folder.
- Tests that only assert on side-effect counts, not the resulting state.
- Tests that mock the SUT itself (mock the inner function it's testing).
- Prompt / string-template assertions that use `endsWith` / `toContain` instead of full-string equality.

Severity: **Block PR** (no test for logic change) — otherwise **Flag for reviewer**.

### 13. Scope concerns — broad deletes, "scary" changes (13 PRs)

What reviewers say:
> "this is scary to me. Does this remove all records from the table? What is the use case for it?"
> "It seems hacky/misleading to use warehouse_agent_inode_id for something that isn't actually a warehouse agent."
> "Why did we decide against setting a defined UUID as the analyze agent? That way you don't need to change the schema of the table."

Detect in a diff:
- `.delete()` / `.update()` calls without a clear org-scoped `.where()`.
- Repurposing of an existing column to carry a different semantic meaning.
- Schema additions that overlap with an existing column.

Severity: **Block PR**.

### 14. Bracket-suggestion nits (31 PRs) — almost always quick wins

What reviewers say:
> "nit: I'd suggest clarifying that it's a custom SQL _element_, not just SQL that is returned. maybe that's silly lol idk"
> "uber nit: we probably don't need to default to undefined here since the filters are optional"
> "small nit: …"
> Frequent use of GitHub `` ```suggestion `` blocks rather than freeform prose.

Detect in a diff:
- Anywhere — but inline GitHub `suggestion` blocks dominate small phrasing/null-handling fixes. Self-review the diff for: redundant `?? undefined`, copy-pasted descriptions with the wrong entity name, off-by-one in lists, places where a struct literal would be clearer than positional args.

Severity: **Nit**.

### 15. Naming clarity (8 PRs)

What reviewers say:
> "made file re-name changes as well as re-named `createSecurityRuleDraft` to `createSecurityDraftsAndAssignments`"
> "why do we have these 2 arguments? `assigneesToAdd` `assigneesToAdd` — I think you should only take `assignees`"
> "should the names be more descriptive for each phase or is this to make it more flexible"

Detect in a diff:
- Function names that don't reflect what the function returns (`createX` that creates X + Y).
- Argument-pair names that look like a typo or that overlap semantically.
- Generic names (`phase1`, `helper`, `doWork`) on exported symbols.

Severity: **Flag for reviewer**.

---

### Sampling caveats

- 100/100 sampled PRs returned both review and issue comments without API errors (0 failures, ~100% coverage of the chosen top-100).
- After filtering bot authors (`github-actions`, `cursorbot`, `aviator-app`, `dependabot`, `semgrep-code-sigma`, `copilot`, `cursor[bot]`), the sample yielded 342 review (line-level) comments and 124 issue comments = 466 substantive comments.
- Bot comments still dominate raw volume: `github-actions[bot]` posted 71, `aviator-app[bot]` 45 in the same 100 PRs — those are the API-docs-staging and merge-queue bots and were excluded from theme analysis.
- The "schema_drift" / "permissions_grants" counts are high in part because the schema-deletion warning bot triggers a long human discussion when it fires; treat them as "this critique surface is dense" rather than "this is the single most common nit".
