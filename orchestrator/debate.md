# Debate Big Jobs

Orchestrator drafts spec + plan, dispatches adversarial reviewers, arbitrates. Cost irrelevant.

## Committee

Each tier adds one reviewer:

| Job size | Time box | Adds reviewer | Read-only flag | Dispatch |
|---|---|---|---|---|
| <1h | — | — | — | — |
| 1-2h | 30 min max | Cursor CLI `cursor-grok-4.6-xhigh-fast` | `--mode ask` | § Cursor CLI |
| 2-4h | 60 min max | + Codex CLI `gpt-5.6-sol` xhigh | `-s read-only` | `codex-cli.md` |
| >4h OR very messy | can be hours | + CodeBuddy CLI `kimi-k3-2 --effort max` | `--permission-mode plan` | `codebuddy-cli.md` |

Round agrees suspiciously fast → escalate one tier.

## Conversation mechanics

- Reviewer memory = its CLI session; every round resumes it (same cwd), sends only the delta. Reviewers run in parallel.
- Each reply lands in `<TMP_PATH>/<reviewer>.r<N>.final.txt`, one file per round. Orchestrator reads that file only.
- `.log` only when final missing/empty, EXIT≠0, or a verdict smells wrong — never whole: `grep -n` the anchor/finding/`error`, `tail -n 100`, `sed -n` ±50 around hits; ≤10% of the file.

## Draft, Debate, Execute

1. Read all five Superpowers skills once: `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/` → `brainstorming/SKILL.md` (spec), `writing-plans/SKILL.md` (plan), `receiving-code-review/SKILL.md` (arbitration), `verification-before-completion/SKILL.md` (accepting work), `subagent-driven-development/SKILL.md` (execution; helper scripts + reviewer template in that dir).
2. Full brainstorming Q&A with user until spec approval.
3. Spec at `<project>/docs/orchestration/MM-DD-##-spec.md`, debate to all-PASS; then plan at `...-plan.md` from the agreed spec, debate to all-PASS.
4. Each doc: version header, changelog, numbered decision table (stable anchors).
5. Workers execute the plan per subagent-driven-development. Overrides: parallel Workers allowed, one per worktree; merge per `SKILL.md` § Worktrees; one final whole-branch `judgment-reviewer.md` pass.

## Reviewer prompt

Same for all: reviewer reads `adversarial-reviewer.md` itself, path in template — never pasted. `NO MATERIAL OBJECTION` = PASS; anything else = findings to rule on.

Honesty rules — bind Reviewers AND Orchestrator; verbatim round 1, one-line re-pin after:
```
1. Evidence and reasoning only. Agreement never courtesy; disagreement never posture.
2. A finding stands until refuted by a specific fact — not restatement, authority, or repetition. Rejected without refutation → restate it. A rejection marked FINAL closes the item.
3. Shown wrong → concede at once, naming what convinced you; unexplained concession invalid.
4. Never soften, drop, or downgrade a finding to end a round; never add one to look useful.
5. Every accept/reject = one line of why.
6. Re-review the doc itself, not the round message: confirm accepted fixes actually landed before PASS.
```

## Rounds

1. Round 1: all reviewers on v1.
2. Orchestrator rules on every finding on merit. Merge accepted → bump version once; never concurrent versions.
3. Round N: resume each thread with the round-N template.
4. No round cap. Done = every reviewer PASS on the same version → human go/no-go → execute. Second rejection of the same finding = FINAL: rationale in the decision table, reviewer told, item closed.

## Templates

Round 1:
```
Read and follow ~/.claude/skills/orchestrator/adversarial-reviewer.md. Target: <doc path> (v1). Context: <1–2 sentences: purpose, consumer>. <honesty rules>
Number every finding. Do not edit any file.
```
Round N:
```
<doc path> is now v<N>. Your #<ids> accepted. #<ids> rejected: <one line each>. Honesty rules still bind.
Re-review v<N>: new or unresolved findings only, same format; PASS if none.
```

## Hard rules

1. Single writer: only Orchestrator edits, Reviewers read-only.
2. Isolation: reviewers never learn others exist. Conflicts: Orchestrator rules, records rationale in the decision table; overruled side gets decision + reason in its own thread.
3. Pointers, not payloads: reviewers run in the project root, read files themselves. Spikes/experiments → `<TMP_PATH>`.
4. Superpowers: orchestrator reads only the five files named in Draft, Debate, Execute; reviewers and executors get the normal `using-superpowers` prefix.
5. No framework files. `<TMP_PATH>` = transport only, never documentation.
