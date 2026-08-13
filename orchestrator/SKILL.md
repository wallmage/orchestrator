---
name: orchestrator
description: Multi-model division of labor — Claude Fable as orchestrator; Opus, Codex (gpt models) or other models as worker. Use when the user says "orchestrate this task" or starts any delegated job. Defines the model routing and cost/intelligence roster, CLI tools, flags, and usage for all scenarios.
---

## Optimal Performance, Cost, Speed

A single “brain” agent (you, Fable 5) receives the high‑level goal or ideas from human user, proposes the best design and implementation plan, decomposes it into subtasks, assigns those to worker agents (cheaper GPT models and Opus), and later evaluates, synthesizes the results. Workers run their own loops to complete assigned tasks, using tools (code execution, web search) and their own skills (superpowers) and can be specialized by task type (e.g., default worker, designer). The routing logic tries to provide adequate performance with lowest cost (overkill is waste). Orchestrator parallelizes as often as possible: assign multiple workers (can be homogeneous or heterogeneous) when speed gains outweight merge cost.

## Model Roster & Routing

| Model & Effort | Role | Cost | Intelligence | Notes |
| --- | --- | --- | --- | --- |
| **Fable (you)** | Orchestrator | Max | Max | Most expensive, use sparingly: judgment only, never labor, never a pipeline's "Claude worker" (that's Opus). Always outsource when possible |
| Opus `claude-opus-5` effort low | Default Worker | Low | Medium | STANDARD WORKER, ~90% of dispatches |
| Codex `gpt-5.6-sol` effort high | Escalated Worker | Medium | High | Hardest ~10%: intricate design/parsing/subtle correctness |
| Codex `gpt-5.6-luna` effort high | Chore Worker | FREE | Low | Mechanical/zero-judgment trivia and batch jobs |
| Codex `gpt-5.6-luna` effort xhigh | Default Worker 2 | Low | Medium | Backup: interchangeable with Opus low |
| Opus `claude-opus-5` effort medium | UI/UX Designer | Medium | High | Design and taste |
| Kimi K3 | On-demand | Max | High | User trigger only — recipe: `reserve-models.md` |

BANNED: Codex Spark (`gpt-5.3-codex-spark`); Sonnet 5 (`claude-sonnet-5` Sonnet is more expensive than Opus, always use Opus low instead of Sonnet); Haiku (`claude-haiku-4.5`)

## Codex CLI

Dispatch = this runner via Bash `run_in_background`, watcher armed same batch:

```sh
exec </dev/null                   # live stdin pipe freezes codex exec
echo $$ > <TMP_PATH>/<job>.pid       # scopes watcher CPU/socket checks to this job
cd <PROJECT ROOT>                 # never a worktree — session cwd files the Codex app's project list
codex exec --json -o <TMP_PATH>/<job>.final.txt -m <model> -c model_reasoning_effort=<effort> \
  -s workspace-write "<prompt>" > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log   # leading \n: a log without trailing newline would bury EXIT= mid-line
```

Files:
- `<TMP_PATH>` = this session's temp directory; one `.pid` + `.log` + `.final.txt` per job; OS-cleaned, no manual cleanup.
- Read the `-o` file, NEVER the log.
- Grep the log only for `thread_id` (to resume) and `^EXIT=`.
- Success = `EXIT=0` AND non-empty `-o` file.

Flags:
- `-m` + `-c model_reasoning_effort=` on EVERY dispatch.
- Models: `gpt-5.6-sol` or `gpt-5.6-luna` only (bare `gpt-5.6` is invalid).
- Effort: `low|medium|high|xhigh`.
- `-s read-only` for analysis-only jobs.
- `--output-schema <file>`: a JSON Schema file fixing the exact shape of the final answer. Use whenever the answer will be parsed or acted on mechanically. Every property must declare an explicit `type`; `uniqueItems` is unsupported.
- `-C <dir>` (sets Codex's working folder) is BANNED — always `cd` to the project root, per the runner.
- Worktree edits: name the path in the prompt ("Work in `<path>`") and add `--add-dir <dir>` to make it writable.
- Rare: `-i <img>` attaches an image; `--skip-git-repo-check` allows running outside a git repo.

Prompts:
- Codex parent thread can fan out 3 parallel subagents (max 4 workers). Codex will not use subagents unless explicitly reminded. Remind Codex when job benefits from parallelism "Use subagents to make the task faster"
- **Superpowers:** prepend to every Codex prompt: `[$superpowers:using-superpowers](~/.codex/plugins/cache/openai-curated-remote/superpowers/6.2.0/skills/using-superpowers/SKILL.md)` (update version # if plugin changes). TDD is enforced as verifiable acceptance checks (failing-tests-first, tests present in the diff), not as trust.

Follow-ups:
- Resume: `codex exec resume <thread_id> --json -o <f> "<delta>"` — send only the follow-up (memory intact). Takes no `-C`/`-s`; inherits shell cwd.
- Cancel: `TaskStop` the Bash task; confirm no `EXIT=` was written.
- Review: `codex exec review --uncommitted|--base <ref>|--commit <sha> --json -o <f>`.

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
- Birth check: log must exist by 15s (LAUNCH FAILURE otherwise); proof of WORK at 3 min (RIGHT-WORK CHECK).
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

Simplest design that solves it. The plan is the only source of scope: never self-authorize extra scope, rounds, or fix passes. Out-of-scope defects are PARKED: one line + evidence to the user, work stays on the critical path.

## 2. Communication
One-line pulse every ~10 min: what's running, what's next. Never surface mechanics, internal recoveries, or worker behavior. Nothing changed = exactly "on track, ~N min left". Self-resolved incidents = no message. No jargon (probe, pilot, contract, amendment) — everyday words.

## 3. Every delegation is a sealed envelope
Workers see only your prompt and the disk. Include: absolute paths, starting commit, exact outputs, forbidden actions, runnable acceptance checks with expected values, every shared state file. Point at governing docs by path + "the doc wins; flag conflicts". Preflight the environment (writability, cwd, auth, model IDs/flags) before every dispatch.

## 4. Spend each intelligence where it's scarce
Cheapest adequate worker; your tokens go to design, contracts, verification, judgment. Exception: ~≤20-line fixes with no design choices — do directly (still in a worktree). Ceremony scales with job size. Delegate bulk reads; clip outputs.
