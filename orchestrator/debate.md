# Debate Big Jobs

Orchestrator drafts spec + plan, dispatches adversarial reviewers, arbitrates. Reviewers = independent top CLI models, read-only, each a private persistent thread, unaware of others. Cost irrelevant.

## Committee

Same prompt every reviewer: `adversarial-reviewer.md`, read by path. Each tier adds one reviewer.

| Job size | Time box to align | Adds reviewer | Read-only flag | Dispatch |
|---|---|---|---|---|
| <1h | — | none | — | — |
| 1-2h | 30 min max | Grok Build CLI `grok-4.6 --effort xhigh` | `--sandbox read-only` | `SKILL.md` § Grok CLI |
| 2-4h | 60 min max | + Codex CLI `gpt-5.6-sol` xhigh | `-s read-only` | `codex-cli.md` |
| >4h OR very messy | can be hours | + CodeBuddy CLI `kimi-k3-2 --effort max` | `--permission-mode plan` | `codebuddy-cli.md` |

Round agrees suspiciously fast → escalate one tier.

## Conversation mechanics

- Reviewer memory = its CLI session; every round resumes it (same cwd), sends only the delta. Reviewers run in parallel.
- Each reply lands in `<TMP_PATH>/<reviewer>.r<N>.final.txt`, one file per round. Orchestrator reads that file only.
- `.log` only when final missing/empty, EXIT≠0, or a verdict smells wrong — never whole: `grep -n` the anchor/finding/`error`, `tail -n 100`, `sed -n` ±50 around hits; ≤10% of the file.

## Draft, Debate, Execute

1. Read all five Superpowers skills once: `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/` → `brainstorming/SKILL.md` (spec), `writing-plans/SKILL.md` (plan), `receiving-code-review/SKILL.md` (arbitration), `verification-before-completion/SKILL.md` (accepting work), `subagent-driven-development/SKILL.md` (execution; helper scripts + reviewer template live in that dir).
2. Full brainstorming Q&A with user until spec approval.
3. Spec at `<project>/docs/orchestration/MM-DD-##-spec.md`, debate with reviewers to all-PASS; then plan at `...-plan.md` from the agreed spec, debate to all-PASS.
4. Each doc: version header, changelog, numbered decision table (stable anchors). Only the orchestrator edits.
5. Execute the plan per subagent-driven-development. Two overrides: parallel implementers allowed, one per worktree (SDD says never); pre-merge + final whole-branch review use `judgment-reviewer.md`, merge follows `SKILL.md` § Worktrees, not SDD's finish menu.

## Reviewer prompt

Reviewer gets the path of `adversarial-reviewer.md` (skill dir), reads it itself; nobody pastes it. Its `NO MATERIAL OBJECTION` = PASS; anything else = findings to rule on.

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
2. Orchestrator rules on every finding on merit. Merge accepted → bump version once; never concurrent versions.
3. Round N: resume each thread with the round-N template; rejections explained to that reviewer only, one line each.
4. No round cap. Done = every reviewer PASS on the same version → human go/no-go → execute. Stalemate (one item unchanged 3 rounds, both sides holding): orchestrator has final say — rare; convince first, overrule last. Rationale in the decision table, tell that reviewer, continue. Human never pulled into the debate.

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
2. Isolation: reviewers never learn others exist; no origin attribution, shared docs, or cross-rebuttal. Conflicts: orchestrator rules, records rationale in the decision table; overruled side gets decision + reason in its own thread.
3. Pointers, not payloads: reviewers run in the project root, read files themselves. Spikes/experiments → `<TMP_PATH>`.
4. Superpowers: orchestrator reads only the five files named in Draft, Debate, Execute; reviewers and executors get the normal `using-superpowers` prefix.
5. No framework files. `<TMP_PATH>` = transport only, never documentation.
