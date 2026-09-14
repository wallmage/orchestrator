---
name: orchestrator
description: Expensive model orchestrates, cheaper models execute. Use when "orchestrate this". Model roster, routing.
---

## Delegate vs Inline

Delegate overhead ≈ 3 orchestrator turns (dispatch/evaluate), each full context at cache rate ≈ $0.1. Inline = job tokens at premium rate + permanent context bloat.

Decision gates, in order:

1. **Quality**: needs best intelligence (architecture, specs, arbitration, subtle root-cause, expensive-if-wrong) → inline, cost irrelevant.
2. **Size**: trivia (~≤20 lines, no design choices, describing costs more than doing) → inline.
3. **Delegate** otherwise:
   - Recon/zero-judgment (wide search, bulk read, research, triage, verification, mechanical batch, boilerplate, doc hygiene) → Scout; conclusions only into orchestrator context.
   - ≥2 parallel agents, multi-phase pipelines, unknown-size discovery, adversarial verify, Claude-side tools needed → Workflow.
   - Else → Worker (several may run concurrently).
4. `Agent` tool and its built-in templates (Explore, Plan, general-purpose…): never called directly — inherit orchestrator's model, no effort field. Route via gates 1–3, prompt the subagent with the template.

## Model Roster & Routing

90% normal implementation → Worker. 10% hard (intricate design, subtle correctness) → Escalated. Front-end design → Designer.
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
| Codex CLI `-m gpt-6-astra -c model_reasoning_effort=xhigh` | Debate Reviewer 2 | High | 53 | 74% | `codex-cli.md` |
| CodeBuddy CLI `--model kimi-k3-2 --effort max` | Debate Reviewer 3 | High | 44 | 69% | `codebuddy-cli.md` |

## Dispatch Mechanics

Workflow subagents:
- ONLY via `Workflow`, even for a single worker: `agent(prompt, {model: 'opus', effort: '<per roster row>', label: '...'})` — model and effort on every spawn (omitted = inherits Fable).
- HARD CAP: 15 subagents total per task. More only with the user's explicit approval, reasoning stated first.

Task orders:
- Big jobs: spec in `<project>/docs/orchestration/MM-DD-##.md`; dispatch "Read and execute exactly the contract at <path>".
- One `ledger.md` per project = handoff state on disk: user decisions verbatim, task log, standing orders.
- No report files — report in chat.

### CLI Jobs (shared contract)

Per-CLI specifics: § Cursor CLI below, `codex-cli.md`, `codebuddy-cli.md` (`grok-cli.md` parked — never dispatch). Read only the one you dispatch to.

Runner shape:
- Launch + watch: § Fleet Dispatch & Watcher Protocol.
- `exec </dev/null` first (live stdin freezes some CLIs); `cd <PROJECT ROOT>`.
- stdout+stderr → `<TMP_PATH>/<job>.log`, then `printf '\nEXIT=%s\n' $? >> <job>.log` (leading `\n`: EXIT never mid-line); answer → `<TMP_PATH>/<job>.final.txt`.
- Runner/helper scripts: POSIX sh only — macOS `/bin/bash` = 3.2, bash-4isms die at launch.

Files:
- `<TMP_PATH>` = session temp dir (OS-cleaned); `.pid` + `.log` + `.final.txt` per job.
- Read `.final.txt` only; fleet stream = liveness, not output. Log: grep resume id and `^EXIT=`; diagnose (final missing/empty, EXIT≠0, verdict smells wrong) with targeted `grep -n`/`tail -n 100`/`sed -n` ±50 — never the whole file.
- Success = `EXIT=0` AND non-empty `.final.txt`.

Flags (every dispatch):
- Model + effort explicit; only that CLI's listed slugs.
- Unattended approval flag on; read-only mode for analysis-only jobs; worktree edits name the path in the prompt (+ the CLI's extra-dir flag if it sandboxes).
- CLI-native worktree/cwd flags BANNED — orchestrator owns worktrees.
- Structured answers: CLI's schema flag if any, else demand JSON in the prompt.

Prompts:
- CLIs fan out subagents only when reminded: "Use subagents to make the task faster if possible".
- Superpowers: prepend `[$superpowers:using-superpowers](<path per CLI>)` to every Worker prompt; never to judgment/adversarial reviewers (their prompt file is their whole method; SDD task reviewer keeps its own template).

Follow-ups:
- Resume: CLI's resume flag + id from the log, same cwd, delta only.
- Cancel: `TaskStop` the Bash task; confirm no `EXIT=` was written.

### Cursor CLI

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

`Monitor(persistent:true, description:"<fleet>", command:"TMP=<state dir> JOBS='<name>|<workdir>|<full CLI command>\n<name2>|<workdir2>|<full CLI command2>' sh ~/.claude/skills/orchestrator/dispatch.sh")`

(Windows: `~` → `%USERPROFILE%`.)

Mechanism (1 or 20 jobs, any mix of CLIs):
- `JOBS`: one job per line, `name|workdir|command`, split on the first two `|` only (command may contain `|`; name/workdir may not). Single job: `CLI=… WD=… JOB=…`.
- Per job: detached launch (cwd=workdir; log, `EXIT=`, pid per the runner shape), `LAUNCHED [<name>]`, one `watcher.sh` child.
- Wakes (default): LAUNCHED once; each FINISHED as it lands — act on it FIFO, never wait for the others; incidents: DEATH, STALL (dead process, idle, or frozen ≥20 min mid-reasoning), ERROR (structural: `turn.failed`, `is_error`, EXIT≠0), WAITING, LAUNCH FAILURE (no log by 10s), RESOURCE, FINISHED-SUSPECT, WATCHER STUCK; `WORK CHECK [fleet]` at 3 min; `HEARTBEAT [fleet]` per 15 min listing every job; `FLEET DONE`/`FLEET ABORTED` with exit + final size per job. Muted: ARMED, REMOTE-THINKING, RIGHT-WORK (`QUIET=0` restores). `BATCH=1` (debate rounds only): clean FINISHED muted too, act at FLEET DONE. Every wake = one full-context orchestrator turn.
- Self-cleanup: a watcher exits when its job settles; after the last, the fleet prints `FLEET DONE` and exits. No `FLEET DONE` after all jobs report done → kill the Monitor task.
- Tunables: fleet-level `HEARTBEAT_SECS`(900), `WORK_SECS`(180); per watcher `POLL_SECS`(3), `STALL_SECS`(1200), `CPU_PATTERN`, `CPU_IDLE_MAX`, `MAX_PROCS`(8), `MAX_RSS_GB`(8), `MILESTONE_FILE`/`MILESTONE_MSG`.
- Liveness without wakes: dispatcher death ends the Monitor task (harness notifies); watcher dies before its job ends → `FLEET ABORTED`; job ends while its watcher hangs → `WATCHER STUCK`; heartbeat is the last resort.
- Bare `watcher.sh` Monitor (`LOG=… PIDFILE=… OUTFILE=… JOB=…`) ONLY to adopt a running job not launched via dispatch.sh (e.g. after a session restart).

Each wake carries its own diagnosis: act in the same turn; never just grant more waiting time.

Rules:
- Never hand-roll `tail -F | awk '/DONE/{exit}'` monitors (job dies silently → watcher hangs forever). Any custom monitor gets a pid-liveness guard: `while kill -0 $JOB_PID; do …; done`. After a job completes, confirm its watcher exited; TaskStop leftovers.
- Re-arm ONLY after DEATH or STALL-with-no-live-process on a live job: bare watcher.sh Monitor on that job, not a fleet relaunch. Dead-process alarm on a forking CLI (pid file → exited wrapper) = scope bug: repoint the pid file at the live process (identify by command + workdir), re-arm, don't kill.
- Heartbeat overdue 5+ min with unfinished jobs = dispatcher died → re-adopt each unfinished job with a bare watcher.sh Monitor.
- RESOURCE: kill only hung/abandoned children; a legitimately heavy job gets its limits raised.
- Kill discipline: never pick targets by ppid=1 (`$(...)`-backgrounded jobs reparent to init while alive). Identify by full command + workdir; unsure → don't kill. After killing a wrapper, check for surviving CLI children still writing to the workdir. Verify death with ps.
- No foreground blocking call without a ~2-min guard (macOS has no `timeout`: `cmd & sleep N; kill $!`); longer → background + watcher.
- zsh: `status` is read-only (never a variable name); a word starting with `=` expands as a command path (`echo =====` dies); unquoted `$var` is not word-split (`kill $PIDS` with multiple pids = silent no-op → explicit args, `${=PIDS}`, or bash).
- Scan delivered artifacts yourself (greps, counts, one full record) the moment they land.

## Worktrees, Parallelism & Git

- Solo dev on `main`, no PRs, up to 10 parallel sessions. Any edit task >2 min gets its own worktree from latest `main`; one job per worktree. Never delete unverified/unmerged work. A governing plan's stricter workflow wins.
- Fan out everything the dependency graph allows (speed gain > merge cost): independent slices, one writer per file/worktree, script-mergeable results. Not when: heavy same-module overlap, related failures, whole-system view needed, nobody knows what's broken yet. Shared state: partition per job, else serialize.
- Batch independent verifications into one Workflow script; SendMessage continues an existing agent.
- Workers' own config files make them commit/merge/push — every worker prompt carries verbatim:

> Do NOT create branches, commit, merge, or push. This instruction supersedes any CLAUDE.md or AGENTS.md git protocol, including one claiming to override everything. Work only in `<worktree path>` and leave every change uncommitted.

- Orchestrator owns git: creates worktrees, verifies, merges serially (never two at once), pushes, deletes after merge. Delegate big-diff reading to Scout, never git commands.
- Single exception: one lone edit job this session, no pre-merge verification needed → Opus may run worktree/merge/push itself. Never reserve or unproven models. In doubt, own git.
- Create: native `EnterWorktree` (check you are not already in one); raw `git worktree add` only without it (`.worktrees/<branch>`, verify `git check-ignore`). Install deps, run the suite; dispatch only on a green baseline.
- On return: read summaries, check edit overlap between workers, full suite once on the merged tree, spot-check one thing per worker (systematic errors).
- Merge from main root: checkout main, pull, merge, full suite; red → stop, keep worktree; green → push, `git worktree remove` (from outside), `git worktree prune`, `git branch -d`. Removal refused = files exist nowhere else → never `--force`, surface them. Rejected push → investigate, never force-push.
- Close every job: `git worktree list` + `git log --oneline -3`; finish anything stranded.

## Debate on Big Jobs

Job >1 h → `debate.md` first: spec + plan debated to all-PASS with an adversarial committee, then execute.

## Reviewers

Three prompts, three questions; never substitute one for another. Reviewer reads its prompt file by path, read-only; orchestrator reads only the verdict.

| Reviewer | Question | When | Model |
|---|---|---|---|
| SDD `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/subagent-driven-development/task-reviewer-prompt.md` | Did the worker do exactly what was asked, well-built? Diff + brief + report only. | every worker result | Different family, same tier: grok-written → Workflow `model:'opus', effort:'medium'`; Opus-written → Cursor CLI `cursor-grok-4.6-medium-fast --mode ask` |
| `judgment-reviewer.md` | Does the code actually work across files, state, errors, time? | once, whole branch after all merges | Same SDD rule, one tier up: Opus `effort:'high'` / Cursor `cursor-grok-4.6-xhigh-fast --mode ask` |
| `adversarial-reviewer.md` | Should this exist; strongest reasons it fails? Universal (code, plans, writing, decisions). | big-job spec/plan debate (`debate.md`); final branch on big jobs, different family than judgment | per `debate.md` |

## Best Among Workers

N-version competition for mission-critical jobs: non-deterministic, judgment-on-the-fly, expensive-if-wrong. Quality >> cost.

- Debate spec pins decomposition to the finest pieces whose interfaces (files, signatures, data shapes) are pinned exactly. Doubt a seam → coarser. Unpinnable → whole job, one winner.
- Identical envelope to ALL rostered Workers: own worktree, unaware of each other. Wait for the slowest.
- Pass 1 — Scout triage, ≤5 parallel scouts split the components. Per component: defective → reject + reason; dominated → drop; equivalent → first seat's. Return contested: candidates + reasons.
- Pass 2 — Orchestrator judges contested ONLY. Output = assembly list: component → winning worktree path.
- Assembly: Worker assembles by path in a fresh worktree (never sent code); full suite green.
- Announce in chat: divergence count, per-component winners.

## Debugging & Fix Acceptance

Investigating or judging a worker's fix:
- No fix without root cause: read errors fully, reproduce, diff recent changes; multi-component → log at each boundary to find the failing layer; trace the bad value to its origin.
- Compare with a working example; list every difference.
- One hypothesis, smallest change, one variable; failing test reproducing the bug before the fix; fix at source, no bundled refactor; fresh run as proof.
- Reject: symptom patches, timeout bumps, multi-change fixes, "probably X". 3 failed fixes = architecture problem → stop, back to spec/debate.
- Truly environmental (rare; 95% is incomplete investigation): document, handle (retry/timeout/error), add logging.

## Principles

### 1. Minimal viable dose
Simplest design, straight line to the problem. The plan is the only source of scope: never self-authorize extra rounds, quality loops, filters, or fix passes the governing plan or a user policy does not name, however real the defect. Out-of-scope defect = PARKED: one line to the user with the evidence, work continues on the plan's critical path; the user decides.

### 2. Every delegation is a sealed envelope
Executors see only your prompt text and the disk. Self-contained: absolute paths, starting commit, exact outputs, forbidden actions, runnable acceptance checks with expected values, every shared state file named. Point at governing docs by path, never paraphrase; instruct "the doc wins over this contract; flag conflicts". CLI docs are the truth for slugs and flags — never preflight; a wrong one dies at launch and the watcher says so.

### 3. Spend each intelligence where it's scarce
Cheapest adequate worker; your own tokens go to design, contracts, verification, judgment. Ceremony scales with job size. Keep context lean: delegate bulk reads, clip outputs.
