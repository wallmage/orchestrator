# Debate and Align on Big Plans

The orchestrator authors spec + implementation plan, dispatches reviewers, arbitrates. Reviewers = independent top-tier CLI models, read-only, each in a private persistent thread, unaware of each other. Human sees only the final go/no-go, never the debate. Cost irrelevant here. Observed: solo ≈6/10 → 1 partner ≈8 → 2 ≈9.3. 3 partners max.

## Tiers

| Job size | Partners | Time box to align 100% |
|---|---|---|
| <1h, easily reversible | 0 | — |
| 1-2h | 1 | 30 min max |
| 2-5h | 2 | 60 min max |
| >5 h OR very messy / irreversible | 3 | can be hours |

Escalate one tier if a round agrees suspiciously fast.

## Committee

| Harness | Read-only flag | Dispatch |
|---|---|---|
| Codex CLI `gpt-5.6-sol` xhigh | `-s read-only` | `codex-cli.md` |
| Grok Build CLI `grok-4.6 --effort xhigh` | `--sandbox read-only` | `grok-cli.md` |
| Cursor CLI `kimi-k3-max` | `--mode ask` | `cursor-cli.md` |

- Same prompt for every reviewer: `adversarial-reviewer.md`, read by path. Diversity comes from model family.

## Sizing gate

<30 min and reversible → no process: decide, dispatch. Longer, or irreversible/messy → big job (tiers above). Cost is irrelevant on big jobs.

## Drafting (orchestrator)

1. One-time read per big job, from `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/` (plain local files; superpowers is deliberately NOT installed in Claude Code — no hooks, no auto-trigger): `brainstorming/SKILL.md` (spec), `writing-plans/SKILL.md` (plan), `receiving-code-review/SKILL.md` (arbitration), `verification-before-completion/SKILL.md` (accepting work). Optional: `*-reviewer-prompt.md` siblings to extend the battery. All other skills are executor-side via the `using-superpowers` prefix; the orchestrator never reads them.
2. Human first. Follow brainstorming fully with the human: probe, ask every clarifying question, surface unspoken requirements, present the design, get approval. No partner is dispatched before human sign-off on the spec. Only exit: human says "don't ask me" → human dropped, the orchestrator talks to partners only from then on.
3. Spec at `<project>/docs/orchestration/MM-DD-##-spec.md`; debate to all-PASS. Then plan at `...-plan.md` (writing-plans format; path override) from the agreed spec; debate to all-PASS. TDD steps in plans are for workers, not the orchestrator.
4. Each doc carries a version header, changelog, numbered decision table (stable anchors). Only the orchestrator edits.

## Executing the plan

Read once per big job: `.../skills/subagent-driven-development/SKILL.md`; use its `scripts/` (`task-brief`, `review-package`, `sdd-workspace`) and prompt templates by path. Deltas for us:
- Implementers and reviewers = CLI workers via runner + watcher (`SKILL.md` § CLI Worker Mechanics), model/effort explicit.
- Parallel implementers allowed — one per worktree; merge per `SKILL.md` § Worktrees. Its `finishing-a-development-branch` handoff does not apply.
- Reviews per `SKILL.md` § Reviewers: per task → SDD `task-reviewer-prompt.md`; pre-merge and final whole-branch → `judgment-reviewer.md`; big jobs add `adversarial-reviewer.md` on a different family at the final review. BASE recorded before dispatch (never `HEAD~1`).
- Ledger, fix-loop caps, escalation, rulings list to human: as written.

## Conversation mechanics

- A reviewer is a CLI process: no shared mind. Its memory = its CLI session (resume id); its voice = its final reply, which the runner writes to `<TMP_PATH>/<reviewer>.r<N>.final.txt` (new file per round, never overwrite; `.log` alongside). The orchestrator reads `.final.txt` only and deliberately skips `.log` (full session transcript: reasoning, tool calls, NDJSON; can be 100k+ lines — a 60-min, 300k-token read-through yields a 100-line verdict, and only the verdict belongs in the orchestrator's context).
- `.log` is for exceptions only (final missing/empty, EXIT≠0, or a verdict the orchestrator suspects). Never read it whole: `wc -l`; `grep -n` for the anchor, finding id, file name, `error`/`failed`; `tail -n 100`; then `sed -n 'a,bp'` ±50 lines around hits. Budget ≤10% of the file.
- Round N = resume that reviewer's thread (per its CLI file, same cwd) with the round-N template; runner + watcher per `SKILL.md` § CLI Worker Mechanics. All reviewers per round in parallel.
- This is a real conversation: reviewer remembers everything; the orchestrator sends only deltas.

## Reviewer prompt

`adversarial-reviewer.md` (skill dir), read by the reviewer by path, never pasted. Its `NO MATERIAL OBJECTION` = PASS; anything else = findings to rule on.

Honesty clause (verbatim, every round, binds the orchestrator too): "Be 100% honest. Accept or reject only on facts and reasoning. Do not defer, do not agree to be agreeable; hold your ground while you believe you are right, and always explain why. Concede only when convinced."

## Rounds

1. Round 1: all reviewers in parallel on v1.
2. The orchestrator rules on every finding on merit. Merge accepted ones → bump version once; never concurrent versions.
3. Round N: resume each thread with the round-N template; rejections explained to that reviewer only, one line each.
4. No round cap. Done only when every reviewer returns PASS on the same version → human go/no-go → execute. Stalemate (one item unchanged 3 rounds, both sides holding): the orchestrator has final say — rare; convince first, overrule last. Record rationale in the decision table, tell that reviewer, continue. Human is never pulled into the debate.

## Templates

Round 1:
```
Read and follow ~/.claude/skills/orchestrator/adversarial-reviewer.md. Target: <doc path> (v1). Context: <1–2 sentences: purpose, consumer>. <honesty clause>
Number every finding. Do not edit any file.
```
Round N:
```
<doc path> is now v<N>. Your #<ids> accepted. #<ids> rejected: <one line each>. <honesty clause>
Re-review v<N>: new or unresolved findings only, same format; PASS if none.
```

## Hard rules

1. Single writer: only the orchestrator edits the docs. Reviewers read-only; their only output is their reply.
2. Isolation: reviewers never learn others exist; never attribute origin; no shared docs, no cross-rebuttal. Conflicts: the orchestrator rules, records rationale in the decision table; the overruled side gets decision + reason in its own thread.
3. Pointers, not payloads: reviewers run in the project root and read files themselves. Spikes/experiments go to `<TMP_PATH>`.
4. Superpowers: the orchestrator reads only the files named in Drafting/Executing; reviewers and executors get the normal `using-superpowers` prefix.
5. No framework files. `<TMP_PATH>` is transport only, never documentation.
