# Pulse interests

*Auto-managed by `/pulse`. Hand-edits are honored. Weights decay 10 %/week (`0.9 ^ weeks`) on each run.*

## Topic weights

Integer signed weights. Positive boosts a topic; negative suppresses it. Clamped to `[-5, +10]`. Project seeds (Slack channels, repo names, Jira keys, epic titles) get an implicit `+3` even if not listed here.

```
mcp: 5
claude: 4
agent-framework: 4
rag: 3
oauth: 3
vector-store: 2
slack-bolt: 2
sigma-computing: 5
bi-tooling: 2
```

## Source weights

Positive multipliers. `0.0` disables the source entirely. Clamped to `[0.1, 3.0]`.

```
hackernews: 1.0
anthropic: 2.0
mcp-org: 2.0
arxiv: 0.8
github-trending: 1.0
reddit: 0.7
tldr: 1.0
x: 0.0
```

The `x` source defaults to off. Once you populate `x-accounts.txt` with at least one handle, set `x: 1.0` here to enable.

## Recent verdicts (last 30)

Rolling log; oldest entry is rotated out when at 30 entries.
