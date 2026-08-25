# Dynamic Workflows (Fable orchestrating Opus fleets)

`Workflow` tool runs JS script spawning Opus agents in-process — no CLI model can join. CLI workers remain for cross-family review + grok/gemini capacity. Gated: explicit opt-in only — "ultracode" (keyword; session-on = standing: workflow every substantive task, solo only trivia), user's own ask, or skill instruction (this skill grants it).

When: ≥2 parallel Claude agents, multi-phase pipelines, budget sweeps, multi-day loops. Single one-off Opus job = still one-`agent()` Workflow (§ Dispatch Mechanics). Hybrid default: scout the work-list inline first, then Workflow pipelines over it. Big multi-phase work = sequential Workflows, one per phase, Fable judging between — never one giant script.

## Unique powers vs CLI dispatch

- Deterministic control flow at zero Fable cost: loops/conditionals/fan-out run as script, not Fable turns. One script → dozens of agents → one return value. Runs in background, completion notifies; `/workflows` = live progress.
- Structured returns: `agent(prompt,{schema})` → validated JSON, auto-retry on mismatch. No logs/watcher/pid/jq.
- Native parallelism: ~16 concurrent (excess queues); caps: 1000 agents/run, 4096 items per pipeline/parallel call.
- Effort per call: `'low'` mechanical, `'medium'` worker tier, `'high'` verify/judge/design (`xhigh|max` exist — hardest judge stages only).
- Per-agent worktrees: `{isolation:'worktree'}` for parallel file mutations — costly, only when needed; auto-removed if unchanged; orchestrator still merges (§ Worktrees).
- Recovery: pass script inline (`script` param), never pre-Write — every run persists it (path in tool result) + `journal.jsonl` (each agent's actual return; if missing → `agent-<id>.jsonl` in transcript dir). Iterate: Edit persisted file, re-invoke `{scriptPath}`. Resume: `{scriptPath, resumeFromRunId}` — unchanged `agent()` prefix cached instant, edited/new run live. SAME SESSION ONLY; TaskStop prior run first. Cross-session: journal → author continuation script. Read journal before diagnosing empty result.
- Budget: user "+500k" directive → `budget.total`; guard `while (budget.total && budget.remaining() > 50_000)` (unset → Infinity → runs to agent cap). Hard ceiling — `agent()` throws past it. Pool shared with main loop. Static sizing: fleet ≈ `total/100k`.

## Script contract

- Plain JS, async body, no TS syntax, no fs/Node APIs (agents touch disk). Banned (break resume): `Date.now()`, `Math.random()`, argless `new Date()` — timestamps via `args` or stamp after return; randomness → vary prompt/label by index.
- `export const meta = {name, description, phases?: [{title, detail?, model?}], whenToUse?}` FIRST, pure literal (no vars/calls/spread). `phase('X')` titles match `meta.phases` exactly; unmatched → own progress group.
- `agent(prompt, opts)` → final text, or validated object with `schema`. Dead/skipped agent → `null`; `.filter(Boolean)`. Opts: `label`, `phase` (set explicitly inside pipeline/parallel stages — global `phase()` races), `schema`, `model`, `effort`, `isolation`, `agentType` (Agent-registry type, e.g. `'code-reviewer'`; composes with `schema`). Agents return raw data (final text = return value, not user message).
- `pipeline(items, ...stages)` DEFAULT — no barrier: item A stage 3 while B stage 1. Stage gets `(prev, originalItem, index)`; stage throw → item `null`, rest skipped. Plain functions OK as stages — reshape (flatten/map/filter) inline, never via a barrier.
- `parallel([...thunks])` BARRIER — thunks `() => agent(...)`, NOT bare promises. Never rejects; failed thunk → `null`. ONLY when stage needs ALL prior results (dedup/merge, early-exit on zero, cross-compare).
- `args` global = Workflow `args` input verbatim — real JSON, never stringified.
- `workflow(nameOr{scriptPath}, args)` = child workflow inline; shares caps/budget/abort; nesting 1 level max; throws on bad name/path/child syntax — catch. `name` = saved script in `.claude/workflows/` (also invocable top-level: `Workflow({name})`).
- Agents reach session MCP tools via ToolSearch; interactively-authed MCP servers may be absent in headless/cron runs.
- `log()` progress + any silent cap (top-N, sampling) — never imply full coverage.

## Multi-day loops ("3 days straight")

- `/loop` dynamic: after each burst, `ScheduleWakeup` (60–3600s clamp) re-fires loop prompt; `noop:true` quiet ticks; `stop:true` when plan done.
- Each wake: read `ledger.md` + latest journal → decide phase → launch ONE Workflow → update ledger → reschedule. While Workflow runs, only long fallback (1200s+) — completion re-invokes on its own; never poll. External untracked state (CI, deploys) → wake ≈ its cadence.
- State on disk (`ledger.md`, `docs/orchestration/`), never context-only — context summarizes across days; ledger survives.
- Division holds all week: Fable authors scripts + judges returns; Opus does 100% labor.

## Patterns (compose freely)

- Understand: parallel readers, one per subsystem → structured map.
- Fan-out review: `pipeline(dimensions, find, verifyEach)` — findings verify while other dimensions still search.
- Adversarial verify: 3 refuters per finding, kill on majority; refuters default refute when uncertain. Finding can fail multiple ways → distinct lenses (correctness/security/perf/repro) beat identical refuters.
- Loop-until-dry: spawn finders until 2 consecutive rounds add nothing; dedup vs ALL seen, not vs confirmed.
- Multi-modal sweep: parallel finders each searching a different way (by-container/content/entity/time) — one angle never finds all.
- Completeness critic: final agent asks "what's missing?" — findings become next round's work.
- Migration: discover sites → transform each in own worktree → verify → orchestrator merges serially.
- Judge panel: N designs from different angles → parallel judges → synthesize winner, graft runner-up ideas.

Rules: every mutating agent's prompt carries verbatim no-git paragraph (§ Worktrees). Default ≤15 agents unless user asks bigger (`/config` → Dynamic workflow size). Scale rigor to the ask: quick check = few finders/single vote; audit = big pool/3–5 votes/synthesis. Fable never an `agent()` — omitted `model` inherits Fable, omitted `effort` inherits session: state both every call.
