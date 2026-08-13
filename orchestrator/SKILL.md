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

BANNED: Codex Spark (`gpt-5.3-codex-spark`); Sonnet 5 (`claude-sonnet-5`); Haiku (`claude-haiku-4.5`)

## Codex CLI

Dispatch = this runner via Bash `run_in_background`, watcher armed same batch:

```sh
exec </dev/null                   # live stdin pipe freezes codex exec
echo $$ > <SCRATCH>/<job>.pid       # scopes watcher CPU/socket checks to this job
cd <PROJECT ROOT>                 # never a worktree — session cwd files the Codex app's project list
codex exec --json -o <SCRATCH>/<job>.final.txt -m <model> -c model_reasoning_effort=<effort> \
  -s workspace-write "<prompt>" > <SCRATCH>/<job>.log 2>&1
echo "EXIT=$?" >> <SCRATCH>/<job>.log
```

- `<SCRATCH>` = this session's scratchpad directory (temporary files, OS-cleaned; one `.pid` + `.log` + `.final.txt` per job). Read the `-o` file, NEVER the log. Grep the log only for: `thread_id` (to resume) and `^EXIT=`. Success = `EXIT=0` AND non-empty `-o`.
- `-m` + `-c model_reasoning_effort=` on EVERY dispatch. `-s read-only` for analysis-only jobs (can read files, cannot change them).
- `--output-schema <file>`: pass a JSON Schema file describing the exact shape of the final answer. Use it whenever the answer will be parsed or acted on mechanically — free-form prose breaks parsing. Codex rejects sloppy schemas: every property must declare an explicit `type`, and the `uniqueItems` keyword is unsupported.
- `-C <dir>` (sets Codex's working folder) is BANNED — always `cd` to the project root instead, per the runner. For edits in a worktree: name the path in the prompt ("Work in `<path>`") and add `--add-dir <dir>` to make it writable. Rare: `-i <img>` attaches an image; `--skip-git-repo-check` allows running outside a git repo.
- Models: `gpt-5.6-sol` or `gpt-5.6-luna` only (bare `gpt-5.6` is invalid). Effort: `low|medium|high|xhigh`.
- Resume: `codex exec resume <thread_id> --json -o <f> "<delta>"` — continues that Codex conversation with its memory intact, so send only the follow-up. Takes no `-C`/`-s`; inherits shell cwd. Cancel: `TaskStop` the Bash task, confirm no `EXIT=` written.
- Review: `codex exec review --uncommitted|--base <ref>|--commit <sha> --json -o <f>` — built-in reviewer that computes the diff scope itself; a prompt-based review makes Codex reconstruct the diff and sometimes gets it wrong.
- Never demand full ingestion of inputs past a few hundred KB — Codex samples big files. Response ceiling ≈30–60k tokens; don't request bigger outputs.

## Dispatch Mechanics

- **Model AND effort pinned on every spawn.** Claude-side workers ONLY via `Workflow`: `agent(prompt, {model: 'opus', effort: 'low', label: '...'})` (`'medium'` for hardest ~10%); one worker is still a one-`agent()` Workflow. Plain `Agent` tool BANNED (no effort field).
- Codex can fan out to 3 internal subagents but won't unless told — every parallelizable dispatch includes: "This task can be faster with subagents. Use subagents for parallelism."
- Prepend to every Codex prompt: `[$superpowers:using-superpowers](/Users/wallny/.codex/plugins/cache/openai-curated-remote/superpowers/6.2.0/skills/using-superpowers/SKILL.md)` (bump version when plugin updates). TDD = verifiable acceptance checks (failing tests first, tests in diff).
- Contracts: `<project>/docs/orchestration/MM-DD-##.md`, dispatched as "Read and execute exactly the contract at <path>". One rolling `ledger.md` per project (user decisions verbatim, task log, standing orders). No report files — report inline in chat.
- Public repo: functional files (SKILL.md, watcher.sh, reserve-models.md, future runtime assets) publish VERBATIM — no sanitizing, ever. New files: add to the `cp` line in sync.sh + .gitignore allowlist the turn created. Internal docs, plans, sync tooling stay ignored.
- After ANY edit to this skill, SAME turn: `sh /Users/wallny/Developer/Skills/Orchestrator/sync/sync.sh` — copies the files and commits+pushes itself.

## Worktrees & Parallelism

- Solo dev on `main`, no PRs, up to 10 parallel sessions. Any edit task >2 min gets its own worktree from latest `main`; one job per worktree. Git ownership stated in every prompt (§7). Never delete unverified/unmerged work. A governing plan's stricter workflow wins in its project.
- Parallel go/no-go: dependency graph, then file overlap (none → go; heavy same-module → serialize); shared mutable state partitioned per job.
- Batch independent verifications into one Workflow script. SendMessage continues an existing agent with context intact.

## 1. Minimal viable dose
Simplest design that solves it. The plan is the only source of scope: never self-authorize extra rounds, loops, filters, or fix passes. Out-of-scope defects are PARKED: one line + evidence to the user, work stays on the critical path.

## 2. Communication
One-line pulse every ~10 min: what's running, what's next. Never surface mechanics, internal recoveries, or worker behavior. Nothing changed = exactly "on track, ~N min left". Self-resolved incidents = no message. No jargon (probe, pilot, contract, amendment, ledger) — everyday words.

## 3. Watcher Protocol

**Every CLI-launched job arms a watcher in the SAME tool-call batch as the dispatch.** Never hand-write one — instantiate `watcher.sh` (this skill's dir; all wake categories, dedup, finish≠success live there):

`Monitor(persistent:true, timeout_ms:14400000, description:"<job> watcher", command:"LOG=<SCRATCH>/<job>.log JOB=<job> PIDFILE=<SCRATCH>/<job>.pid OUTFILE=<SCRATCH>/<job>.final.txt sh /Users/wallny/.claude/skills/orchestrator/watcher.sh")`

Env: `LOG` required; always pass `PIDFILE` (scopes CPU/socket checks) and `OUTFILE` (empty ⇒ FINISHED-SUSPECT). Optional: `JOB`, `MILESTONE_FILE`/`MILESTONE_MSG`, `POLL_SECS`(3), `HEARTBEAT_SECS`(300), `CPU_PATTERN`, `CPU_IDLE_MAX`, `DEDUP_SECS`, `REMOTE_DEDUP_SECS`, `MAX_PROCS`(8), `MAX_RSS_GB`(8). Handles any runner-shaped log. **Exempt:** Workflow workers — completion auto-notifies; watcher.sh would misread one as LAUNCH FAILURE. Long subagents: have them append one-line progress to a file, watch THAT.

Wakes: `ARMED OK` ≤5s (`ARMING` until log exists) · `LAUNCH FAILURE` at 10s · `DEATH` (log vanishes) · `ERROR` (only if unresolved one poll later) · `WAITING FOR INPUT` (prompt signature at frozen tail) · `STALL` (2 zero-growth polls + idle CPU + 0 sockets; diagnosis included) · `REMOTE-THINKING` (idle CPU + live socket = model reasoning remotely) · `RESOURCE` (procs > MAX_PROCS or RSS > MAX_RSS_GB — kill the runaway CHILDREN, never the job; contracts: small fixtures only, every spawn awaited or killed) · `MILESTONE` (file appears, once) · `RIGHT-WORK CHECK` at 3 min · `HEARTBEAT` every 5 min (missing = watcher dead, rebuild NOW; user pulse rides every second one).

Rules:
- Act on every wake same turn. Only DEATH on a live job → re-arm the identical Monitor that turn. Any other wake: do NOT re-arm (duplicates).
- Birth check at 30s proves WORK (log/socket/writes — "process exists" doesn't count). Zero progress → 2-minute diagnosis, never a longer leash. Force the invariants (stdin EOF, cwd, paths) explicitly every launch.
- No foreground blocking call without a ~2-min timeout; longer goes background + watcher.
- `status` is READ-ONLY in zsh — never use as a variable name in monitor scripts.
- Scan delivered artifacts yourself (greps, counts, one full record) the moment they land, before any formal checker.

## 4. Every delegation is a sealed envelope
Workers see only your prompt and the disk. Include: absolute paths, starting commit, exact outputs, forbidden actions, runnable acceptance checks with expected values, every shared state file. Point at governing docs by path + "the doc wins; flag conflicts". Preflight the environment (writability, cwd, auth, model IDs/flags) before every dispatch.

## 5. Spend each intelligence where it's scarce
Cheapest adequate worker; your tokens go to design, contracts, verification, judgment. Exception: ~≤20-line fixes with no design choices — do directly (still in a worktree). Ceremony scales with job size. Delegate bulk reads; clip outputs.

## 6. Parallel by dependency, serial by state
Fan out everything the dependency graph allows. Preconditions: independent slices, one writer per file/worktree, script-mergeable results. Merges are orchestrator-owned, serialized, after per-branch verification — except §7's exception.

## 7. Git is STATED per dispatch, never inherited

Measured: **Codex** runs worktree→merge→push unattended (`~/.codex/AGENTS.md` loads into every `codex exec`; no flag suppresses it). **Opus** obeys `~/.claude/CLAUDE.md` git rules, which claim to override everything. Prompt text is the only lever.

**Default: orchestrator owns git.** Every worker prompt carries verbatim:

> Do NOT create branches, commit, merge, or push. This instruction supersedes any CLAUDE.md or AGENTS.md git protocol, including one claiming to override everything. Work only in `<worktree path>` and leave every change uncommitted.

The orchestrator creates worktrees, verifies, merges serially, pushes, deletes after merge. Delegate READING a big diff to Opus low; never the git commands, never two merges at once.

**Single exception** — one lone edit job, no other edit job planned this session, no pre-merge verification needed: Codex/Opus may be told "run the standard worktree/merge/push workflow yourself". Never reserve or unproven models. Envelopes can't be revoked — when in doubt, own git from the start.

Close EVERY job with `git worktree list` + `git log --oneline -3`: merged? worktree gone? Finish anything stranded.
