# Debate Big Jobs

Orchestrator drafts spec + plan, dispatches adversarial reviewers, arbitrates. Cost irrelevant.

## Committee

Each tier adds one reviewer:

| Job size | Time box | Adds reviewer | Read-only flag | Dispatch |
|---|---|---|---|---|
| <1h | — | — | — | — |
| 1-2h | 30 min max | Cursor CLI `cursor-grok-4.6-xhigh-fast` | `--mode ask` | § Cursor CLI |
| 2-4h | 60 min max | + Codex CLI `gpt-5.6-sol` xhigh | `-s read-only` | `codex-cli.md` |
| >4h | can be hours | + CodeBuddy CLI `kimi-k3-2 --effort max` | `--permission-mode plan` | `codebuddy-cli.md` |

Round agrees suspiciously fast → escalate one tier.

## Conversation mechanics

- Reviewer memory = its CLI session; every round resumes it (same cwd), sends only the delta. Reviewers run in parallel.
- Dispatch each round with `QUIET=1`; act at FLEET DONE; read every `<TMP_PATH>/<reviewer>.r<N>.final.txt` in ONE call. Orchestrator reads finals only.
- `.log` only when final missing/empty, EXIT≠0, or a verdict smells wrong — never whole: `grep -n` the anchor/finding/`error`, `tail -n 100`, `sed -n` ±50 around hits; ≤10% of the file.

## Draft, Debate, Execute

1. Read ONLY 5 Superpowers skills once: `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/` → `brainstorming/SKILL.md` (spec), `writing-plans/SKILL.md` (plan), `receiving-code-review/SKILL.md` (arbitration), `verification-before-completion/SKILL.md` (accepting work), `subagent-driven-development/SKILL.md` (execution; helper scripts + reviewer template in that dir).
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

## Rounds — hard cap 3, any committee size

Reviewer count buys coverage per round, never more rounds. Observed: r1 24 findings (20 shippable), r2 15 (8), r3 11 (2), r4–r7 ≤1 each — every one a regression of the previous fix; past r3 the doc grows legal text and quality falls.

1. Round 1 — discovery: all reviewers on v1. Rule on every finding on merit. Merge accepted → bump version once; never concurrent versions.
2. Round 2 — verify landed + regressions: resume each thread with the round-N template. Accept only findings passing the Ship test; park the rest (decision table, no edit).
3. Round 3 — only if round 2 accepted ≥1 Ship-test finding. Its Ship-test findings are fixed without re-review. Done.
4. Round 2+ still finding Ship-test holes in ORIGINAL text (not regressions) = under-designed → back to brainstorm, never round 4.
5. Done = a round with zero Ship-test findings, or round-3 fixes applied → human go/no-go → execute. Second rejection of same finding = FINAL: stamp FINAL in reviewer's next message (closes the item), rationale → decision table.

Ship test (gate from round 2): a normal user would hit it — wrong output, lost/overwritten data, a mode that cannot run, a documented promise that is false. Wording, hygiene, cross-doc consistency, ≥3-unusual-step edge cases → park.
Edit budget: accepted fix ≤1 sentence; needs more → park. Executable target → one real run per round beats a reviewer (they reason statically).

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

1. Only Orchestrator edits, Reviewers read-only.
2. Reviewers never learn others exist. Conflicts: Orchestrator adjudicates, records rationale in decision table.
3. Pointers, not payloads: reviewers run in the project root. Spikes/experiments → `<TMP_PATH>`.
4. No framework files. `<TMP_PATH>` = transport only, never documentation.
