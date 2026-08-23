# Orchestrator

A battle-tested skill that turns a strong AI coding agent into an **orchestrator of cheaper AI executors** — it writes the contracts, watches every job, verifies results from disk, and spends its own expensive tokens only on judgment.

Forged over long autonomous sessions running a real 16-task data-recovery campaign: 100k-page fetches across parallel throttled lanes, multi-model AI generation rounds with adversarial review, and iOS release engineering — with the human checking in only at planned decision pauses.

## What's in it

One skill file, two parts:

- **Part I — The Law.** 14 principles that decide every situation: minimal-viable-dose execution, verification from artifacts (never from worker claims), the Watchtower monitoring protocol, sealed-envelope delegation contracts, dependency-driven parallelism, zero-filler communication, and the zero-push autonomy standard (if the human has to nudge the agent, that's a system failure to be root-caused into the rules the same turn).
- **Part II — The Almanac.** The concrete mechanics from the reference environment (Claude Code as orchestrator, OpenAI Codex CLI as primary executor, Claude Opus as fallback, Kimi as adjudicator): dispatch commands, effort-level policy, watcher script shapes, CLI gotchas. **Rewrite this part for your own toolchain** — the structure is the point, the specific paths and model names are examples.

## Install (Claude Code)

```bash
cp -r orchestrator ~/.claude/skills/orchestrator
```

Then in any project, tell your agent something like *"you're the orchestrator — delegate the work and verify it"*, or invoke the skill directly. The skill auto-triggers on phrases like "delegate and verify" or "outsource the work".

## The core ideas in 30 seconds

1. **The orchestrator never does labor.** Every execution task goes to the cheapest adequate model via a self-contained written contract with runnable acceptance checks.
2. **Worker claims are hypotheses.** Only disk, git, and recomputation count as evidence. The orchestrator (or an independent checker agent) re-runs the gates.
3. **Every launch arms a watcher.** A zero-cost shell loop that wakes the orchestrator on death, stall, error, input-wait, finish, and named milestones — enumerated explicitly at arming time, every time.
4. **Parallel by default.** If the dependency graph allows it, it runs concurrently — including building future tasks' code against fixtures before their input data exists.
5. **Every human nudge is a bug.** When the human has to push, the root cause gets written into the skill immediately, so no session makes the same mistake twice.

## License

MIT — see [LICENSE](LICENSE).

## Maintainers: auto-sync

Whenever the private skill changes, the orchestrator dispatches a cheap executor subagent that runs `sync/sync.sh`. The script sanitizes into a temporary file, blocks publication when `sync/blocklist.txt` matches, and only then replaces `orchestrator/SKILL.md`, commits, and pushes when `origin` exists. A blocked run leaves the public copy untouched and writes the offending lines to the ignored `sync/NEEDS-REVIEW.txt` flag for manual review; `sync/sync.log` records each trigger.
