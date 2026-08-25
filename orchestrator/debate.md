# Debate and Align on Big Plans

The orchestrator authors spec + implementation plans, dispatches adversarial reviewers, arbitrates. Adversarial reviewers = independent top CLI models, read-only, each in a private persistent thread, unaware of each other. Cost irrelevant here. Observed: orchestrator solo ≈6/10 → +1 reviewer ≈8 → +2 ≈9.3. Capped at 3 reviewers max.

## Tiers

| Job size | Reviewers | Time box to align |
|---|---|---|
| <1h, easily reversible | 0 | — |
| 1-2h | 1 | 30 min max |
| 2-5h | 2 | 60 min max |
| >5h OR very messy / irreversible | 3 | can be hours |

Only debate with an adversarial reviewer for “Big Jobs” sizing 1h+. Escalate one tier if a round agrees suspiciously fast.

## Adversarial Reviewer Committee

* Same prompt for every reviewer: `adversarial-reviewer.md`, read by path.
* Fixed order: 1 reviewer = always grok 4.6 xhigh; 2 reviewers = + gpt-5.6-sol xhigh; 3 reviewers = + K3 via CodeBuddy (GLM 5.3 stands in when WorkBuddy quota is low; K3 preferred when the target involves design or visuals).
* Never substitute a second harness of the same model (Cursor grok is not independent of GBC grok).

| Harness | Read-only flag | Dispatch |
|---|---|---|
| Grok Build CLI `grok-4.6 --effort xhigh` | `--sandbox read-only` | `grok-cli.md` |
| Codex CLI `gpt-5.6-sol` xhigh | `-s read-only` | `codex-cli.md` |
| CodeBuddy CLI Kimi K3 (GLM 5.3 stand-in) | read-only mode | CLI file TBD — get mechanics from user before first dispatch |

## Drafting (orchestrator)

1. Read once per big job (local files; superpowers is not installed in Claude Code): `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/` → `brainstorming/SKILL.md` (spec), `writing-plans/SKILL.md` (plan), `receiving-code-review/SKILL.md` (arbitration), `verification-before-completion/SKILL.md` (accepting work).
2. Human first: follow brainstorming fully, thorough Q&A until the human approves the spec, unless the human says not to be bothered. Reviewers only after that.
3. Spec at `<project>/docs/orchestration/MM-DD-##-spec.md`; debate to all-PASS. Then plan at `...-plan.md` from the agreed spec; debate to all-PASS.
4. Each doc carries a version header, changelog, numbered decision table (stable anchors). Only the orchestrator edits.

## Executing the plan

Read once per big job and follow: `.../skills/subagent-driven-development/SKILL.md` (its helper scripts and reviewer template live in that dir). Two overrides: parallel implementers are allowed, one per worktree (SDD says never); pre-merge and final whole-branch review use `judgment-reviewer.md`, and merge follows `SKILL.md` § Worktrees, not SDD's finish menu.

## Conversation mechanics

- Reviewer memory = its CLI session; every round resumes it (same cwd) and sends only the delta. Reviewers run in parallel.
- Each reply lands in `<TMP_PATH>/<reviewer>.r<N>.final.txt`, one file per round. The orchestrator reads that file only.
- `.log` only when the final is missing/empty, EXIT≠0, or a verdict smells wrong — and never whole: `grep -n` the anchor/finding/`error`, `tail -n 100`, `sed -n` ±50 lines around hits; ≤10% of the file.

## Reviewer prompt

Reviewer is told the path of `adversarial-reviewer.md` (skill dir) and reads it itself; nobody pastes it. Its `NO MATERIAL OBJECTION` = PASS; anything else = findings to rule on.

Honesty rules (verbatim every round; bind the orchestrator too):
```
1. Verdicts rest on evidence and reasoning only. Agreement is never a courtesy; disagreement is never a posture.
2. A finding stands until refuted with a specific fact or argument — not by restatement, authority, or repetition. If your finding was rejected without a refutation, say so and restate it.
3. Concede the moment you are shown wrong, and name exactly what convinced you. A concession without that reason is invalid.
4. Never soften, drop, or downgrade a finding to end the round. Never add one to look useful.
5. Every accept/reject carries one line of why. No "fair point", no "you're right" without the reason.
```

## Rounds

1. Round 1: all reviewers in parallel on v1.
2. The orchestrator rules on every finding on merit. Merge accepted ones → bump version once; never concurrent versions.
3. Round N: resume each thread with the round-N template; rejections explained to that reviewer only, one line each.
4. No round cap. Done only when every reviewer returns PASS on the same version → human go/no-go → execute. Stalemate (one item unchanged 3 rounds, both sides holding): the orchestrator has final say — rare; convince first, overrule last. Record rationale in the decision table, tell that reviewer, continue. Human is never pulled into the debate.

## Templates

Round 1:
```
Read and follow ~/.claude/skills/orchestrator/adversarial-reviewer.md. Target: <doc path> (v1). Context: <1–2 sentences: purpose, consumer>. <honesty rules>
Number every finding. Do not edit any file.
```
Round N:
```
<doc path> is now v<N>. Your #<ids> accepted. #<ids> rejected: <one line each>. <honesty rules>
Re-review v<N>: new or unresolved findings only, same format; PASS if none.
```

## Hard rules

1. Single writer: only the orchestrator edits the docs. Reviewers read-only; their only output is their reply.
2. Isolation: reviewers never learn others exist; never attribute origin; no shared docs, no cross-rebuttal. Conflicts: the orchestrator rules, records rationale in the decision table; the overruled side gets decision + reason in its own thread.
3. Pointers, not payloads: reviewers run in the project root and read files themselves. Spikes/experiments go to `<TMP_PATH>`.
4. Superpowers: the orchestrator reads only the files named in Drafting/Executing; reviewers and executors get the normal `using-superpowers` prefix.
5. No framework files. `<TMP_PATH>` is transport only, never documentation.
