# `sigmacomputing/slate` — PR author profile

Built from the 500 most-recently merged PRs (window: roughly two months prior to 2026-05-29). Review-comment patterns are mined from the top 100 PRs by review activity in that window (856 inline review comments + 117 human top-level comments; 100% fetch coverage, no errors).

---

## 1. PR description style profile

### Template structure (the dominant pattern)

The Sigma PR template is a four-headline Q&A skeleton. **~80% of merged PRs use it** in full or part:

| Heading | PRs using it (of 500) |
|---|---|
| `## What is the purpose of this PR?` | 358 (72%) |
| `## How can reviewers try out these changes?` (or `## How to Try`) | 326 (65%) |
| `## What should reviewers focus on?` (or `## Reviewer Focus`) | 293 (59%) |
| `## How is this PR tested?` (or `## Testing`) | 307 (61%) |

A small ~8% use a shorter `## Purpose` form. ~17% of PRs are free-form (no template headings at all) — almost always small/mechanical changes (rename, codeowners tweak, version bump, single-line bug fix).

**Canonical skeleton (literal copy-pasteable):**

```
Resolves [SIG-NNNNN]

## What is the purpose of this PR?

<1–2 paragraph explanation of the intended outcome. Audience: any engineer at Sigma.>

## How can reviewers try out these changes?

<numbered or bulleted repro steps, often with deploy-preview link, screenshots, or a short video>

## What should reviewers focus on?

<bullet list of decisions, tradeoffs, or risky areas reviewers should scrutinize>

## How is this PR tested?

<which tests were added/run; cypress/playwright/jest; manual verification notes; explicit gaps if any>

[SIG-NNNNN]: https://sigmacomputing.atlassian.net/browse/SIG-NNNNN
```

### Length

- Median body: **129 words** (across all 500). P25 = 52, P75 = 221, max = 2,141.
- Per-section averages: Purpose 69 words, Try 38, Focus 47, Tested 48.
- **2 PRs were fully empty**, **5 were under 50 chars**. Length scales with risk: large refactors and stack-spanning changes routinely hit 500+ words; trivial fixes are 1–3 sentences with no sections.
- "Long" in this repo means ~250+ words with multiple sections plus images/code blocks. "Short" means 1–2 sentences and no sections.

### Title style

- **82% of titles use a `[area]` bracket prefix** (410/500). Most common prefixes (top 25 of ~80 used): `[agent builder v2]` (25), `[workbook-api]` (16), `[e2e]` (14), `[ai]` (12), `[AI Builder]` (11), `[swap-sources]`, `[report]`, `[Phi]`, `[ask]` (~9 each), `[starter-apps]`, `[maint]`, `[sigma table]`, `[converter]`, `[appy]`, `[prog-sync]`, `[peppermint]`, `[codemode]`, `[ai builder]`, `[VT]`, `[viz-encoder]`, `[neuron]`, `[i18n]`, `[actions]`, `[tools]` (5+ each).
- 14% (68/500) include a `SIG-NNNNN` Jira key in the title — most commonly bracketed (`[SIG-100356]`), occasionally as a prefix.
- **Conventional-commit prefixes (`feat:`, `fix:`, `chore:`) are virtually absent** — only 3 PRs of 500. Don't use them.
- Lowercase after the bracket prefix is the norm: `[agent builder v2] instructions popover fixes`.
- Titles are imperative and concise, usually 5–12 words.

### Jira / ticket linking

- **34% (172/500) link a Jira ticket** in the body, almost always with the **`Resolves [SIG-NNNNN]` first-line pattern**, then a reference-style link footer (`[SIG-NNNNN]: https://sigmacomputing.atlassian.net/...`). 126 PRs use that exact reference-style format.
- 14 PRs explicitly write `Resolves N/A` when there's no ticket; **50 PRs leave the literal placeholder `Resolves [SIG-####]`** unfilled (visible artifact of the template). The agent should either fill it or delete the line — don't leave the placeholder.
- 65% of merged PRs have **no Jira reference anywhere** (title or body). Tickets aren't required.

### Screenshots, videos, code blocks

- **36% (179/500) include an image or video** (`user-attachments` URL). UI-touching PRs almost always include one; backend-only PRs almost never do.
- Screenshots are pasted as `<img>` tags from GitHub attachments — no explicit captions, no Before/After labels in most cases (only 63 PRs use any "Before"/"After" wording, often informally).
- Videos (`.mov`/`.mp4`) appear in 7 PRs — typically when behavior is animation-heavy or hard to convey statically.
- **9% (45/500) use code blocks** (` ``` `) in the description — usually a snippet of CLI invocation, a diff, or a small example. Long code dumps are uncommon.

### Reviewer mentions / cc

- **15% (77/500) @-mention a teammate** in the body, usually to flag a specific reviewer for an area ("@username can you look at the fetch-manager bits?"). No PR uses an explicit `cc:` block — the convention is inline @-mention in the relevant section.

### Labels

Labels are sparse and mostly automated:

| Label | Count |
|---|---|
| `mergequeue` | 139 (auto-applied by Aviator merge queue) |
| `reporting` | 18 |
| `complexity:L/M`, `risk:L/M`, `type:BugFix/Feature/Refactor` | 1–4 each (rarely used) |
| `ai-review`, `blocked`, `stuck`, `merged-by-mq` | 1 each |

**Authors do not manually label most PRs.** Don't synthesize labels — let the merge queue and CI do it.

### Generated-by footers

**29% (147/500) include a "Generated by/for Sigma by Claude" footer.** Multiple variants exist: `Generated for Sigma by Claude Code`, `Generated by [Claude Code](https://claude.ai/code/session_...)`, `Generated for Sigma by Claude (Sonnet 4.5 + Opus 4.7)`, `Generated for Sigma by Claude 4.6 Opus`. Used by 10+ different authors — not just one. This is normalized in the repo.

### Anti-patterns to avoid

- **Leaving template placeholders unfilled.** 60 PRs ship with stray `<!-- ... -->` template comments; 56 leave `SIG-####` literal. The agent should strip placeholders for sections it leaves empty, or fill them.
- **Conventional-commit prefixes** (`feat:`, `fix(scope):`) — almost nonexistent. Use `[area] lowercase imperative` instead.
- **Markdown checkboxes / test-plan checklists** — only 2 PRs use them. Not the house style.
- **Long unstructured prose** without the four headings, on anything non-trivial — gets harder to review, and review comments often ask "where's the test plan?"
- **Posting `cc: @user` blocks** — convention is inline @-mention in the relevant section.
- **`## Summary` / `## Test plan`** headings (GitHub's default template) — only 2–4 PRs use them. Match the Sigma headings instead.

### Fill-in-the-blanks skeleton (what the drafting agent should produce)

```
[<area>] <imperative, lowercase, 5–12 words>
---
Resolves [SIG-NNNNN]   <!-- omit this line if no ticket -->

## What is the purpose of this PR?

<60–80 words. State the intended outcome; reference Jira if relevant. Audience: any Sigma engineer.>

## How can reviewers try out these changes?

<35–45 words OR a screenshot/video. For UI changes, include an image. For CLI/backend, give the exact commands.>

## What should reviewers focus on?

- <tradeoff or risky area #1>
- <tradeoff or risky area #2>
- <anything intentionally out of scope, linked to a follow-up ticket>

## How is this PR tested?

<unit/component (jest, vitest *.component.test.tsx), then e2e (playwright). State which suites pass, and call out any verification gap explicitly.>

[SIG-NNNNN]: https://sigmacomputing.atlassian.net/browse/SIG-NNNNN
```

For trivial changes (single-line fix, rename, codeowners), 1–2 sentences with no headings is acceptable and common.

---

## 2. Best-practice critiques mined from review comments

The following recurring critique themes each appear ≥3 times across the 100 most-reviewed PRs. Ranked by frequency. For each: representative quote(s), and how to detect the triggering diff pattern.

### 1. "Use the Phi wrapper, not RAC/the raw primitive" — 38 hits

**What reviewers say:**
- "shouldn't we be using a Phi component, not RAC directly?"
- "You shouldn't be using `createTheme` to override phi components like this"
- "the phi components are all around better and then you don't have to fix the switch labels being broken here"
- "use `SimpleLoader`" / "use `Copy` not `Text`" / "`ButtonGroup`" (terse 1-word redirects to the Phi component)

**Detect in a diff:** imports from `react-aria-components`, raw `@radix-ui/*`, raw `@react-aria/*`, or direct DOM elements (`<button>`, `<dialog>`) inside `packages/slate/src/**/*.tsx`. ESLint's `no-restricted-imports` will fail; if a diff modifies the `no-restricted-imports` rule itself, that's also a flag. Wrappers live in `packages/phi/src/components/foundations/<Name>/<Name>.tsx`; reach for those.

**Severity:** Block PR (raw RAC/Radix import in slate package) or Flag for reviewer (case-specific override).

### 2. Inline questions: "why do we need this?" — 34 hits

**What reviewers say:**
- "why do we need this?"
- "why do we need the typecasting here?"
- "Why is this here?"
- "nit: why this change?"
- "out of curiosity why is this data attr inside this flex and not applied to the Drawer?"

**Detect in a diff:** unexplained additions — new `useEffect`, new state, new prop, new wrapper element, new type cast (`as X`), new guard, or a single-character formatting change with no commit-message rationale. Self-review heuristic: every non-obvious new line should be explainable in one sentence; if not, add a code comment or expand the PR description.

**Severity:** Nit (cumulatively significant — clean up before pushing).

### 3. Missing / unsafe types, casts, and `any` — 27 hits

**What reviewers say:**
- "why do we need the typecasting here?"
- "as const shouldn't be necessary since you've already typed `next`"
- "can we update the upstream type to use `ConnectionType_t` so we don't need this cast here and below?"

**Detect in a diff:** new `as <T>`, `as any`, `as unknown as <T>`, `// @ts-expect-error`, `// @ts-ignore`, or a function declared without a return type when surrounding code in the file does declare them. Sigma also uses a `_t` suffix convention (e.g. `ConnectionType_t`) — if a diff introduces an inline shape literal where a `_t` already exists, flag it.

**Severity:** Flag for reviewer.

### 4. DRY: "this duplicates / can reuse" — 32 hits

**What reviewers say:**
- "This was copy pasted from the existing ask usage, should I drop it from both?"
- "This seems to be the same logic as the first bit of `teardown` - maybe we could reuse these bits in there as well"
- "Also the menu code should prob be shared instead of duped"
- "this mostly duplicates the first few lines of teardown(), though I notice you are checking on isCanceled whereas teardown() does not"

**Detect in a diff:** identical (or near-identical) blocks of 5+ lines across multiple files in the same PR, or a new function whose body strongly resembles an existing exported function in the same package. Especially common in `packages/edits/src/**` (edit utilities) and `packages/slate/src/**/menu/**`.

**Severity:** Flag for reviewer.

### 5. Naming nits: "let's call it X to match Y" — 29 hits

**What reviewers say:**
- "Maybe call it `placement` to match the phi API"
- "could we call it FORCE_{DISABLE,ENABLE}_HYPERSHEETS just to make it clearer?"
- "since the original was `duplicateMainContentElement`, it makes sense to have a function like `duplicateContainerElement`. rename/rework so that's the name of the function we use"
- "since none of these guarantee persistence, consider renaming methods to ..."

**Detect in a diff:** new exported symbols whose name diverges from a sibling concept already in the file/package. For React/Phi: prop names should mirror RAC/Phi (e.g. `placement`, `onOpenChange`, `size`, `variant`). For backend: methods that imply side effects should be named with verbs that match neighbors (`save*`/`persist*`/`flush*`/`commit*`).

**Severity:** Nit / Flag for reviewer (for exported symbols).

### 6. Tests requested or test-strategy pushback — 30 hits (22 review + 8 issue)

**What reviewers say:**
- "Unit tests would def be preferred. In slate we should prioritize unit (jest), component (vitest `*.component.test.tsx`), and then e2e (playwright) tests."
- "Should we have more robust assertions here for content? Should we add a negative case as well as documented?"
- "could the data correctness bits be covered in a unit test?"
- "Consider adding this into an export fixture."

**Detect in a diff:** new code under `packages/*/src/**` with no corresponding `*.test.ts`, `*.test.tsx`, `*.component.test.tsx`, or `*.spec.ts` change. New Playwright spec that asserts low-level data correctness (cell values, exact byte content) → ask if it should be a jest test instead. New cypress spec → ask if it could be Playwright + jest.

**Severity:** Block PR (logic change with no test) or Flag for reviewer (test exists but in the wrong tier).

### 7. Feature-flag gating — 9–12 hits (with high priority)

**What reviewers say:**
- "Can you put this behind a feature flag?"
- "this should be gated behind a feature flag, most likely AGENT_SOURCE_SWAP"
- "I couldn't find the feature flag code in here, is this guarded under a ff? otherwise looks ok"
- "it's easier to just override the flag for yourself in statsig"

**Detect in a diff:** new user-visible behavior in `packages/slate/src/views/**` or `packages/ai/**`, or any new entrypoint (menu item, button, modal), without a corresponding `useStatsigGate`/`useFeatureFlag` check or a flag name added to the flags registry. Flags use SCREAMING_SNAKE_CASE (`AGENT_SOURCE_SWAP`, `AI_CHAT_DICTATION`, `PIVOT_REORDER_LABELS`).

**Severity:** Block PR for user-visible behavior in `views/**` or `ai/**`.

### 8. i18n / translation wrapping — strong signal in UI PRs

**What reviewers say:**
- (Inline) `t('New drawer'),` — reviewers will literally rewrite a string literal to wrap it in `t(...)`
- "Is this not inheriting `yarn i18n:extract` & `yarn format` anymore intentional?"

**Detect in a diff:** new user-facing string literals (passed to `label=`, `placeholder=`, `title=`, `aria-label=`, `children` of `<Text>` / `<Heading>` / `<Copy>`) not wrapped in `t(...)`. Anything in `packages/slate/src/**/*.tsx` that renders text. If `yarn i18n:extract` would produce a diff and the PR doesn't include it, flag.

**Severity:** Block PR (untranslated user-facing string in slate).

### 9. Out-of-scope / split-this-PR / follow-up — 16+ hits

**What reviewers say:**
- "Switching both modal + drawer to a Phi primitive is out of scope for Part A — happy to file a follow-up."
- "let's fix this in followup"
- "Ya not sure, should we tag the owning team and let them make the call? I think either consolidate into the existing spec ... or delete entirely"
- "I'll leave that for a separate PR, so we can address all of the design fixes in one swoop."

**Detect in a diff:** the PR touches >1 distinct subsystem (e.g. modifies `packages/phi/**` AND `packages/slate/**` AND adds a Cypress spec) when the title implies a single concern. Self-review heuristic: if you can't summarize the change in one sentence under `## What is the purpose of this PR?`, split it.

**Severity:** Flag for reviewer.

### 10. `useCallback` / `useMemo` requests, dependency-array correctness — 10–15 hits

**What reviewers say:**
- "let's move this to a `useCallback`"
- "If you run `filter` then you need to memoize this, but why do `null` entries exist here?"

**Detect in a diff:** new inline function or new derived array/object literal passed as a prop to a memoized child component (`React.memo(...)`, virtualized lists, RAC components). New `useEffect` whose body calls a function that itself isn't memoized.

**Severity:** Flag for reviewer.

### 11. Phi component css/style props — repeated for `Flex`/`Stack`/Alert sizing — 49 hits in "modal/drawer/popover" cluster

**What reviewers say:**
- "Both of these flexes can be removed and the css can be applied directly on the Alert component"
- "Don't adjust the modal sizing. The defaults should be enough with an appropriate `size` prop. If the defaults are not enough, then this modal needs to be redesigned."
- "Phi's Drawer filters out `style` ... and routes css to the panel, so `style={{ backgroundColor }}` doesn't render."

**Detect in a diff:** raw `style={{...}}` on a Phi foundation component (especially `Modal`, `Drawer`, `Popover`, `Alert`), `width:`/`height:` in vh/px on a modal, manual `padding`/`margin` token values when a Phi prop already controls them. Prefer the component's prop API (`size`, `variant`, `placement`, `padding`).

**Severity:** Flag for reviewer.

### 12. Test-id / tracking-id missing — 5+ hits

**What reviewers say:**
- "Add a track id"
- "out of curiousity why is this data attr inside this flex and not applied to the Drawer? same with the testId"

**Detect in a diff:** new interactive surface (button, modal, panel) without `data-testid` or `trackingId` props. The repo has a strong convention of adding both on every interactive root component.

**Severity:** Nit (but consistently requested — clean up before pushing).

### 13. Error handling: missing `finally`, swallowed errors, leaked promises — 23 hits

**What reviewers say:**
- "since we set isPending to false in both the catch and outside could use a `finally`?"
- "Don't directly call `getApiClient()` so you don't leak promises"
- "updated to use apollo's `useMutation` which ties the in-flight promise to the component's lifecycle"

**Detect in a diff:** new `try { ... } catch (e) { setState(false) }` followed by a duplicate state reset outside the block → flag for `finally`. Calls to `getApiClient()`/raw fetches without `await` or `.catch(...)`. New mutations not using `useMutation` for state-tied lifecycles.

**Severity:** Flag for reviewer.

### 14. Dead code / leftover scaffolding — 15 hits

**What reviewers say:**
- "can we rm this disable now"
- "Unnecessary since drawer title is already set"
- "This is the default size, remove"
- "nit: likely don't need the doc here"

**Detect in a diff:** new `eslint-disable` comments (especially `eslint-disable-next-line`), no-op prop assignments (`size: 'medium'` when medium is the default), commented-out code, unused imports, props that the underlying component already defaults.

**Severity:** Nit.

### 15. Cross-repo / mono-node regression risk — recurring in test-strategy threads

**What reviewers say:**
- "My hesitance about relying solely on slate unit/component tests is that it won't catch regressions on the mono-node/other repos."

**Detect in a diff:** changes to serializers, protobuf-adjacent types (`*Raw_t`, `WasmEval_*`), or anything in `packages/edits/**` or `packages/workbook-api/**` that has counterparts in `mono-node`. Self-review prompt: "does this change a shape that crosses repo boundaries? If so, name the other repo in `## What should reviewers focus on?`"

**Severity:** Flag for reviewer.

---

## Raw counts used in this synthesis

- Window: 500 most recently merged PRs from `sigmacomputing/slate` (top of `master`, gathered 2026-05-29).
- 500/500 PR descriptions retrieved; **2 PRs had empty bodies**, 5 < 50 chars.
- Top 100 PRs by `reviewThreads.totalCount + comments.totalCount` were sampled. **100/100 fetched successfully** (review comments + issue comments). No errors.
- 856 inline review comments analyzed; 309 issue-level comments (117 human after stripping `SigmaDeployPreview` 101 + `aviator-app[bot]` 89 + other bots).
- Template-section frequencies (% of 500): Purpose-Q 72%, Try 65%, Focus 59%, Tested 61%. Short `## Purpose` form adds 8%. Free-form (no canonical headings): ~17%.
- Bracketed title prefix: 82% (410/500). `SIG-` in title: 14% (68/500). `feat:/fix:` conventional prefix: 0.6% (3/500).
- `Resolves [SIG-NNNNN]` first-line: 31% (156/500). Reference-style Jira footer: 25% (126/500). No Jira anywhere: 66% (328/500). Literal `SIG-####` placeholder left unfilled: 10% (50/500). Stray `<!-- ... -->` template comments: 12% (60/500).
- Image/screenshot in body: 36% (179/500). Code block in body: 9% (45/500). Video extension reference: 1% (7/500). Checkbox lists: 0.4% (2/500). @-mention in body: 15% (77/500). Explicit `cc:` block: 0 (0/500).
- "Generated by/for Sigma by Claude" footer: 29% (147/500), authored by 10+ distinct humans.
- `mergequeue` label: 28% (139/500) — auto-applied. All other labels: <4% each.
