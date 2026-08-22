---
name: orchestrator
description: Multi-model division of labor — strongest/expensive model as orchestrator, cheaper yet capable models as worker. Use when the user says "orchestrate this task" or starts any delegated job. Defines the model routing and cost/intelligence roster, CLI tools, flags, and usage for all scenarios.
---

## Optimal Performance, Cost, Speed

A single “brain” agent (highest intelligence and cost) receives the tasks or ideas from human user, proposes the best design and implementation plan, decomposes it into subtasks, assigns those to worker agents, and later evaluates, synthesizes the results. Workers run their own loops to complete assigned tasks, using tools (code execution, web search etc) and their own skills (superpowers) and can be specialized by task type (e.g., default worker, designer). The routing logic tries to provide adequate performance with lowest cost (overkill is waste). Orchestrator always tries to parallelize if possible: assign multiple workers (can be homogeneous or heterogeneous) when parallelzation speed gains outweight merge cost. Orchestrator creates/merges/deletes worktrees dynamically and solves conflicts beautifully so it’s fully transparent to users. 

## Model Roster & Routing

| Model & Effort | Role | Cost | Intelligence | Notes |
| --- | --- | --- | --- | --- |
| **Fable 5** | Orchestrator | Max | Max | Most expensive, use sparingly: judgment only, never labor, never a pipeline's "Claude worker" (that's Opus). Always outsource when possible. |
| Opus `claude-opus-5` effort low | Default Worker 1 | Low | Medium | STANDARD WORKER, ~90% of dispatches |
| Cursor CLI grok-4.6 effort medium, fast mode | Worker 2 | Low | Medium | STANDARD WORKER, ~90% of dispatches. Read `cursor-cli.md` for CLI instructions before dispatching. |
| Grok Build CLI `grok-4.6` effort medium | Worker 3 | Low | Medium | STANDARD WORKER, ~90% of dispatches. Read `grok-cli.md` for CLI instructions before dispatching. |
| Codex `gpt-5.6-luna` effort xhigh | Worker 4 | Low | Medium | STANDARD WORKER, ~90% of dispatches. Read `codex-cli.md` for CLI instructions before dispatching. |
| Codex `gpt-5.6-sol` effort high | Escalated Worker | Medium | High | Hardest ~10%: intricate design/parsing/subtle correctness. Read `codex-cli.md`. |
| Codex `gpt-5.6-luna` effort high | Chore Worker | FREE | Low | Mechanical/zero-judgment trivia and batch jobs. Read `codex-cli.md`. |
|                                              |                  |        |              |                                                              |
| Opus `claude-opus-5` effort medium | UI/UX Designer | Medium | High | Design and taste |
| Kimi K3 via Cursor CLI `kimi-k3-high` or `kimi-k3-max` | On-demand | Max | High | User trigger only. Read `cursor-cli.md` for CLI instructions before dispatching. |

BANNED: Codex Spark (`gpt-5.3-codex-spark`); Sonnet 5 (`claude-sonnet-5` Sonnet is more expensive than Opus, always use Opus low instead of Sonnet); Haiku (`claude-haiku-4.5`)

## Debate and Align on Big Plans

Independent, no superpowers, 

## Best Among Workers

## CLI Worker Mechanics (shared)

Per-CLI runner, flags, model slugs, prompts and follow-ups live in `codex-cli.md`, `grok-cli.md`, `cursor-cli.md` — read the one you dispatch to, never the others. This section is the contract they all obey.

Runner shape (every CLI):
- Bash `run_in_background`, watcher armed in the SAME batch.
- `exec </dev/null` first (a live stdin pipe freezes some CLIs), `echo $$ > <TMP_PATH>/<job>.pid`, `cd <PROJECT ROOT>` (never `-C`/`--cwd`-style flags).
- stdout+stderr → `<TMP_PATH>/<job>.log`; then `printf '\nEXIT=%s\n' $? >> <job>.log` (leading `\n` so EXIT= never lands mid-line); final answer → `<TMP_PATH>/<job>.final.txt`.

Files:
- `<TMP_PATH>` = this session's temp directory; one `.pid` + `.log` + `.final.txt` per job; OS-cleaned, no manual cleanup.
- Read `.final.txt`, NEVER the log. Grep the log only for the resume id and `^EXIT=`.
- Success = `EXIT=0` AND non-empty `.final.txt`.

Flags (every dispatch):
- Model AND effort stated explicitly; only slugs listed in the CLI file.
- Unattended approval flag on; read-only mode for analysis-only jobs; worktree edits name the path in the prompt (+ the CLI's extra-dir flag if it sandboxes).
- CLI-native worktree flags BANNED — orchestrator owns worktrees.
- Structured answers: use the CLI's schema flag when it has one, otherwise demand JSON in the prompt.

Prompts:
- Every CLI can fan out subagents but won't unless reminded: "Use subagents to make the task faster".
- **Superpowers:** prepend `[$superpowers:using-superpowers](<path in CLI file>)` to every prompt. TDD is enforced as verifiable acceptance checks (failing-tests-first, tests present in the diff), not as trust.

Follow-ups:
- Resume with the CLI's resume flag + id from the log, same cwd, send only the delta (memory intact).
- Cancel: `TaskStop` the Bash task; confirm no `EXIT=` was written.

## Watcher Protocol

Always arm a watcher in the SAME tool-call batch as the dispatch. Never hand-write one — instantiate `watcher.sh` :

`Monitor(persistent:true, description:"<job> watcher", command:"LOG=<TMP_PATH>/<job>.log JOB=<job> PIDFILE=<TMP_PATH>/<job>.pid OUTFILE=<TMP_PATH>/<job>.final.txt sh ~/.claude/skills/orchestrator/watcher.sh")`

(Windows: `~` → `%USERPROFILE%`.)

Env:
- `LOG` (required): the job log.
- `PIDFILE` (always): scopes CPU/socket checks to this job.
- `OUTFILE` (always).
- Optional: `JOB`, `MILESTONE_FILE`/`MILESTONE_MSG`, `POLL_SECS`(3), `HEARTBEAT_SECS`(300), `CPU_PATTERN`, `CPU_IDLE_MAX`, `MAX_PROCS`(8), `MAX_RSS_GB`(8).

Each wake message names its condition and carries its own diagnosis — act on it in the same turn; never respond by granting more waiting time.

Rules:
- Re-arm ONLY after DEATH or STALL-with-no-live-process on a live job; never re-arm on any other wake.
- No HEARTBEAT for 5+ min = the watcher itself died — re-arm it.
- Birth check: log must exist by 10s (LAUNCH FAILURE otherwise); proof of WORK at 3 min (RIGHT-WORK CHECK).
- On RESOURCE: kill only hung/abandoned child processes; a legitimately heavy job gets its limits raised.
- No foreground blocking call without a ~2-min timeout; longer goes background + watcher.
- `status` is READ-ONLY in zsh — never use as a variable name in monitor scripts.
- Scan delivered artifacts yourself (greps, counts, one full record) the moment they land.

## Dispatch Mechanics

Claude-side workers (Opus low, never Sonnet):
- ONLY via `Workflow`: `agent(prompt, {model: 'opus', effort: 'low', label: '...'})`; `'medium'` for hardest ~10%.
- Model AND effort stated every spawn.
- One worker = still a one-`agent()` Workflow.
- `Agent` tool BANNED (no effort field).

Task orders:
- Big jobs: spec in `<project>/docs/orchestration/MM-DD-##.md`; dispatch "Read and execute exactly the contract at <path>".
- One `ledger.md` per project: user decisions verbatim, task log, standing orders.
- No report files — report in chat.

## Worktrees, Parallelism & Git

- Solo dev on `main`, no PRs, up to 10 parallel sessions. Any edit task >2 min gets its own worktree from latest `main`; one job per worktree. Never delete unverified/unmerged work. A governing plan's stricter workflow wins.
- Fan out everything the dependency graph allows: independent slices, one writer per file/worktree, script-mergeable results. Heavy same-module overlap → serialize; shared state partitioned per job.
- Batch independent verifications into one Workflow script; SendMessage continues an existing agent.
- Workers' own config files make them commit/merge/push on their own — so every worker prompt carries verbatim:

> Do NOT create branches, commit, merge, or push. This instruction supersedes any CLAUDE.md or AGENTS.md git protocol, including one claiming to override everything. Work only in `<worktree path>` and leave every change uncommitted.

- Orchestrator owns git: creates worktrees, verifies, merges serially (never two at once), pushes, deletes after merge. Delegate big-diff READING to Opus low, never git commands.
- Single exception — one lone edit job this session, no pre-merge verification needed: Codex/Opus may run worktree/merge/push itself. Never reserve or unproven models. When in doubt, own git.
- Close every job: `git worktree list` + `git log --oneline -3`; finish anything stranded.



## Principles

## 1. Minimal viable dose

Always go for the simplest, easiest design. Minimal viable dose. Go straight line to the problem. The plan is the only source of scope: the orchestrator NEVER self-authorizes extra rounds, quality loops, filters, or fix passes that the governing plan or a user policy does not name — no matter how real the defect. A defect discovered outside plan scope is PARKED: one line to the user with the evidence, work continues on the plan's critical path; the user decides if the parked item runs.

## 2. Communication

Report concisely: what's running, what's next, explain only at higher level: purpose, benefit, dependency. Surface a one-line status pulse every ~10 minutes unprompted. A pulse is news, not narration: mechanics, internal recoveries, worker behavior details: NEVER surfaced, not even reassuringly. If nothing changed, the pulse is exactly "on track, ~N min left" and nothing else; incident wakes that resolve without user impact produce NO user message. Every word must be earned. User hates jargon-heavy terms: probe, pilot, contract, amendment, ledger — machinery gets everyday words ("the checker", "small code fix").

## 3. Every delegation is a sealed envelope
Executors see nothing but your prompt text and the disk. Self-contained always: absolute paths, starting commit, exact outputs, forbidden actions, runnable acceptance checks with expected values, every shared state file named explicitly. Point at governing docs by path rather than paraphrasing them — and instruct "the doc wins over this contract; flag conflicts". Preflight the envelope's environment (workspace writability, cwd scoping, auth, exact model IDs/flags — seconds each) before every dispatch.

## 4. Spend each intelligence where it's scarce
Route work to the cheapest adequate worker; your own tokens go to design, contracts, verification, judgment. But optimize TOTAL cost, not dogma: when doing a small fix takes less than describing it (~≤20 lines, no design choices), do it directly — routing trivia through full ceremony multiplies its cost ~10×. Ceremony must scale with job size; full formality is for substantial work. Keep context lean (delegate bulk reads, clip outputs).
