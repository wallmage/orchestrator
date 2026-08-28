---
name: orchestrator
description: Expensive model orchestrates, cheaper models execute. Use when the user says "orchestrate this". Model roster, routing.
---

## Optimal Performance, Cost, Speed

Orchestrator receives tasks from user, proposes best implementation plan, decomposes into subtasks, delegate to workers, and evaluates, synthesizes results. Routing logic: adequate performance with lowest cost. Orchestrator always aggressively assigns multiple workers when parallelzation speed gains outweight merge cost. Orchestrator creates/merges/deletes worktrees dynamically and solves conflicts beautifully, transparent to user. 

## Delegate vs Inline

Delegate overhead ≈ minimal 3 orchestrator turns (dispatch/evaluate job); each turn = full context at orchestrator cache rate, often > $0.1 per turn. Inline = job tokens at orchestrator's premium rate + permanent context bloat.

Decision Gates:

1. **Quality**: need absolute best intelligence (architecture, specs, arbitration, subtle root-cause, expensive-if-wrong)? → inline. Cost irrelevant. Stop.
2. **Size**: trivia, overhead > savings → inline. Stop.
3. **Delegate** when: no quality loss, non-trivia job, net savings.
   - Recon/zero-judgment (wide search, bulk read, research, triage, verification, mechanical batch, boilerplate/fixtures, doc hygiene...) → Scout, conclusions only, no noise into Orchestrator context.
   - Brute-force parallelism → Workflow: ≥2 parallel agents, multi-phase pipelines, unknown-size discovery, adversarial verify, fleets, needs Claude-side tools.
   - Everything else → Worker. Several Workers may run concurrently.
4. **Built-in Agent templates** (claude-code-guide, Explore, Plan, general-purpose…): NEVER call directly — subagent inherits orchestrator's model, max cost. Run gates 1–3, prompt subagent with template.

## Model Roster & Routing

90% normal implementation → Worker. 10% hard (intricate design, parsing, subtle correctness) → Escalated. Front-End Design → Designer. 
BANNED: Sonnet 5 (worse value); Haiku 4.5.

| Harness & Model | Role | Cost | Intelligence | Notes |
| --- | --- | --- | --- | --- |
| Fable 5 | Orchestrator | Max | Max | Expensive: judgment only, never labor. Never pipeline worker. |
| Grok Build CLI `grok-4.6 --effort medium` | Worker 1 - Default | Low | 59 | § Grok CLI |
| Workflow `model:'opus', effort:'medium'` (Opus 5) | Worker 2 | Low | 59 | Claude-side fleets, fan-out, dynamic workflows. § Dispatch Mechanics + `workflows.md` |
| Workflow `model:'opus', effort:'high'` (Opus 5) | Escalated 1 - Default | Low | 61 | Opus workflow above. |
| Grok Build CLI `grok-4.6 --effort xhigh` | Escalated 2 | Low | 61 | § Grok CLI |
| Antigravity CLI `agy` `gemini-3.7-flash --effort medium` | Scout - Default | Low | 53 | § Antigravity CLI. Lightning fast implementer + recon + menial bulk work. |
| Workflow `model:'opus', effort:'low'` (Opus 5) | Scout 2 | Low | 52 | Opus workflow above. |
| Workflow `model:'opus', effort:'high'` (Opus 5) | Designer | Low | 61 | Best design and taste. Opus workflow above. |
| CodeBuddy CLI `kimi-k3-2 --effort max` | Dabate Reviewer 3 | High | 60 | `codebuddy-cli.md` |
| CodeBuddy CLI `glm-5.3-flash --effort max` | Backup | Low | 57 | ALWAYS max — except workflows: `--effort ultracode` (= high + Dynamic Workflows; parallelism over peak).  `codebuddy-cli.md` |
| CodeBuddy CLI `hy4-preview --effort max` | Backup | Free |  |  |

## Dispatch Mechanics

Claude-side workers (Opus, never Sonnet):
- ONLY via `Workflow`: `agent(prompt, {model: 'opus', effort: 'medium', label: '...'})`; `'high'` for hardest ~10% and design. Multi-agent scripts, budgets, resume, multi-day loops: `workflows.md`.
- Model AND effort stated every spawn.
- One worker = still a one-`agent()` Workflow.
- `Agent` tool BANNED (no effort field) — sole exception: teammate spawns (§ Agent Team).

Task orders:
- Big jobs: spec in `<project>/docs/orchestration/MM-DD-##.md`; dispatch "Read and execute exactly the contract at <path>".
- One `ledger.md` per project: user decisions verbatim, task log, standing orders.
- No report files — report in chat.

### CLI Workers (shared contract)

Grok + agy live below; `codex-cli.md`, `codebuddy-cli.md` hold the rest — read the one you dispatch to, never the others. This is the contract every CLI obeys.

Runner shape (every CLI):
- Bash `run_in_background`, watcher armed in the SAME batch.
- `exec </dev/null` first (a live stdin pipe freezes some CLIs), `echo $$ > <TMP_PATH>/<job>.pid`, `cd <PROJECT ROOT>` (never `-C`/`--cwd`-style flags).
- stdout+stderr → `<TMP_PATH>/<job>.log`; then `printf '\nEXIT=%s\n' $? >> <job>.log` (leading `\n` so EXIT= never lands mid-line); final answer → `<TMP_PATH>/<job>.final.txt`.

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
- **Superpowers:** prepend `[$superpowers:using-superpowers](<path per CLI>)` to every prompt. TDD is enforced as verifiable acceptance checks (failing-tests-first, tests present in the diff), not as trust.

Follow-ups:
- Resume with the CLI's resume flag + id from the log, same cwd, send only the delta (memory intact).
- Cancel: `TaskStop` the Bash task; confirm no `EXIT=` was written.

### Grok CLI

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>                 # sessions keyed by cwd — resume must run from same dir
grok -p "<prompt>" -m grok-4.6 --effort <medium|xhigh> --always-approve \
  --output-format streaming-messages-json > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"type":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.structured_output // .result' > <TMP_PATH>/<job>.final.txt
```

Files: log = NDJSON (liveness); resume id = first `"session_id"` in log. Signal kills exit 130/143, session saved to last tool call.

Flags:
- `-m grok-4.6` + `--effort` EVERY dispatch: `medium` = worker, `xhigh` = escalated/reviewer (omitted defaults to `high` — neither lane). Never `grok-4.5`.
- `--always-approve`: required unattended; deny rules + hooks still apply.
- `--sandbox read-only` = analysis-only. Default `off` — worktree edits need only path in prompt.
- `--json-schema '<inline JSON>'` (string, not file) → `structured_output` in result line (runner prefers).
- `--prompt-file <path>` for long prompts.
- `--cwd` BANNED — always `cd`. `-w/--worktree` BANNED.
- `--max-turns <N>` for runaway risk (`stopReason: max_turn_requests`).

Prompts:
- Fans out via `spawn_subagent` (`general-purpose|explore|plan`, depth 1, parallel, own context); remind explicitly.
- Superpowers: `~/.grok/installed-plugins/superpowers-5993746a/skills/using-superpowers/SKILL.md`

Follow-ups:
- Resume: `grok -p "<delta>" -r <session_id> -m grok-4.6 --effort <same> --always-approve --output-format streaming-messages-json` — same cwd, same `--sandbox` (differing refused).
- Review: normal job + `--sandbox read-only`.

### Antigravity CLI (`agy`)

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>
agy -p "<prompt>" --model gemini-3.7-flash --effort medium --dangerously-skip-permissions \
  --output-format stream-json --print-timeout 30m > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"event":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.result.structured_output // .result.response' > <TMP_PATH>/<job>.final.txt
```

Files: log = NDJSON (`step_update` events = liveness); resume id = `conversation_id` in first `init` line. Success also needs last result line `"status":"SUCCESS"`; errors → `"status":"ERROR"` + exit 1.

Flags:
- `--model gemini-3.7-flash --effort medium` EVERY dispatch — the only model + effort ever used; all other `agy models` BANNED.
- `--dangerously-skip-permissions`: required unattended.
- `--mode plan` = analysis-only: blocks all writes; plan docs dumped under `~/.gemini/antigravity-cli/brain/<cid>/` — ignore, read only the reply.
- `--print-timeout 30m`: default 5m kills longer jobs mid-run — raise EVERY dispatch.
- `--json-schema '<inline JSON or path>'` → result gains `structured_output` (runner prefers).
- Worktree edits: `cd` in, or path in prompt + `--add-dir <dir>`. No cwd flag — always `cd`.

Prompts:
- Fans out via native subagent tools (`define_subagent`/`invoke_subagent`/`manage_subagents`); remind explicitly.
- Superpowers: `~/.gemini/config/plugins/superpowers/skills/using-superpowers/SKILL.md`

Follow-ups:
- Resume: `agy -p "<delta>" --conversation <conversation_id> --model gemini-3.7-flash --effort medium --dangerously-skip-permissions --output-format stream-json` — same cwd, memory intact.
- Review: normal job + `--mode plan`.

## Agent Team vs Workflow

Key question decides: do workers need to TALK to each other mid-job?

**Agent Team = collaboration.** Small crew 2–5, group chat: peer `SendMessage` + shared task list, live debate/handoff/renegotiation — value comes from the discussion. Lead = Orchestrator, Teammates = separate Claude sessions, model chosen per teammate (Opus default). Must-knows (not in tool schemas): spawn = `Agent` tool + `name` param — SOLE exception to the Agent-tool ban; name the model in the spawn prompt (no model param; blocked/unnamed → lead's model; effort NOT settable, inherits lead's). Teammate idle notice carries NO output — results arrive only via SendMessage/task list; teammates forget to mark tasks done, nudge them. Stop = `TaskStop` with teammate name; `SendMessage` to a stopped teammate auto-resumes it with its transcript. In-process teammates (only mode in desktop GUI) can't run background subagents (synchronous OK); only lead approves plans; team auto-cleans at session end; one team/session, no nesting, `/resume` drops in-process teammates.

**Workflow = brute-force parallelism.** Isolated agents never talk; script holds the plan: deterministic, resumable, reusable, budgeted. Structurally defends vs agent laziness, self-preferential bias, goal drift (fresh context each, producer ≠ verifier). Read: `workflows.md`.

Route:
- Many independent units; verification/adversarial-heavy; unknown-size discovery; ranking/sorting; reproducibility wanted → Workflow.
- Team ONLY when ALL hold: few pieces (2–5), deeply interdependent, interfaces uncertain/evolving, live negotiation essential. Examples: rival-hypothesis debugging, cross-layer API negotiation, multi-angle exploration where findings must cross-pollinate mid-flight.
- Small crew but no cross-talk needed → still Workflow: 3 isolated agents beat 3 chatting ones (cheaper, deterministic, no coordination overhead).
- Depth not breadth — ONE thread grinding until done-criteria met (days OK) → `/goal <criteria>`: session Stop hook, agent CANNOT end turn until condition holds, auto-clears on success (`/goal clear` = abort early). Criteria must be verifiable/runnable; fights laziness. Breadth too big for one path → Workflow.

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

State lives on disk

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
