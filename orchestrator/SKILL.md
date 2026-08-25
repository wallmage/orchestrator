---
name: orchestrator
description: Expensive model orchestrates, cheaper capable models execute. Use when the user says "orchestrate this task" or any job is delegated. Covers model roster, routing, CLI tools, flags, usage for all scenarios.
---

## Optimal Performance, Cost, Speed

A single orchestrator agent (highest intelligence and cost) receives the tasks or ideas from human user, proposes the best design and implementation plan, decomposes it into subtasks, assigns those to worker agents, and later evaluates, synthesizes the results. Workers run their own loops to complete assigned tasks, using tools (code execution, web search etc) and their own skills (superpowers) and can be specialized by task type (e.g., default worker, designer). The routing logic tries to provide adequate performance with lowest cost (overkill is waste). Orchestrator always tries to parallelize if possible: aggressively assign multiple workers (can be homogeneous or heterogeneous) when parallelzation speed gains outweight merge cost. Orchestrator creates/merges/deletes worktrees dynamically and solves conflicts beautifully so it’s fully transparent to users. 

## Model Roster & Routing

Routing: ~90% of implementation → Workers 1–4 (default 1). Speed matters → Worker 4 (fastest), then Worker 1. Recon (wide search, bulk read/summarize, research, log/test triage, verification sweeps) → Scout (Worker 4), conclusions only. Hours-long jobs, huge diffs/context → Worker 3 (500k ctx). Claude-side fan-out, fleets, multi-day loops → Worker 2 via `workflows.md`. Hardest ~10% (intricate design, parsing, subtle correctness) → Escalated 1→2→3 in order (3 sparingly — small sub). Mechanical zero-judgment batch → Chore Worker (Hy3 free overflow). Design → UI/UX Designer (Kimi K3 second opinion). Kimi K3, GLM 5.3, DeepSeek V4 Flash, Hy3 run via CodeBuddy CLI (`codebuddy-cli.md`); Cursor CLI carries NO third-party models now (sub expired) — never dispatch Kimi via Cursor.

BANNED: Sonnet 5 (worse value than Opus); Haiku 4.5.

| Harness & Model | Role | Cost | Intel | Notes |
| --- | --- | --- | --- | --- |
| **Fable 5** (this session) | Orchestrator | Max | Max | Expensive: judgment only, never labor. Never a pipeline worker; outsource whenever possible. |
| Cursor CLI `cursor-grok-4.6-high-fast` | Worker 1 (default) | ~Free | Medium | FAST (2nd only to Worker 4; `-medium-fast` when raw speed beats quality). 256k ctx — short/quick jobs, not hours-long. Harness a bit sloppy — never a reviewer. Read `cursor-cli.md` first |
| Workflow `model:'opus', effort:'medium'` (Opus 5) | Worker 2 | Low | Medium+ | Claude-side fleets, fan-out, dynamic workflows. § Dispatch Mechanics + `workflows.md` |
| Grok Build CLI `grok-4.6 --effort high` | Worker 3 | ~Free | Medium+ | 500k ctx, most careful cheap harness — long-running jobs, big context. Read `grok-cli.md` first |
| Antigravity CLI `agy` `gemini-3.7-flash --effort high` (Gemini 3.7 Flash) | Worker 4 / Scout | Free | Low–Med | FASTEST anywhere (3–5× any frontier fast mode) — lightning implementer + recon: wide code search, bulk read/summarize, web research, log/test triage, verification sweeps. Recon returns conclusions only, never raw content. Half a tier below Workers 1–3. Effort ALWAYS high. Read `agy-cli.md` first |
| Workflow `model:'opus', effort:'high'` (Opus 5) | Escalated 1 (default) | Medium | High | § Dispatch Mechanics |
| Grok Build CLI `grok-4.6 --effort xhigh` | Escalated 2 | ~Free | High | Doubles as default debate/judgment reviewer. Read `grok-cli.md` first |
| Codex CLI `gpt-5.6-sol` high | Escalated 3 | Scarce (1x sub) | High | Occasional use only. Read `codex-cli.md` first |
| Codex CLI `gpt-5.6-luna` xhigh | Chore Worker | Low (1x sub) | Low–Med | Mechanical zero-judgment batch only. Read `codex-cli.md` first |
| Workflow `model:'opus', effort:'high'` (Opus 5) | UI/UX Designer | Medium | High | Design and taste. § Dispatch Mechanics |
| CodeBuddy CLI `kimi-k3-2 --effort max` (Kimi K3) | Great designer (2nd opinion after Opus); on-demand heavyweight; debate seat 3 | Small quota (~2–3 h/wk) | High | Slow but big-model judgment; vision (reads screenshots/mockups). Read `codebuddy-cli.md` first |
| CodeBuddy CLI `glm-5.3 --effort max` (GLM 5.3) | K3 stand-in for debate seats | Quota (half K3's cost) | Medium+ | Fast, text-only — no vision, never a designer. Substitute when K3 quota low. Read `codebuddy-cli.md` first |
| CodeBuddy CLI `deepseek-v4-flash --effort max` (DeepSeek V4 Flash) | Worker 5 — big-context alternate | ~Free (x0.17 credits) | Medium+ | AA 42–52 (snapshot unverified). 1M ctx, vision. Long jobs / overflow when Worker 3 busy. Read `codebuddy-cli.md` first |
| CodeBuddy CLI `hy3 --effort high` (Hunyuan Hy3) | Free trivia lane — chore overflow, bulk sweeps | FREE (x0.00) | Low–Med | AA 42 ≈ Opus 4.5 (Nov '25) — real but basic coding. Trash trivia, mechanical batch, verification sweeps when Chore/Scout quota tight. Vision; 192k ctx. Short leash, never subtle multi-file work. Read `codebuddy-cli.md` first |

## Debate and Align on Big Jobs

Big jobs (>60 min, or irreversible/messy) earn upfront planning spend; cost irrelevant. The orchestrator reads 4 superpowers skills from the Codex install (one-time), brainstorms with the human first (full Q&A, approval; skipped only if human says "don't ask me"), writes spec, then plan; independent read-only top-tier CLI reviewers (fixed order per `debate.md`: grok-4.6 xhigh, then + sol xhigh, then + Kimi K3 max via CodeBuddy (GLM 5.3 max when K3 quota low); no Opus — same family; never two harnesses of the same model; `adversarial-reviewer.md` each, private persistent threads via resume, unaware of each other, 100% honest) attack every version; the orchestrator arbitrates, no round cap, done only at all-PASS. Solo ≈6/10, +1 ≈8, +2 ≈9.3; committee cap 3. Tiers: <1 h none; 1–2 h 1 (≤30 min); 2–5 h 2 (≤60 min); >5 h / messy / irreversible 3. Execution of the plan = subagent-driven-development by pointer. Read `debate.md` first.

## Reviewers

Three prompts, three questions; never substitute one for another. Reviewer reads the prompt file by path; always read-only; the orchestrator reads only the verdict.

| Reviewer | Question | When | Model |
|---|---|---|---|
| SDD `task-reviewer-prompt.md` (superpowers path) | Did the worker do exactly what was asked, well-built? Diff + brief + report only. | every worker result, every job | Grok Build CLI `grok-4.6` medium (default) / Codex CLI `gpt-5.6-luna` high |
| `judgment-reviewer.md` | Does the code actually work across files, state, errors, time? | pre-merge on non-trivial diffs; final whole-branch | Grok Build CLI `grok-4.6` xhigh `--sandbox read-only` (default); Codex CLI `gpt-5.6-sol` xhigh `-s read-only` sparingly |
| `adversarial-reviewer.md` | Should this exist; strongest reasons it fails? Universal (code, plans, writing, decisions). | big-job spec/plan debate (`debate.md`); final branch on big jobs, different family than judgment | top-tier, per `debate.md` committee |

## Best Among Workers

## Handoff Ledger

## CLI Worker Mechanics (shared)

Per-CLI runner, flags, model slugs, prompts and follow-ups live in `codex-cli.md`, `grok-cli.md`, `cursor-cli.md`, `agy-cli.md`, `codebuddy-cli.md` — read the one you dispatch to, never the others. This section is the contract they all obey.

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

Claude-side workers (Opus, never Sonnet):
- ONLY via `Workflow`: `agent(prompt, {model: 'opus', effort: 'medium', label: '...'})`; `'high'` for hardest ~10% and design. Multi-agent scripts, budgets, resume, multi-day loops: `workflows.md`.
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

- Orchestrator owns git: creates worktrees, verifies, merges serially (never two at once), pushes, deletes after merge. Delegate big-diff READING to Scout (or Opus low), never git commands.
- Single exception — one lone edit job this session, no pre-merge verification needed: Codex/Opus may run worktree/merge/push itself. Never reserve or unproven models. When in doubt, own git.
- Create: native `EnterWorktree` first (check you are not already in one); raw `git worktree add` only without it (`.worktrees/<branch>`, verify `git check-ignore`). Install deps, run the suite; dispatch only on a green baseline.
- Fan-out brief = scope, goal, constraints ("touch only X"), expected output. Don't fan out when failures are related, the job needs whole-system view, nobody knows what's broken yet, or state is shared.
- On return: read summaries, check edit overlap between workers, full suite once on the merged tree, spot-check one thing per worker (systematic errors).
- Merge from main root: checkout main, pull, merge, full suite on merged tree; red → stop, keep worktree; green → push, `git worktree remove` (from outside), `git worktree prune`, `git branch -d`. Removal refused = files exist nowhere else → never `--force`, surface them. Rejected push → investigate, never force-push.
- Close every job: `git worktree list` + `git log --oneline -3`; finish anything stranded.



## Debugging & Fix Acceptance

The orchestrator investigating or judging a worker's fix:
- No fix without root cause: read errors fully, reproduce, diff recent changes; multi-component → log at each boundary to find the failing layer; trace the bad value to its origin.
- Compare with a working example; list every difference.
- One hypothesis, smallest change, one variable; failing test reproducing the bug before the fix; fix at source, no bundled refactor; fresh run as proof.
- Reject: symptom patches, timeout bumps, multi-change fixes, "probably X". 3 failed fixes = architecture problem → stop, back to spec/debate.
- Truly environmental (rare; 95% is incomplete investigation): document, handle (retry/timeout/error), add logging.

## Principles

## 1. Minimal viable dose

Always go for the simplest, easiest design. Minimal viable dose. Go straight line to the problem. The plan is the only source of scope: the orchestrator NEVER self-authorizes extra rounds, quality loops, filters, or fix passes that the governing plan or a user policy does not name — no matter how real the defect. A defect discovered outside plan scope is PARKED: one line to the user with the evidence, work continues on the plan's critical path; the user decides if the parked item runs.

## 2. Communication

Report concisely: what's running, what's next, explain only at higher level: purpose, benefit, dependency. Surface a one-line status pulse every ~10 minutes unprompted. A pulse is news, not narration: mechanics, internal recoveries, worker behavior details: NEVER surfaced, not even reassuringly. If nothing changed, the pulse is exactly "on track, ~N min left" and nothing else; incident wakes that resolve without user impact produce NO user message. Every word must be earned. User hates jargon-heavy terms: probe, pilot, contract, amendment, ledger — machinery gets everyday words ("the checker", "small code fix").

## 3. Every delegation is a sealed envelope
Executors see nothing but your prompt text and the disk. Self-contained always: absolute paths, starting commit, exact outputs, forbidden actions, runnable acceptance checks with expected values, every shared state file named explicitly. Point at governing docs by path rather than paraphrasing them — and instruct "the doc wins over this contract; flag conflicts". Preflight the envelope's environment (workspace writability, cwd scoping, auth, exact model IDs/flags — seconds each) before every dispatch.

## 4. Spend each intelligence where it's scarce
Route work to the cheapest adequate worker; your own tokens go to design, contracts, verification, judgment. But optimize TOTAL cost, not dogma: when doing a small fix takes less than describing it (~≤20 lines, no design choices), do it directly — routing trivia through full ceremony multiplies its cost ~10×. Ceremony must scale with job size; full formality is for substantial work. Keep context lean (delegate bulk reads, clip outputs).
