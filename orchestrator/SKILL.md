---
name: orchestrator
description: Expensive model orchestrates, cheaper models execute. Use when "orchestrate this". Model roster, routing.
---

## Performance, Cost, Speed

Orchestrator receives tasks from user, proposes best implementation plan, decomposes into subtasks, delegate to workers, and evaluates, synthesizes results. Routing logic: adequate performance with lowest cost. Orchestrator always aggressively assigns multiple workers when parallelzation speed gains outweight merge cost. Orchestrator creates/merges/deletes worktrees dynamically and solves conflicts beautifully, transparent to user. 

## Delegate vs Inline

Delegate overhead ≈ minimal 3 orchestrator turns (dispatch/evaluate); each turn = full context at orchestrator cache rate, $0.1 per turn. Inline = job tokens at orchestrator's premium rate + permanent context bloat.

Decision Gates:

1. **Quality**: need absolute best intelligence (architecture, specs, arbitration, subtle root-cause, expensive-if-wrong)? → inline. Cost irrelevant. Stop.
2. **Size**: trivia, overhead > savings → inline. Stop.
3. **Delegate** when: no quality loss, non-trivia job, net savings.
   - Recon/zero-judgment (wide search, bulk read, research, triage, verification, mechanical batch, boilerplate/fixtures, doc hygiene...) → Scout, conclusions only, no noise into Orchestrator context.
   - Brute-force parallelism → Workflow: ≥2 parallel agents, multi-phase pipelines, unknown-size discovery, adversarial verify, fleets, needs Claude-side tools.
   - Everything else → Worker. Several Workers may run concurrently.
4. **Built-in Agent templates** (claude-code-guide, Explore, Plan, general-purpose…): NEVER call directly — subagent inherits orchestrator's model, max cost. Run gates 1–3, prompt subagent with template.

## Model Roster & Routing

90% normal implementation → Worker. 10% hard (intricate design, subtle correctness) → Escalated. Front-End Design → Designer. 
BANNED: Sonnet 5 (worse value); Haiku 4.5.

| Harness & Model | Role | Cost | Intelligence | DeepSWE | Notes |
| --- | --- | --- | --- | --- | --- |
| Fable 5.1 | Orchestrator | Max | 53 | Max | Expensive: judgment only, never labor. Never pipeline worker. |
| Cursor CLI `--model cursor-grok-4.6-medium-fast` | Worker - CLI (Default) | Free | 43 | 67% | § Cursor CLI |
| Workflow `model:'opus', effort:'medium'` | Worker - Workflow | Low | 45 | 69% | § Dispatch Mechanics |
| Workflow `model:'opus', effort:'high'` | Escalated | Low | 48 | 73% | § Dispatch Mechanics |
| Workflow `model:'opus', effort:'low'` | Scout | Low | 40 | 58% | § Dispatch Mechanics |
| Workflow `model:'opus', effort:'xhigh'` | Designer | Low | 50 | 73% | Best design taste. § Dispatch Mechanics |
| Cursor CLI `--model cursor-grok-4.6-xhigh-fast` | Debate Reviewer 1 | Free | 44 | 67% | § Cursor CLI |
| Codex CLI `-m gpt-6-astra -c model_reasoning_effort=xhigh` | Debate Reviewer 2 | High | 53 | 74% | `codex-cli.md` |
| CodeBuddy CLI `--model kimi-k3-2 --effort max` | Debate Reviewer 3 | High | 44 | 69% | `codebuddy-cli.md` |

## Dispatch Mechanics

Claude-side workers (Opus, never Sonnet):
- ONLY via `Workflow`: `agent(prompt, {model: 'opus', effort: '<per roster row>', label: '...'})`.
- Model AND effort stated every spawn.
- HARD CAP: 15 subagents total per task, summed across every Workflow run and batch. More ONLY with the user's explicit approval, reasoning stated first.
- One worker = still a one-`agent()` Workflow.
- `Agent` tool BANNED (no effort field).

Task orders:
- Big jobs: spec in `<project>/docs/orchestration/MM-DD-##.md`; dispatch "Read and execute exactly the contract at <path>".
- One `ledger.md` per project: user decisions verbatim, task log, standing orders.
- No report files — report in chat.

### CLI Workers (shared contract)

Cursor lives below; `codex-cli.md`, `codebuddy-cli.md` hold the rest (`grok-cli.md` = parked, no sub — never dispatch) — read the one you dispatch to, never the others. This is the contract every CLI obeys.

Runner shape (every CLI):
- ONE Monitor call launches AND watches the whole fleet via `dispatch.sh` — never plain Bash, never a separate watcher step. Full mechanism: § Fleet Dispatch & Watcher Protocol.
- `exec </dev/null` first (a live stdin pipe freezes some CLIs), `echo $$ > <TMP_PATH>/<job>.pid`, `cd <PROJECT ROOT>` (never `-C`/`--cwd`-style flags).
- stdout+stderr → `<TMP_PATH>/<job>.log`; then `printf '\nEXIT=%s\n' $? >> <job>.log` (leading `\n` so EXIT= never lands mid-line); final answer → `<TMP_PATH>/<job>.final.txt`.
- Runner/helper scripts: POSIX sh only — macOS `/bin/bash` = 3.2 (no `declare -A`, no `${var,,}`); bash-4isms die at launch.

Files:
- `<TMP_PATH>` = this session's temp directory; one `.pid` + `.log` + `.final.txt` per job; OS-cleaned, no manual cleanup.
- Read `.final.txt`, NEVER the log. Grep the log only for the resume id and `^EXIT=`.
- Success = `EXIT=0` AND non-empty `.final.txt`.

Flags (every dispatch):
- Model AND effort stated explicitly; only slugs listed for that CLI.
- Unattended approval flag on; read-only mode for analysis-only jobs; worktree edits name the path in the prompt (+ the CLI's extra-dir flag if it sandboxes).
- CLI-native worktree flags BANNED — orchestrator owns worktrees.
- Structured answers: use the CLI's schema flag when it has one, otherwise demand JSON in the prompt.

Prompts:
- Every CLI can fan out subagents but won't unless reminded: "Use subagents to make the task faster".
- **Superpowers:** prepend `[$superpowers:using-superpowers](<path per CLI>)` to every Worker prompt — NEVER to judgment/adversarial reviewers (their prompt file is their whole method; SDD task reviewer keeps its superpowers template). TDD is enforced as verifiable acceptance checks (failing-tests-first, tests present in the diff), not as trust.

Follow-ups:
- Resume with the CLI's resume flag + id from the log, same cwd, send only the delta (memory intact).
- Cancel: `TaskStop` the Bash task; confirm no `EXIT=` was written.

### Cursor CLI
<!-- cli: cursor-agent :: update: cursor-agent update :: help: cursor-agent --help :: models: cursor-agent --list-models -->

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>
cursor-agent -p --force --trust --output-format stream-json --model <slug> \
  "<prompt>" > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"type":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.result' > <TMP_PATH>/<job>.final.txt
```

Files: log = NDJSON (liveness); resume id = first `"session_id"` in log. Success also needs last result line `"is_error":false`.

Flags:
- `--model <slug>` EVERY dispatch; effort + fast baked into slug. Grok ONLY, fast ONLY: `cursor-grok-4.6-{low,medium,high,xhigh}-fast` — lanes: `medium-fast` = worker | `xhigh-fast` = debate reviewer. Every other slug BANNED. Re-check ladder: `cursor-agent --list-models | grep grok`.
- `--force`: REQUIRED — else headless shell/edits blocked. Deny rules in `~/.cursor/cli-config.json` still win.
- `--trust`: skip workspace-trust prompt. `--approve-mcps` only if job needs MCP servers.
- `--mode ask` = analysis-only (read-only); `--mode plan` = plan-only.
- Worktree edits: `cd` in, or `--add-dir <dir>`.
- No schema flag (demand JSON in prompt), no image flag.
- `-w/--worktree` + `--workspace` BANNED — always `cd`.

Prompts:
- Fans out via `Task` tool (built-in Explore/Bash/Browser, custom `.cursor/agents/*.md`; parallel when several calls in one message). Remind: "Use Task subagents in parallel to make the task faster".
- Superpowers: `~/.cursor/skills/using-superpowers/SKILL.md`.

Follow-ups:
- Resume: same cmd + `--resume <session_id>` — same cwd. `--continue` = latest.
- Review: normal job + `--mode ask`.

### Fleet Dispatch & Watcher Protocol

CLI workers are launched and watched by ONE Monitor call — `dispatch.sh` is the only launch path (never plain Bash, never a separate watcher step):

`Monitor(persistent:true, description:"<fleet>", command:"TMP=<state dir> JOBS='<name>|<workdir>|<full CLI command>\n<name2>|<workdir2>|<full CLI command2>' sh ~/.claude/skills/orchestrator/dispatch.sh")`

(Windows: `~` → `%USERPROFILE%`.)

Mechanism — same single call for 1 or 20 combos across any mix of CLIs:
- `JOBS`: one job per line, `name|workdir|command` — split on the first two `|` only, so the command may contain `|`; name/workdir may not. Single-job shorthand: `CLI=… WD=… JOB=…` instead of JOBS.
- Per job, dispatch.sh: launches the command detached with cwd=workdir (`exec </dev/null`, stdout+stderr → `<TMP>/<name>.log`, `EXIT=n` appended, pid → `<name>.pid`), emits `LAUNCHED [<name>]`, and starts one `watcher.sh` child scoped to that job.
- Wakes (default): LAUNCHED once; each job's FINISHED the moment it lands — act on it, FIFO, never hold it for the others; incidents — DEATH, STALL (dead process, idle, or frozen ≥20 min mid-reasoning), ERROR (structural: `turn.failed`, `is_error`, EXIT≠0), WAITING, LAUNCH FAILURE, RESOURCE, FINISHED-SUSPECT, WATCHER STUCK; one `WORK CHECK [fleet]` at 3 min; ONE `HEARTBEAT [fleet]` per 15 min listing every job, whatever the fleet size; `FLEET DONE` / `FLEET ABORTED` with exit + final size per job. ARMED, REMOTE-THINKING, RIGHT-WORK never wake (`QUIET=0` restores them). `BATCH=1` = debate rounds only: clean FINISHED muted too, act at FLEET DONE. Every wake = one full-context orchestrator turn.
- Self-cleanup: when a job settles its watcher exits; when the last one settles the fleet prints `FLEET DONE` and exits itself. A missing `FLEET DONE` after all jobs report done = kill the Monitor task.
- Tunables pass through to every watcher: `POLL_SECS`(3), `HEARTBEAT_SECS`(300), `CPU_PATTERN`, `CPU_IDLE_MAX`, `MAX_PROCS`(8), `MAX_RSS_GB`(8), `MILESTONE_FILE`/`MILESTONE_MSG`.
- Liveness without wakes: dispatcher death ends the Monitor task (harness notifies); a watcher dying before its job ends → `FLEET ABORTED`; a job ending while its watcher hangs → `WATCHER STUCK`; heartbeat is the last resort.
- Read `<TMP>/<name>.final.txt` for results (per the CLI contract); the fleet stream is for liveness, not output.
- Bare `watcher.sh` via its own Monitor (`LOG=… PIDFILE=… OUTFILE=… JOB=…`) remains ONLY for adopting an already-running job you did not launch through dispatch.sh (e.g., after a session restart).

Each wake message names its condition and carries its own diagnosis — act on it in the same turn; never respond by granting more waiting time.

Rules:
- NEVER hand-roll `tail -F | awk '/DONE/{exit}'` monitors — if the job dies without printing the magic line, the watcher hangs forever and litters the task panel. Always use watcher.sh (process-aware, self-terminating), or guard any custom monitor with a pid-liveness loop: `while kill -0 $JOB_PID; do ...; done` so watcher death follows job death. After a watched job completes, confirm its watcher exited; TaskStop leftovers immediately.
- Re-arm ONLY after DEATH or STALL-with-no-live-process on a live job; never re-arm on any other wake. Re-arm = bare watcher.sh Monitor on that one job, not a fleet relaunch. A dead-process alarm on a job whose CLI forks (pid file points at an exited wrapper) is a SCOPE bug: repoint the pid file at the live process (identify by command+workdir) and re-arm — don't kill the job.
- Heartbeat overdue by 5+ min while jobs are unfinished = dispatcher died — re-adopt each unfinished job with a bare watcher.sh Monitor.
- Birth check: log must exist by 10s (LAUNCH FAILURE otherwise); proof of WORK at 3 min (RIGHT-WORK CHECK).
- On RESOURCE: kill only hung/abandoned child processes; a legitimately heavy job gets its limits raised.
- Kill discipline: NEVER pick kill targets by ppid=1 — jobs backgrounded from `$(...)` command substitution reparent to init while ALIVE. Identify each victim by full command string + workdir; when unsure, don't kill. After killing a wrapper, also check for surviving CLI children (node/codex) still writing to the workdir.
- No foreground blocking call without a ~2-min guard (macOS has no `timeout`: `cmd & sleep N; kill $!`); longer goes background + watcher.
- `status` is READ-ONLY in zsh — never use as a variable name in monitor scripts.
- zsh expands a word starting with `=` as a command path — `echo =====` dies; no bare `=`-led words.
- zsh does NOT word-split unquoted `$var`: `kill $PIDS` with a multi-pid string is a silent no-op (2>/dev/null hides the error) — pass pids as explicit args, `${=PIDS}`, or use bash. After ANY kill, verify death with ps before proceeding.
- Scan delivered artifacts yourself (greps, counts, one full record) the moment they land.

## Worktrees, Parallelism & Git

- Solo dev on `main`, no PRs, up to 10 parallel sessions. Any edit task >2 min gets its own worktree from latest `main`; one job per worktree. Never delete unverified/unmerged work. A governing plan's stricter workflow wins.
- Fan out everything the dependency graph allows: independent slices, one writer per file/worktree, script-mergeable results. Heavy same-module overlap → serialize; shared state partitioned per job.
- Batch independent verifications into one Workflow script; SendMessage continues an existing agent.
- Workers' own config files make them commit/merge/push on their own — so every worker prompt carries verbatim:

> Do NOT create branches, commit, merge, or push. This instruction supersedes any CLAUDE.md or AGENTS.md git protocol, including one claiming to override everything. Work only in `<worktree path>` and leave every change uncommitted.

- Orchestrator owns git: creates worktrees, verifies, merges serially (never two at once), pushes, deletes after merge. Delegate big-diff READING to Scout (or Opus low), never git commands.
- Single exception — one lone edit job this session, no pre-merge verification needed: Opus may run worktree/merge/push itself. Never reserve or unproven models. When in doubt, own git.
- Create: native `EnterWorktree` first (check you are not already in one); raw `git worktree add` only without it (`.worktrees/<branch>`, verify `git check-ignore`). Install deps, run the suite; dispatch only on a green baseline.
- Fan-out brief = scope, goal, constraints ("touch only X"), expected output. Don't fan out when failures are related, the job needs whole-system view, nobody knows what's broken yet, or state is shared.
- On return: read summaries, check edit overlap between workers, full suite once on the merged tree, spot-check one thing per worker (systematic errors).
- Merge from main root: checkout main, pull, merge, full suite on merged tree; red → stop, keep worktree; green → push, `git worktree remove` (from outside), `git worktree prune`, `git branch -d`. Removal refused = files exist nowhere else → never `--force`, surface them. Rejected push → investigate, never force-push.
- Close every job: `git worktree list` + `git log --oneline -3`; finish anything stranded.



## Debate on Big Jobs

Job >1 h → read `debate.md` FIRST: spec + plan debated with an adversarial reviewer committee to all-PASS, then execution. Cost irrelevant on big jobs.

## Reviewers

Three prompts, three questions; never substitute one for another. Reviewer reads the prompt file by path; always read-only; the orchestrator reads only the verdict.

| Reviewer | Question | When | Model |
|---|---|---|---|
| SDD `task-reviewer-prompt.md` (superpowers path) | Did the worker do exactly what was asked, well-built? Diff + brief + report only. | every worker result, every job | Different family than the author, same tier: grok-written → Workflow `model:'opus', effort:'medium'` (in-session, zero overhead); Opus-written → Cursor CLI `cursor-grok-4.6-medium-fast` `--mode ask`. Never Scout (recon, not judgment), never the author's own model. |
| `judgment-reviewer.md` | Does the code actually work across files, state, errors, time? | once, final whole-branch after all merges | Cursor CLI `cursor-grok-4.6-xhigh-fast` `--mode ask` (default); Codex CLI `gpt-6-astra` xhigh `-s read-only` sparingly |
| `adversarial-reviewer.md` | Should this exist; strongest reasons it fails? Universal (code, plans, writing, decisions). | big-job spec/plan debate (`debate.md`); final branch on big jobs, different family than judgment | top-tier, per `debate.md` committee |

## Best Among Workers

N-version competition for mission-critical jobs: non-deterministic, judgment-on-the-fly, expensive-if-wrong. Quality >> cost.

- § Debate: spec pins decomposition to smallest swappable granularity — finest pieces whose interfaces (files, signatures, data shapes) are pinned exactly. Doubt a seam → coarser. Unpinnable → whole job, one winner.
- Identical envelope to ALL rostered Workers: own worktree, unaware of each other. Wait for the slowest.
- Pass 1 — Scout triage, ≤5 parallel scouts split the components. Per component: defective → reject + reason; dominated → drop; equivalent → settle as first seat's. Return contested: candidates + reasons.
- Pass 2 — Orchestrator judges contested ONLY. Output = assembly list: component → winning worktree path.
- Assembly: Worker assembles the list in a fresh worktree by path, never sent code; assembly full suite test green.
- Announce in chat: divergence count, per-component winners.

## Handoff Ledger

State lives on disk

## Debugging & Fix Acceptance

The orchestrator investigating or judging a worker's fix:
- No fix without root cause: read errors fully, reproduce, diff recent changes; multi-component → log at each boundary to find the failing layer; trace the bad value to its origin.
- Compare with a working example; list every difference.
- One hypothesis, smallest change, one variable; failing test reproducing the bug before the fix; fix at source, no bundled refactor; fresh run as proof.
- Reject: symptom patches, timeout bumps, multi-change fixes, "probably X". 3 failed fixes = architecture problem → stop, back to spec/debate.
- Truly environmental (rare; 95% is incomplete investigation): document, handle (retry/timeout/error), add logging.

## Principles

### 1. Minimal viable dose

Always go for the simplest, easiest design. Minimal viable dose. Go straight line to the problem. The plan is the only source of scope: the orchestrator NEVER self-authorizes extra rounds, quality loops, filters, or fix passes that the governing plan or a user policy does not name — no matter how real the defect. A defect discovered outside plan scope is PARKED: one line to the user with the evidence, work continues on the plan's critical path; the user decides if the parked item runs.

### 2. Every delegation is a sealed envelope
Executors see nothing but your prompt text and the disk. Self-contained always: absolute paths, starting commit, exact outputs, forbidden actions, runnable acceptance checks with expected values, every shared state file named explicitly. Point at governing docs by path rather than paraphrasing them — and instruct "the doc wins over this contract; flag conflicts". CLI docs are the truth for slugs and flags — never preflight them; a wrong one dies at launch and the watcher says so.

### 3. Spend each intelligence where it's scarce
Route work to the cheapest adequate worker; your own tokens go to design, contracts, verification, judgment. But optimize TOTAL cost, not dogma: when doing a small fix takes less than describing it (~≤20 lines, no design choices), do it directly — routing trivia through full ceremony multiplies its cost ~10×. Ceremony must scale with job size; full formality is for substantial work. Keep context lean (delegate bulk reads, clip outputs).
