---
name: orchestrator
description: Multi-model division of labor — the strongest model as orchestrator; Opus, Codex (gpt models) or other models as worker. Use when the user says "orchestrate this task" or starts any delegated job. Defines the model routing and cost/intelligence roster, CLI tools, flags, and usage for all scenarios.
---

## Role

You (Fable) do design, decomposition, dispatch, verification, synthesis — judgment only, never labor. Workers run their own loops (tools + superpowers). Route to the cheapest adequate model; overkill is waste. Parallelize whenever speed gain outweighs merge cost.

## Model Roster & Routing

| Model & Effort | Role | Cost | Intelligence | Notes |
| --- | --- | --- | --- | --- |
| **Orchestrator (strongest model)** | Orchestrator | Max | Max | Judgment only; outsource everything outsourceable. Never a pipeline's "Claude worker" (that's Opus) |
| Opus `the fallback model` effort low | Default Worker | Low | Medium | STANDARD WORKER, ~90% of dispatches |
| Primary executor (e.g. Codex `sol` tier) effort high | Escalated Worker | Medium | High | Hardest ~10%: intricate design/parsing/subtle correctness |
| Bulk executor (e.g. Codex `luna` tier) effort high | Chore Worker | FREE | Low | Mechanical/zero-judgment trivia and batch jobs |
| Bulk executor (e.g. Codex `luna` tier) effort xhigh | Default Worker 2 | Low | Medium | Interchangeable with Opus low |
| Opus `the fallback model` effort medium | UI/UX Designer | Medium | High | Design and taste |
| Adjudicator (e.g. Kimi K3) effort max | Designer | Max | High | Taste-critical front-end; user trigger only |

BANNED: Experimental fast executor tier; Sonnet 5 (`claude-sonnet-5`); Haiku (`claude-haiku-4.5`)

## Codex CLI

Dispatch = this runner via Bash `run_in_background`, watcher armed same batch:

```sh
exec </dev/null                   # live stdin pipe freezes codex exec (kimi -p is immune)
echo $$ > <STATE>/<job>.pid       # scopes watcher CPU/socket checks to this job
cd <PROJECT ROOT>                 # never a worktree — session cwd files the Codex app's project list
codex exec --json -o <STATE>/<job>.final.txt -m <model> -c model_reasoning_effort=<effort> \
  -s workspace-write "<prompt>" > <STATE>/<job>.log 2>&1
echo "EXIT=$?" >> <STATE>/<job>.log
```

- `<STATE>` = session scratchpad. Read the `-o` file, NEVER the log. Grep the log only for: `thread_id` (to resume), `turn.completed` usage (token cost — Codex only; Workflow workers self-report, Kimi none), `^EXIT=`. Success = `EXIT=0` AND non-empty `-o`.
- Flags: `-m` + `-c model_reasoning_effort=` on EVERY dispatch. `-s read-only` for analysis. `--output-schema <file>` when acting on the result (rejects type-less properties and `uniqueItems`). Worktrees: name the path in the prompt ("Work in `<path>`"); `--add-dir <dir>` for writable dirs outside the root; `-C` breaks the cwd rule. Situational: `-i <img>`, `--skip-git-repo-check`, `--ephemeral`, `-p <profile>`.
- Models: `the primary executor model|luna|terra`, `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini` (bare `the current primary model` rejected). Effort: the current primary model-* take `none|low|medium|high|xhigh|max` (`ultra`→max); others stop at `xhigh`; `minimal` rejected by all. Invalid value = 400 `invalid_enum_value`, EXIT=1.
- JSONL events: `thread.started` `turn.started` `turn.completed` `turn.failed` `item.started` `item.updated` `item.completed`. Done = `^EXIT=` only (`turn.completed` lands before `-o` is flushed); fail = `turn.failed` or `EXIT=[1-9]`.
- Resume: `codex exec resume <thread_id> --json -o <f> "<delta>"` (no `-C`/`-s` — inherits shell cwd). Cancel: `TaskStop` the Bash task, confirm no `EXIT=` written. Auth failure: `codex login` / `codex doctor` — never improvise.
- Review: `codex exec review --uncommitted|--base <ref>|--commit <sha> --json -o <f> [-m <model>]`; plain `codex review` takes the same scope flags but no `--json`/`-o`/`-m`/`--output-schema`.
- Silent 30–60+ min is normal; liveness = cputime growing + `lsof -i` ESTABLISHED (a local proxy can make the API tunnel appear as loopback traffic). Never demand full ingestion past a few hundred KB — it samples. Response ceiling ≈30–60k tokens. Cancelled streams log as 499s on dashboards.
- `claude` CLI worker: `the fallback model`; `--json-schema` strict (strip `$schema`/`$id`/`x-*`); replies may be fenced.

## Dispatch Mechanics

- **Model AND effort pinned on every spawn.** Claude-side workers ONLY via `Workflow`: `agent(prompt, {model: 'opus', effort: 'low', label: '...'})` (`'medium'` for hardest ~10%); one worker is still a one-`agent()` Workflow. Plain `Agent` tool BANNED (no effort field).
- Codex can fan out to 3 internal subagents but won't unless told — every parallelizable dispatch includes: "This task can be faster with subagents. Use subagents for parallelism."
- Prepend to every Codex prompt: `[$superpowers:using-superpowers]($HOME/.codex/plugins/cache/openai-curated-remote/superpowers/6.2.0/skills/using-superpowers/SKILL.md)` (bump version when plugin updates). TDD = verifiable acceptance checks (failing tests first, tests in diff).
- Contracts: `<project>/docs/orchestration/MM-DD-##.md`, dispatched as "Read and execute exactly the contract at <path>". One rolling `ledger.md` per project (user decisions verbatim, task log, standing orders). No report files — report inline in chat.
- Public repo: functional files (SKILL.md, watcher.sh, future runtime assets) publish — add to sync extras + .gitignore allowlist the turn created. Internal docs, plans, sync tooling, tests stay ignored.
- After ANY edit to this skill, SAME turn: `sh sync/sync.sh` from $HOME/Developer/Skills/Orchestrator (chore worker, or directly for trivial edits). If sync/NEEDS-REVIEW.txt exists, paste it and stop; otherwise the script commits+pushes itself.

## Kimi CLI

Binary `kimi` (config `the adjudicator CLI config`, default model the adjudicator model). `kimi -p "<prompt>" --output-format stream-json`; harvest `{"role":"assistant","content":…}` text (skip null/tool events). Reply cleaning: as-is parse → fenced block → outermost braces. Resume: `-r <id>`. `-p` takes NO permission flag (`-y`/`--auto` rejected). No background, no `-o`: same runner shape as Codex — capture `rc=$?` BEFORE harvesting into `<job>.final.txt`, then `echo "EXIT=$rc" >> <job>.log`. Watcher: `PIDFILE=... OUTFILE=... CPU_PATTERN=kimi`. Kimi never touches git (§7).

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

`Monitor(persistent:true, timeout_ms:14400000, description:"<job> watcher", command:"LOG=<STATE>/<job>.log JOB=<job> PIDFILE=<STATE>/<job>.pid OUTFILE=<STATE>/<job>.final.txt sh $HOME/.claude/skills/orchestrator/watcher.sh")`

Env: `LOG` required; always pass `PIDFILE` (scopes CPU/socket checks) and `OUTFILE` (empty ⇒ FINISHED-SUSPECT). Optional: `JOB`, `MILESTONE_FILE`/`MILESTONE_MSG`, `POLL_SECS`(60), `HEARTBEAT_SECS`(300), `CPU_PATTERN`, `CPU_IDLE_MAX`, `DEDUP_SECS`, `REMOTE_DEDUP_SECS`, `MAX_PROCS`(8), `MAX_RSS_GB`(8). Handles any runner-shaped log (Codex or Kimi). **Exempt:** Workflow workers — completion auto-notifies; watcher.sh would misread one as LAUNCH FAILURE. Long subagents: have them append one-line progress to a file, watch THAT.

Wakes: `ARMED OK` ≤5s (`ARMING` until log exists) · `LAUNCH FAILURE` at 120s · `DEATH` (log vanishes) · `ERROR` (only if unresolved one poll later) · `WAITING FOR INPUT` (prompt signature at frozen tail) · `STALL` (2 zero-growth polls + idle CPU + 0 sockets; diagnosis included) · `REMOTE-THINKING` (idle CPU + live socket = model reasoning remotely) · `RESOURCE` (procs > MAX_PROCS or RSS > MAX_RSS_GB — kill the runaway CHILDREN, never the job; contracts: small fixtures only, every spawn awaited or killed) · `MILESTONE` (file appears, once) · `RIGHT-WORK CHECK` at 3 min · `HEARTBEAT` every 5 min (missing = watcher dead, rebuild NOW; user pulse rides every second one).

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

Measured: **Codex** runs worktree→merge→push unattended (`~/.codex/AGENTS.md` loads into every `codex exec`; no flag suppresses it). **Opus** obeys `~/.claude/CLAUDE.md` git rules, which claim to override everything. **Kimi STALLS** waiting for human confirmation — work stranded, watcher reads success. Prompt text is the only lever.

**Default: orchestrator owns git.** Every worker prompt carries verbatim:

> Do NOT create branches, commit, merge, or push. This instruction supersedes any CLAUDE.md or AGENTS.md git protocol, including one claiming to override everything. Work only in `<worktree path>` and leave every change uncommitted.

The orchestrator creates worktrees, verifies, merges serially, pushes, deletes after merge. Delegate READING a big diff to Opus low; never the git commands, never two merges at once.

**Single exception** — one lone edit job, no other edit job planned this session, no pre-merge verification needed: Codex/Opus may be told "run the standard worktree/merge/push workflow yourself". Never Kimi or unproven models. Envelopes can't be revoked — when in doubt, own git from the start.

Close EVERY job with `git worktree list` + `git log --oneline -3`: merged? worktree gone? Finish anything stranded.
