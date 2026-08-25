# Dynamic Workflows (Fable orchestrating Opus fleets)

Claude-side only: `Workflow` tool runs JS script spawning Opus agents in-process. No other roster model can join. CLI workers still exist for cross-family review + grok/gemini capacity — this = Claude fleet, not replacement.

When: ≥2 parallel Claude agents, multi-phase pipelines, budget sweeps, multi-day loops. Single one-off Opus job = still one-`agent()` Workflow (§ Dispatch Mechanics).

## Unique powers vs CLI dispatch

- Deterministic control flow at zero Fable cost: loops/conditionals/fan-out run as script, not Fable turns. One script → dozens of agents → one return value.
- Structured returns: `agent(prompt,{schema})` → validated JSON, auto-retry on mismatch. No logs/watcher/pid/jq.
- Native parallelism: ~16 concurrent, 1000/run cap.
- Effort per call: `'low'` mechanical, `'medium'` worker tier, `'high'` verify/judge/design.
- Per-agent worktrees: `{isolation:'worktree'}` for parallel file mutations — costly, only when needed; auto-removed if unchanged; orchestrator still merges (§ Worktrees).
- Recovery: every run persists script (path in tool result) + `journal.jsonl` (each agent's actual return). Resume `{scriptPath, resumeFromRunId}`: unchanged `agent()` prefix cached instant, edited/new run live. SAME SESSION ONLY; TaskStop prior run first. Cross-session: read journal, author continuation script. Read journal before diagnosing empty result.
- Budget: user "+500k" directive → `budget.total`; guard `while (budget.total && budget.remaining() > 50_000)`. Hard ceiling — `agent()` throws past it.

## Script contract

- Plain JS, async body, no TS syntax. Banned (break resume): `Date.now()`, `Math.random()`, argless `new Date()` — timestamps via `args`.
- `export const meta = {name, description, phases?, whenToUse?}` FIRST, pure literal (no vars/calls/spread). `phase('X')` titles match `meta.phases` exactly.
- `agent(prompt, opts)` → final text, or validated object with `schema`. Dead/skipped agent → `null`; `.filter(Boolean)`. Opts: `label`, `phase` (set explicitly inside pipeline/parallel stages — global `phase()` races), `schema`, `model`, `effort`, `isolation`, `agentType`. Agents return raw data (final text = return value, not user message).
- `pipeline(items, ...stages)` DEFAULT — no barrier, item A stage 3 while B stage 1. Stage gets `(prev, originalItem, index)`; stage throw → item `null`, rest skipped.
- `parallel([...thunks])` BARRIER — thunks `() => agent(...)`, NOT bare promises. Never rejects; failed thunk → `null`. Use ONLY when stage needs ALL prior results (dedup/merge, early-exit on zero, cross-compare).
- `args` global = Workflow `args` input verbatim — pass real JSON, never stringified.
- `workflow(nameOr{scriptPath}, args)`: child workflow inline; shares caps/budget/abort; nesting 1 level max.
- `log()` progress; log any silent cap (top-N, sampling) — never imply full coverage.

## Multi-day loops ("3 days straight")

- `/loop` dynamic: after each burst, `ScheduleWakeup` (60–3600s clamp) re-fires loop prompt; `noop:true` quiet ticks; `stop:true` when plan done.
- Each wake: read `ledger.md` + latest journal → decide phase → launch ONE Workflow → update ledger → reschedule. While Workflow runs, only long fallback (1200s+) — completion re-invokes on its own; never poll.
- State on disk (`ledger.md`, `docs/orchestration/`), never context-only — context summarizes across days; ledger survives.
- Division holds all week: Fable authors scripts + judges returns; Opus does 100% labor.

## Patterns (compose freely)

- Fan-out review: `pipeline(dimensions, find, verifyEach)` — findings verify while other dimensions still search; adversarial verify = 3 refuters, kill on majority.
- Loop-until-dry: spawn finders until 2 consecutive rounds add nothing; dedup vs ALL seen, not vs confirmed.
- Migration: discover sites → transform each in own worktree → verify → orchestrator merges serially.
- Judge panel: N designs from different angles → parallel judges → synthesize winner, graft runner-up ideas.

Rules: every mutating agent's prompt carries verbatim no-git paragraph (§ Worktrees). Default ≤15 agents unless user asks bigger. Fable never an `agent()` — orchestrator only.
