# Debate Big Jobs

Orchestrator drafts spec + plan, dispatches adversarial reviewers, arbitrates. Cost irrelevant.

## Committee

Each tier adds one reviewer:

| Job size | Adds reviewer (roster slugs, read-only) |
|---|---|
| <1h | — |
| 1-3h | Debate Reviewer 1 |
| >3h | + Debate Reviewer 2 |

## Manual — user-triggered

User names reviewer (any model, any effort) and scope; unnamed → Debate Reviewer 1. Everything else standard.

## Conversation mechanics

- Each round resumes each reviewer's CLI session (same cwd) with the delta only; reviewers run in parallel.
- At FLEET DONE read every `<TMP_PATH>/<reviewer>.r<N>.final.txt` in ONE call.

## Draft, Debate, Execute

1. Read only 5 Superpowers skills once `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/<name>/SKILL.md`: `brainstorming` (spec), `writing-plans` (plan), `receiving-code-review` (arbitration), `verification-before-completion` (accepting work), `subagent-driven-development` (execution; helper scripts + reviewer template in that dir).
2. Full brainstorming Q&A with user until spec approval.
3. Spec at `<project>/docs/orchestration/MMDD-##-spec.md`, debate; then plan at `...-plan.md` from the agreed spec, debate.
4. Each doc: version header, changelog, numbered decision table (stable anchors).
5. Workers execute the plan per subagent-driven-development. Overrides: parallel Workers allowed, one per worktree; merge per `SKILL.md` § Worktrees.

## Reviewer prompt

`NO MATERIAL OBJECTION` = PASS; anything else = findings to rule on.

Honesty rules — bind Reviewers AND Orchestrator; verbatim round 1, one-line re-pin after:
```
1. Evidence and reasoning only. Agreement never courtesy; disagreement never posture.
2. A finding stands until refuted by a specific fact — not restatement, authority, or repetition. Rejected without refutation → restate it.
3. Shown wrong → concede at once, naming what convinced you; unexplained concession invalid.
4. Never soften, drop, or downgrade a finding to end a round; never add one to look useful.
5. Every accept/reject = one line of why.
6. Re-review the doc itself, not the round message: confirm accepted fixes actually landed before `NO MATERIAL OBJECTION`.
```

## Triage — every round, every claim

Verify each claim in the target first (open the file, trace the path, run it when runnable); a claim that cannot be shown true = rejected.
- P0 doesn't work: crash, data lost/overwritten, main feature broken, purpose not met
- P1 runs, but major problem
- P2 minor, but user notices
- P3 user never notices: wording, hygiene, doc consistency, edge cases → reject on sight
Only verified P0–P2 get fixed.

## Rounds — Hard Cap 2

1. Round 1 — all reviewers on v1. Triage, fix P0–P2. Merge → v2 once; never concurrent versions.
2. Round 2 — resume each thread with the round-2 template on v2: confirm fixes landed, report new P0–P2. Triage, fix → v3; nobody reviews those fixes.
Done = a round with nothing to fix, or round 2 → human go/no-go → execute.
Executable target → one real run per round beats a reviewer.

## Templates

Round 1:
```
Read and follow ~/.claude/skills/orchestrator/adversarial-reviewer.md. Target: <doc path> (v1). Context: <1–2 sentences: purpose, consumer>. <honesty rules>
Number every finding. Do not edit any file.
```
Round 2:
```
<doc path> is now v2. Your #<ids> accepted. #<ids> rejected: <one line each>. Honesty rules still bind.
Re-review v2: confirm fixes landed; new P0–P2 only, same format; verdict `NO MATERIAL OBJECTION` if none.
```

## Hard rules

1. Reviewers never learn others exist. Conflicts: Orchestrator adjudicates, records rationale in decision table.
2. Pointers, not payloads: reviewers run in the project root. Spikes/experiments → `<TMP_PATH>`.
3. Output files: spec + plan only.
