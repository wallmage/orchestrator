---
name: orchestrator
description: Expensive model orchestrates, cheaper models execute. Use when "orchestrate this". Model roster, routing.
---

## Performance, Cost

Orchestrator receives tasks, plans, decomposes, delegates, evaluates, synthesizes. Routing: adequate performance at lowest cost.

## Delegate vs Inline

Delegate overhead ≈ ≥3 orchestrator turns (dispatch/evaluate), each full context at cache rate ≈ 0.1 USD. Inline = job tokens at premium rate + permanent context bloat.

Decision gates, in order:

1. **Quality**: needs best intelligence (architecture, specs, arbitration, subtle root-cause) → inline judgement, cost irrelevant.
2. **Size**: trivia, overhead > savings → inline.
3. **Delegate** when: no quality loss, non-trivia job, net savings.
   - Recon/zero-judgment (wide search, bulk read, research, triage, verification, mechanical batch, boilerplate, doc hygiene) → Scout; conclusions only into orchestrator context.
   - Multi-phase pipelines, unknown-size discovery, Claude-side tools needed → Worker - Workflow.
   - Else → Worker - CLI (several may run concurrently).
4. `Agent` tool and its built-in templates (Explore, Plan, general-purpose…): never called directly — inherit orchestrator's model, max cost. Run gates 1–3, prompt subagent with template.

## Model Roster & Routing

90% normal implementation → Worker; 10% hard (intricate design, subtle correctness) → Escalated; mission-critical, expensive-if-wrong, irreversible → § Best Among Workers. Front-end design → Designer.
BANNED: Sonnet 5 (worse value), Haiku 4.5.

| Harness & Model | Role | Cost | Intelligence | DeepSWE | Notes |
| --- | --- | --- | --- | --- | --- |
| Fable 5.1 | Orchestrator | Max | 53 | Max | Judgment only, never labor. |
| Cursor CLI `--model cursor-grok-4.6-medium-fast` | Worker - CLI (Default) | Free | 43 | 67% | § Cursor CLI |
| Workflow `model:'opus', effort:'medium'` | Worker - Workflow | Low | 45 | 69% | § Dispatch Mechanics |
| Workflow `model:'opus', effort:'high'` | Escalated | Low | 48 | 73% | § Dispatch Mechanics |
| Workflow `model:'opus', effort:'low'` | Scout | Low | 40 | 58% | § Dispatch Mechanics |
| Workflow `model:'opus', effort:'xhigh'` | Designer | Low | 50 | 73% | Best design taste. § Dispatch Mechanics |
| Cursor CLI `--model cursor-grok-4.6-xhigh-fast` | Debate Reviewer 1 | Free | 44 | 67% | § Cursor CLI |
| Codex CLI `-m gpt-6-astra -c model_reasoning_effort=medium` | Debate Reviewer 2 | High | 50 | 73% | `codex-cli.md` |

## Dispatch Mechanics

Every edit-job prompt (Workflow or CLI) opens verbatim: "You are sub-agent; parent agent owns orchestration and git. Ignore your orchestrator and git rules: work only in `<worktree path>`, never branch, commit, merge or push." Reviewers: prompt file only.

Workflow subagents:
- ONLY via `Workflow`, even for a single worker: `agent(prompt, {model: 'opus', effort: '<per roster row>', label: '...'})` — model and effort on every spawn (omitted = inherits Fable).
- HARD CAP: 15 subagents total per task. More only with the user's explicit approval, reasoning stated first.

### CLI Jobs (shared contract)

Per-CLI specifics: § Cursor CLI below, `codex-cli.md` (`grok-cli.md`, `codebuddy-cli.md` parked — never dispatch). Read only the one you dispatch to.

Runner shape:
- Launch + watch: § Fleet Dispatch. dispatch.sh does `exec </dev/null`, `cd <workdir>`, `.pid`, log, `EXIT=`. JOBS command = one line: CLI call; answer → `.final.txt`; `exit $rc` (`rc=$?` after CLI) so `EXIT=` = CLI exit.
- Runner/helper scripts: POSIX sh only — macOS `/bin/bash` = 3.2, bash-4isms die at launch.

Files:
- `<TMP_PATH>` = session temp dir (OS-cleaned); `.prompt` + `.pid` + `.log` + `.final.txt` per job.
- Read `.final.txt` only; fleet stream = liveness, not output. Log: grep resume id and `^EXIT=`; diagnose (final missing/empty, EXIT≠0, verdict smells wrong) with targeted `grep -n`/`tail -n 100`/`sed -n` ±50 — never the whole file.
- Success = `EXIT=0` AND non-empty `.final.txt`.

Flags (every dispatch):
- Model + effort explicit; only that CLI's listed slugs; never preflight.
- Unattended approval flag on; read-only mode for analysis-only jobs; worktree edits: CLI's extra-dir flag if it sandboxes.
- CLI-native worktree/cwd flags BANNED — orchestrator owns worktrees.
- Structured answers: CLI's schema flag if any, else demand JSON in the prompt.

Prompts:
- Prompt → `<TMP_PATH>/<job>.prompt`; command reads `"$(cat …)"`. Never inline (3 quoting layers).
- CLIs fan out subagents only when reminded: "Use subagents to make the task faster if possible".
- Superpowers: prepend `[$superpowers:using-superpowers](<path per CLI>)` to every Worker prompt; never to judgment/adversarial reviewers (their prompt file is their whole method; SDD task reviewer keeps its own template).

Follow-ups:
- Resume: CLI's resume flag + id from the log, same cwd, delta only.
- Cancel: kill job tree, children first: `k(){ for c in $(pgrep -P "$1"); do k "$c"; done; kill "$1"; }; k $(cat <TMP_PATH>/<job>.pid)`; verify `ps`. `TaskStop` stops only the relay.

### Cursor CLI

JOBS command (one line, no single quotes — JOBS is single-quoted):

```sh
cursor-agent -p --force --trust --output-format stream-json --model <slug> "$(cat <TMP_PATH>/<job>.prompt)"; rc=$?; grep -a \"type\":\"result\" <TMP_PATH>/<job>.log | tail -1 | jq -r .result > <TMP_PATH>/<job>.final.txt; exit $rc
```

Files: log = NDJSON; resume id = first `"session_id"` in log. Success also needs last result line `"is_error":false`.

Flags:
- `--model cursor-grok-4.6-medium-fast` (worker, task reviewer) or `cursor-grok-4.6-xhigh-fast` (debate/judgment reviewer); every other slug BANNED. Ladder: `cursor-agent --list-models | grep grok`.
- `--force`: REQUIRED, else headless shell/edits blocked. Deny rules in `~/.cursor/cli-config.json` still win.
- `--trust`: skips workspace-trust prompt. `--approve-mcps` only if the job needs MCP servers.
- `--mode ask` = read-only; `--mode plan` = plan-only.
- Worktree edits: `cd` in, or `--add-dir <dir>`.
- No schema or image flag.
- `-w/--worktree`, `--workspace` BANNED.

Prompts:
- Fan-out = `Task` tool (built-in Explore/Bash/Browser, custom `.cursor/agents/*.md`; parallel when several calls share one message). Remind: "Use Task subagents in parallel to make the task faster".
- Superpowers: `~/.cursor/skills/using-superpowers/SKILL.md`.

Follow-ups:
- Resume: `--resume <session_id>`; `--continue` = latest.

### Fleet Dispatch & Watcher Protocol

ONE Monitor call launches and watches the fleet via `dispatch.sh` — never plain Bash, never a separate watcher step:

`Monitor(description:"<fleet>", timeout_ms:1800000, command:"TMP=<state dir> JOBS='<name>|<workdir>|<full CLI command>\n<name2>|<workdir2>|<full CLI command2>' sh ~/.claude/skills/orchestrator/dispatch.sh")`

(`\n` = real newline in the JSON string, not backslash-n. Windows: `~` → `%USERPROFILE%`.)

Monitor expires at 30 min, kills its process group → fleet runs detached, events → `<TMP>/fleet.events`, Monitor relays. Expiry notice → re-arm `Monitor(description:"<fleet>", timeout_ms:1800000, command:"RELAY=1 TMP=<state dir> sh ~/.claude/skills/orchestrator/dispatch.sh")`, lossless. Never relaunch with `JOBS` (refused while fleet lives). Same command adopts after session restart.

Mechanism (1 or 100 jobs, any mix of CLIs):
- `JOBS`: one job per line, `name|workdir|command`, split on the first two `|` only (command may contain `|`; name/workdir may not). Single job: `CLI=… WD=… JOB=…`. `TMP` required.
- Per job: detached launch (cwd=workdir; log, `EXIT=`, pid per the runner shape), `LAUNCHED [<name>]`, one `watcher.sh` child.
- Wakes (default): LAUNCHED once; each FINISHED as it lands — act on it FIFO, never wait for the others; incidents: DEATH, STALL (dead process, idle, or frozen ≥20 min mid-reasoning), WATCH ENDED (job tree dead), ERROR (structural: `turn.failed`, `is_error`, EXIT≠0), WAITING FOR INPUT, LAUNCH FAILURE (no log by 10s), RESOURCE, FINISHED-SUSPECT, WATCHER STUCK, MILESTONE, FLEET DEAD; `WORK CHECK [fleet]` at 3 min; `HEARTBEAT [fleet]` per 15 min listing every job; `FLEET DONE`/`FLEET ABORTED` with exit + final size per job. Muted: ARMING, ARMED, REMOTE-THINKING, RIGHT-WORK, WATCHER RESPAWNED (`QUIET=0` restores). `BATCH=1` (debate rounds only): clean FINISHED muted too, act at FLEET DONE. Every wake = one full-context orchestrator turn.
- Self-cleanup: a watcher exits when its job settles; after the last, `FLEET DONE`, relay exits. No `FLEET DONE` after all jobs done → kill `<TMP>/fleet.pid`, `TaskStop` relay.
- Tunables: fleet-level `HEARTBEAT_SECS`(900), `WORK_SECS`(180); per watcher `POLL_SECS`(3), `STALL_SECS`(1200), `CPU_PATTERN`, `CPU_IDLE_MAX`, `MAX_PROCS`(8), `MAX_RSS_GB`(8), `MILESTONE_FILE`/`MILESTONE_MSG` (fleet-wide).
- Liveness without wakes: fleet dies → `FLEET DEAD`; watcher dies mid-job → respawned once, else `FLEET ABORTED` at end; job ends, watcher hangs → `WATCHER STUCK`; heartbeat last resort.
- Bare `watcher.sh` Monitor (`LOG=… PIDFILE=… OUTFILE=… JOB=…`) ONLY to adopt a running job not launched via dispatch.sh.

Each wake carries its own diagnosis: act in the same turn; never just grant more waiting time.

Rules:
- Never hand-roll `tail -F | awk '/DONE/{exit}'` monitors (job dies silently → watcher hangs forever). Any custom monitor gets a pid-liveness guard: `while kill -0 $JOB_PID; do …; done`. After a job completes, confirm its watcher exited; kill leftovers.
- Re-arm ONLY after DEATH or STALL-with-no-live-process on a live job: bare watcher.sh Monitor on that job, not a fleet relaunch. Dead-process alarm on a forking CLI (pid file → exited wrapper) = scope bug: repoint the pid file at the live process (identify by command + workdir), re-arm, don't kill.
- `FLEET DEAD` or heartbeat overdue 5+ min → bare watcher.sh Monitor per unfinished job.
- RESOURCE: kill only hung/abandoned children; a legitimately heavy job gets its limits raised.
- Kill discipline: never pick targets by ppid=1 (`$(...)`-backgrounded jobs reparent to init while alive). Identify by full command + workdir; unsure → don't kill. After killing a wrapper, check for surviving CLI children still writing to the workdir. Verify death with ps.
- No foreground blocking call without a ~2-min guard (macOS has no `timeout`: `cmd & sleep N; kill $!`); longer → background + watcher.
- zsh: `status` is read-only (never a variable name); a word starting with `=` expands as a command path (`echo =====` dies); unquoted `$var` is not word-split (`kill $PIDS` with multiple pids = silent no-op → explicit args, `${=PIDS}`, or bash).
- Scan delivered artifacts yourself (greps, counts, one full record) the moment they land.

## Worktrees, Parallelism & Git

- Solo dev on `main`, no PRs, up to 10 parallel sessions. Any edit task >2 min gets its own worktree from latest `main`; one job per worktree. Never delete unverified/unmerged work (§ Best Among Workers losers excepted). A governing plan's stricter workflow wins.
- Fan out everything the dependency graph allows (speed gain > merge cost): independent slices, one writer per file/worktree, script-mergeable results. Not when: heavy same-module overlap, related failures, whole-system view needed, nobody knows what's broken yet. Shared state: partition per job, else serialize.
- Mechanical checks = Scout, batch independent checks into one Workflow script.
- Orchestrator owns git: create worktrees, verify, merge serially, delete after merge. Delegate big-diff reading to Scout, never git commands.
- Create: `EnterWorktree` (→ `.claude/worktrees/<name>`) from main, never inside another worktree; install deps. Suite green on main once before dispatch.
- On return: check edit overlap between workers; spot-check one thing per worker (systematic errors).
- Merge from main root; full suite on merged tree; green → remove worktree + branch, red → keep it. Push once, after judgment passes. Removal refused → never `--force`, surface the files. Never force-push.
- Close: no stranded worktrees, merge landed on main.

## Debate Big Jobs

Job >1 h → `debate.md` first: spec + plan debated with adversarial committee.

## Reviewers

Never substitute one reviewer for another. Reviewer reads its prompt file by path, read-only; orchestrator reads only the verdict.

| Reviewer | Question | When | Model |
|---|---|---|---|
| SDD `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/subagent-driven-development/task-reviewer-prompt.md` | Did the worker do exactly what was asked, well-built? Diff + brief + report only. | every worker result | Different family, same tier: grok-written → Workflow `model:'opus', effort:'medium'`; Opus-written → Cursor CLI `cursor-grok-4.6-medium-fast --mode ask` |
| `judgment-reviewer.md` | Does the code actually work across files, state, errors, time? | once, after all merges, before push | Same SDD rule, one tier up: Opus `effort:'high'` / Cursor `cursor-grok-4.6-xhigh-fast --mode ask` |
| `adversarial-reviewer.md` | Should this exist; strongest reasons it fails? Universal (code, plans, writing, decisions). | big-job spec/plan debate only (`debate.md`) | per `debate.md` |

## Best Among Workers

Quality >>> cost. 3 seats, one winner.

- Seats: Escalated, Debate Reviewer 1, Debate Reviewer 2. Same envelope, own worktree, unaware of each other. Wait for all three; dead seat → relaunch.
- Orchestrator picks the winner; losers deleted after merge.

## Ledger

`docs/orchestration/ledger.md` = current state, concise telegram; every entry dated MMDD; update whenever state changes. Contains: decisions; per job, each task's state (commit | worktree, session id, next step | pending), spec/plan paths if available. Cap 80 lines: delete oldest-dated entries until ≤80. Resume = read it + any spec/plan it names.

## Debugging & Fix

- Fix = root cause named, fixed at source; failing repro test before, green run after.
- 2 failed fixes → architecture problem → stop, orchestrator redesigns inline; big job → `debate.md`.

## Principles

- Simplest design, straight line to the problem. Scope = plan or request: no self-authorized extra passes, however real the defect. Out-of-scope defect → one line to user, continue; user decides.
- Executor sees only prompt and disk. Self-contained: absolute paths, acceptance checks with expected values. Governing docs by path, never paraphrased: "doc wins over this prompt; flag conflicts".
