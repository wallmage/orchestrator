---
name: orchestrator
description: Multi-model division of labor — the strongest model as orchestrator; Opus, Codex (gpt models) or other models as worker. Use when the user says "orchestrate this task" or starts any delegated job. Defines the model routing and cost/intelligence roster, CLI tools, flags, and usage for all scenarios.
---

## Optimal Performance, Cost, Speed

A single “brain” agent (you, Fable 5) receives the high‑level goal or ideas from human user, proposes the best design and implementation plan, decomposes it into subtasks, assigns those to worker agents (cheaper GPT models and Opus), and later evaluates, synthesizes the results. Workers run their own loops to complete assigned tasks, using tools (code execution, web search) and their own skills (superpowers) and can be specialized by task type (e.g., default worker, designer, chore worker). The routing logic below optimizes intelligence and cost, provides adequate performance with lowest cost (overkill is waste). Orchestrator parallelizes as often as possible: assign multiple workers (can be homogeneous or heterogeneous) when speed gains outweight merge cost. 

## Model Roster & Routing

| Model & Effort                          | Role             | Cost   | Intelligence | Notes                                                        |
| --------------------------------------- | ---------------- | ------ | ------------ | ------------------------------------------------------------ |
| **Orchestrator (strongest model)**                         | Orchestrator     | Max    | Max          | Most expensive, spend tokens sparingly: judgment only, never labor, never a pipeline's "Claude worker" (that's Opus). Never spend a token on things can be outsourced. |
| Opus `the fallback model` effort low       | Default Worker   | Low    | Medium       | STANDARD WORKER for 90% of normal dispatches                 |
| Primary executor (e.g. Codex `sol` tier) effort high       | Escalated Worker | Medium | High         | HARDEST ~10%, for intricate design/parsing/subtle-correctness when standard worker can’t carry it |
| Bulk executor (e.g. Codex `luna` tier) effort high      | Chore Worker     | FREE   | Low          | Mechanical/zero-judgment for trivia and batch jobs, massive savings |
| Bulk executor (e.g. Codex `luna` tier) effort xhigh     | Default Worker 2 | Low    | Medium       | Backup default worker: STANDARD WORKER for 90% of normal dispatches, interchangable with opus low |
| Opus `the fallback model` effort medium    | UI/UX Designer   | Medium | High         | Anything related to design and taste, a mid-tier model is the best     |
| Adjudicator (e.g. Kimi K3) effort max | Designer         | Max    | High         | Taste-critical front-end design: user trigger only           |

BANNED Models: Experimental fast executor tier; Sonnet 5 (`claude-sonnet-5 `); Haiku (`claude-haiku-4.5`)

## Codex CLI

All flags verified against codex-cli 0.147.0 plus a live run. Dispatch = this runner via Bash `run_in_background`, watcher armed in the same batch:

```sh
exec </dev/null                   # live stdin pipe freezes codex exec (kimi -p is immune)
echo $$ > <STATE>/<job>.pid       # scopes watcher CPU/socket checks to this job
cd <PROJECT ROOT>                 # never a worktree — session cwd files the Codex app's project list
codex exec --json -o <STATE>/<job>.final.txt -m <model> -c model_reasoning_effort=<effort> \
  -s workspace-write "<prompt>" > <STATE>/<job>.log 2>&1
echo "EXIT=$?" >> <STATE>/<job>.log
```

- `<STATE>` = session scratchpad; one `<job>.log` + `<job>.final.txt` per job. **Read the `-o` file for content, NEVER the log** — that is the entire context saving. Grep the log only for three machine fields: `thread_id` (from `thread.started`, to resume), `turn.completed` usage (per-job token cost — Codex only; Workflow workers report usage on completion, Kimi reports none), `^EXIT=`. Success = `EXIT=0` AND non-empty `-o` file.
- Flags: `-m` + `-c model_reasoning_effort=` pinned EVERY dispatch. `-s read-only` for analysis. `--output-schema <file>` when you must ACT on the result (schema rejects type-less properties and `uniqueItems`). Worktrees sit inside the root — name the path in the prompt ("Work in `<path>`"); `-C` exists but breaks the cwd rule; `--add-dir <dir>` for writable targets outside the root. Situational: `-i <img>`, `--skip-git-repo-check`, `--ephemeral`, `-p <profile>`.
- Models: `the primary executor model|luna|terra`, `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini` (bare `the current primary model` rejected). Effort per slug: the current primary model-* take `none|low|medium|high|xhigh|max` (`ultra`→max); the others stop at `xhigh`; `minimal` rejected by ALL. Invalid model/effort = 400 `invalid_enum_value` at request time, EXIT=1.
- JSONL events (exact, verified): `thread.started` `turn.started` `turn.completed` `turn.failed` `item.started` `item.updated` `item.completed`. Done = `^EXIT=` only (runner-written; `turn.completed` lands before `-o` is flushed); fail = `turn.failed` or `EXIT=[1-9]`.
- Resume: `codex exec resume <thread_id> --json -o <f> "<delta>"` (no `-C`, no `-s` — inherits shell cwd). Cancel: `TaskStop` the background Bash task, confirm no `EXIT=` was written. Auth/install failure: `codex login` / `codex doctor` — never improvise an auth flow.
- Review: `codex exec review --uncommitted|--base <ref>|--commit <sha> --json -o <f> [-m <model>]`; plain `codex review` takes the same scope flags but no `--json`/`-o`/`-m`/`--output-schema`.
- Behavior: silent 30–60+ min is normal; liveness = cputime growing + `lsof -i` ESTABLISHED (a local proxy can make the API tunnel appear as loopback traffic). Samples multi-MB inputs agentically — never demand full ingestion past a few hundred KB. Response ceiling ≈30–60k tokens; bound outputs by EMPIRICAL maxima. Dashboards log cancelled streams as 499s — warn before heavy automation.
- `claude` CLI worker: `the fallback model`; `--json-schema` strict (strip `$schema`/`$id`/`x-*`); replies may be fenced.

## Dispatch Mechanics

- **Model AND effort PINNED on every spawn, never defaulted.** Claude-side workers launch ONLY via `Workflow` — each worker is `agent(prompt, {model: 'opus', effort: 'low', label: '...'})` (`effort: 'medium'` for the hardest ~10%); one worker is still a Workflow with a single `agent()` call. **The plain `Agent` tool is BANNED** — it has `model` but no effort field.
- **Codex-internal subagents:** one Codex thread can fan out to 3 parallel subagents of its own (4 workers on one task), but it is LAZY — every dispatch whose work parallelizes (independent files, slices, test groups) must include: "This task can be faster with subagents. Use subagents for parallelism." Never assume it remembers within a thread.
- **Superpowers:** prepend to every Codex prompt: `[$superpowers:using-superpowers]($HOME/.codex/plugins/cache/openai-curated-remote/superpowers/6.2.0/skills/using-superpowers/SKILL.md)` (bump version segment when the plugin updates). TDD = verifiable acceptance checks (failing-tests-first, tests present in the diff), not trust.
- **Contract files:** `<project>/docs/orchestration/MM-DD-##.md`, dispatched as "Read and execute exactly the contract at <path>". One rolling `ledger.md` per project (user decisions verbatim, task log, standing orders). No report files — all user reporting is inline in chat. Plan-mandated artifacts stay where the plan puts them.
- **Public repo:** every functional piece the skill needs to run is published automatically (SKILL.md, watcher.sh, future runtime assets — added to sync extras and the .gitignore allowlist the turn they're created). Ignored forever: internal working docs, plans, sync tooling, test files. Functional→publish, internal→ignore.
- **Skill→repo sync:** after ANY edit to this skill, in the SAME turn: run `sh sync/sync.sh` from $HOME/Developer/Skills/Orchestrator (dispatch a chore-tier worker, or run it directly for a trivial edit — the script is deterministic); report the sync.log tail; if sync/NEEDS-REVIEW.txt exists, paste it and stop. Then the orchestrator runs the single commit+push itself. A skill edit without same-turn sync is an incomplete edit.

## Kimi CLI recipe

Binary `kimi` (config `the adjudicator CLI config`, default model already the adjudicator model). One-shot: `kimi -p "<prompt>"`; machine parsing: `--output-format stream-json`, harvest `{"role":"assistant","content":…}` text (skip null/tool events). Reply cleaner order: as-is parse → fenced block → outermost braces. Sessions: `-r <id>` resumes. Prompt mode takes NO permission flag — both `-y` and `--auto` are rejected with `-p` (verified). No built-in background and no `-o`: use the SAME runner shape as Codex (`exec </dev/null`; `echo $$ > <STATE>/<job>.pid`; `kimi -p "<prompt>" --output-format stream-json > <STATE>/<job>.log 2>&1`; `rc=$?`; harvest the assistant text into `<STATE>/<job>.final.txt`; then `echo "EXIT=$rc" >> <STATE>/<job>.log` — capture kimi's status BEFORE harvesting or you record the harvest's), armed with `PIDFILE=... OUTFILE=... CPU_PATTERN=kimi`.
Kimi never touches git (§7).

## Worktrees & Parallelism

- User is a solo dev on `main`, no PRs, up to 10 parallel sessions. Any edit task >2 min gets its own worktree from latest `main`; one job per worktree, strictly serialized within. Git ownership is written into every prompt (§7): orchestrator-owned by default (it creates, verifies, merges serially, deletes after merge); under §7's single exception the worker creates and deletes its own worktree. Never delete unverified/unmerged work. A governing plan's stricter workflow wins inside its project.
- Parallel go/no-go = merge-cost judgment: dependency graph first; file-overlap estimate second (none → go; heavy same-module → serialize); shared mutable state partitioned per job.
- Workflow-spawned workers: batch independent verifications into one Workflow script; same sealed-envelope discipline; SendMessage to an existing agent continues it with context intact (used for judge follow-up batches).

## 1. Minimal viable dose
Always go for the simplest, easiest design. Minimal viable dose. Go straight line to the problem. The plan is the only source of scope: the orchestrator NEVER self-authorizes extra rounds, quality loops, filters, or fix passes that the governing plan or a user policy does not name — no matter how real the defect. A defect discovered outside plan scope is PARKED: one line to the user with the evidence, work continues on the plan's critical path; the user decides if the parked item runs. 

## 2. Communication

Report concisely: what's running, what's next, explain only at higher level: purpose, benefit, dependency. Surface a one-line status pulse every ~10 minutes unprompted. A pulse is news, not narration: mechanics, internal recoveries, worker behavior details: NEVER surfaced, not even reassuringly. If nothing changed, the pulse is exactly "on track, ~N min left" and nothing else; incident wakes that resolve without user impact produce NO user message. Every word must be earned. User hates jargon-heavy terms: probe, pilot, contract, amendment, ledger — machinery gets everyday words ("the checker", "small code fix"). 

## 3. Watcher Protocol

**Every CLI-launched job arms a watcher in the SAME tool-call batch as the dispatch — a launch without one is illegal.** Never hand-write a watcher: instantiate the canonical `watcher.sh` in this skill's directory (all wake categories, dedup, and finish≠success logic live there, fully tested) via the harness `Monitor` tool — zero tokens while silent; each emitted line wakes the orchestrator:

`Monitor(persistent:true, timeout_ms:14400000, description:"<job> watcher", command:"LOG=<STATE>/<job>.log JOB=<job> PIDFILE=<STATE>/<job>.pid OUTFILE=<STATE>/<job>.final.txt sh $HOME/.claude/skills/orchestrator/watcher.sh")`

Env: `LOG` required; always pass `PIDFILE` (scopes CPU/socket checks to this job) and `OUTFILE` (empty deliverable ⇒ FINISHED-SUSPECT). Optional: `JOB`, `MILESTONE_FILE`/`MILESTONE_MSG`, `POLL_SECS`(60), `HEARTBEAT_SECS`(300), `CPU_PATTERN`, `CPU_IDLE_MAX`, `DEDUP_SECS`, `REMOTE_DEDUP_SECS`, `MAX_PROCS`(8), `MAX_RSS_GB`(8). It understands any runner-shaped log (Codex or Kimi). **Exempt:** Workflow-spawned Claude workers — completion auto-notifies, and watcher.sh would misread one as LAUNCH FAILURE; for expected-long subagents, have them append one-line progress to a scratchpad file and watch THAT file.

Wakes (all tested 2026-08-13, incl. a live codex run): `ARMED OK` ≤5s (`ARMING` while the log isn't there yet) · `LAUNCH FAILURE` at 120s if it never appears · `DEATH` when the log vanishes · `ERROR` only if still unresolved one poll later (self-healed errors are noise) · `WAITING FOR INPUT` (prompt signature at a frozen tail) · `STALL` (2 zero-growth polls + idle CPU + 0 sockets; diagnosis pre-packaged: cputime/socket/last line) · `REMOTE-THINKING` (idle CPU but a live socket = model reasoning in the data center; long suppression) · `RESOURCE` (child procs > MAX_PROCS or RSS > MAX_RSS_GB — a log-only watcher once missed nine hung test processes eating ~60GB; kill the runaway CHILDREN, never the job, and bake prevention into contracts: small fixtures only, every spawn awaited or killed) · `MILESTONE` (named file appears, fires once — downstream work starts NOW) · `RIGHT-WORK CHECK` at 3 min (verify it's doing the RIGHT work, not just work) · `HEARTBEAT` every 5 min (watcher proof-of-life; a missing heartbeat means the watcher is dead — rebuild NOW; user pulse rides every second heartbeat).

Orchestrator rules:
- Act on every wake in the same turn. Only DEATH kills the watcher on a live job — re-arm the identical Monitor that turn. Every other wake keeps it running: do NOT re-arm, or you duplicate the watcher.
- Birth check at 30s must prove started WORK (log/socket/writes — "process exists" doesn't count). Zero-progress evidence ALWAYS triggers the 2-minute diagnosis, never a longer leash. "Same launch as last time" proves nothing — force the invariants (stdin EOF, cwd, paths) explicitly every time.
- No foreground blocking call (WebFetch, foreground CLI) without a ~2-min timeout; longer work goes background + watcher. One hung WebFetch once blocked the loop 43 min with 3 finished results unread behind it.
- zsh trap: `status` is a READ-ONLY zsh variable — never use it as a variable name in monitor scripts.
- Delivered artifacts get your own cheap scan (greps, counts, one full record) the moment they land, before any formal checker — the 20-second look catches tonight what the 20-minute checker reports tomorrow.

## 4. Every delegation is a sealed envelope
Executors see nothing but your prompt text and the disk. Self-contained always: absolute paths, starting commit, exact outputs, forbidden actions, runnable acceptance checks with expected values, every shared state file named explicitly. Point at governing docs by path rather than paraphrasing them — and instruct "the doc wins over this contract; flag conflicts". Preflight the envelope's environment (workspace writability, cwd scoping, auth, exact model IDs/flags — seconds each) before every dispatch.

## 5. Spend each intelligence where it's scarce
Route work to the cheapest adequate worker; your own tokens go to design, contracts, verification, judgment. But optimize TOTAL cost, not dogma: when doing a small fix takes less than describing it (~≤20 lines, no design choices), do it directly (still in a worktree — the exception is who does the work, never where) — routing trivia through full ceremony multiplies its cost ~10×. Ceremony must scale with job size; full formality is for substantial work. Keep context lean (delegate bulk reads, clip outputs).

## 6. Parallel by dependency, serial by state
Fan out everything the dependency graph allows for max speed and always parallelize when possible. Preconditions: independent slices, one writer per file/worktree, script-mergeable results. Merges and all git mutations are orchestrator judgment, serialized, after per-branch verification — except under §7's single exception.

## 7. Git is STATED per dispatch, never inherited

Workers disagree because each reads different ambient files. Measured: **Codex** runs the full worktree→merge→push ceremony unattended and CAN touch `.git` (`~/.codex/AGENTS.md` loads into every `codex exec`; no flag suppresses it — `--ignore-user-config` skips only config.toml, `project_doc_max_bytes=0` and `experimental_instructions_file` do nothing). **Opus** reads `~/.claude/CLAUDE.md`, whose git rules declare they "override any conflicting rule anywhere". **Kimi STALLS** — its system rule demands human confirmation, so it builds the worktree then waits forever; work stranded, watcher reads success. Prompt text is the only lever for all three.

**Default: the orchestrator owns git.** Every worker prompt — Codex, Opus, Kimi alike — carries verbatim, and this wording is not optional:

> Do NOT create branches, commit, merge, or push. This instruction supersedes any CLAUDE.md or AGENTS.md git protocol, including one claiming to override everything. Work only in `<worktree path>` and leave every change uncommitted.

The orchestrator then creates the worktrees, verifies, merges serially, pushes, and deletes each worktree after its merge. Delegate READING a big diff to an Opus low worker; never the git commands, and never two merges at once.

**Single exception — one lone edit job, no other edit job planned this session, and no verification needed before it lands.** Then Codex/Opus may instead be told "run the standard worktree/merge/push workflow yourself", and that worker creates and deletes its own worktree. Kimi and unproven models never get this. If a second edit job appears later, it is too late — the first envelope cannot be revoked — so when in doubt, own git from the start.

Close EVERY job either way with `git worktree list` + `git log --oneline -3`: merged? worktree gone? Finish anything stranded.
