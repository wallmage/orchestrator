# Debate and Align on Big Plans

Fable authors the plan, dispatches reviewers, arbitrates. Reviewers are independent CLI models, read-only, one-on-one, unaware of each other. Human sees only the final go/no-go. Cost is irrelevant here: highest-tier intelligence only. Observed: solo plan ≈6/10 → 1 partner ≈8 → 2 partners ≈9.3.

## Tiers

| Job size | Partners | Time box | Roles |
|---|---|---|---|
| <30 min, reversible | 0 | — | Decide alone. |
| 30–60 min | 1 | ~5 min | Verifier |
| >1 h | 2 | 15–20 min | Verifier + Adversary |
| >5 h / multi-day / irreversible | 3 (cap) | as needed | Verifier + Adversary + Red Team |

Fixed battery, never chosen by diagnosing the draft (author can't see own blind spots). Escalate one tier if a round agrees suspiciously fast.

## Partners (fixed order of addition)

| # | Role | Harness | Read-only flag | Dispatch |
|---|---|---|---|---|
| 1 | Verifier | Codex CLI `gpt-5.6-sol` xhigh | `-s read-only` | `codex-cli.md` |
| 2 | Adversary | Grok Build CLI `grok-4.6 --effort xhigh` | `--sandbox read-only` | `grok-cli.md` |
| 3 | Red Team | Cursor CLI `kimi-k3-max` | `--mode ask` | `cursor-cli.md` |

Model notes (update only on strong repeated evidence): sol — evidence-cited verification, completeness bias; grok — strong economy/simplicity, may pass designs that don't mechanically work.

## Roles (quote verbatim; extend with job specifics, never dilute)

- **Verifier — is it wrong?** "Verify every verifiable claim against ground truth — run commands, read the code, check docs/platform facts. Cite evidence per finding. Find everything that cannot work as written."
- **Adversary — is it too much?** "Attack complexity, scope, cost. Find what should not be built or decided at all, propose the simpler alternative, price what the draft's structures cost over time."
- **Red Team — what's missing / breaks later?** "Assume this is adopted exactly as written. Find where it fails afterward: missing requirements, unhandled cases, invalidated assumptions, long-term consequences nobody will re-check."

## Hard rules

1. Single writer: only Fable edits the artifact (the spec at `<project>/docs/orchestration/MM-DD-##.md`).
2. Isolation: reviewers never learn others exist; never attribute origin; no shared docs, no cross-rebuttal.
3. Arbiter: Fable accepts/rejects each item on merit. Rejections explained in that reviewer's thread only; acceptances merged, version bumped, all reviewers re-review the same version.
4. Pointers, not payloads: reviewers run in the project root and read files themselves; prompts carry paths.
5. No superpowers prefix, no framework files. Review outputs live in `<TMP_PATH>`, never in the repo.
6. Runner/watcher/resume per `SKILL.md` § CLI Worker Mechanics; one persistent thread per reviewer, later rounds via that CLI's resume.

## Invocation

```
Role: <verbatim role>.
Context: <1–2 sentences: purpose, consumer>.
Read: <artifact path(s)>.
Output: PASS or NO-GO, then numbered findings, each quoting the exact text it targets.
Do not edit any file.
```

## Rounds

1. Draft with a numbered decision table for contested choices (stable addresses).
2. Round 1: all reviewers in parallel on the same version — disagreement is the harvest.
3. Merge all round-1 output at once; bump version once. Never review different versions concurrently after round 1.
4. Later rounds delta-scoped: "Verify only that items <N…> were applied; do not reopen settled design." Exit condition per reviewer: "you hear from me again only if your signed items change."
5. Cap 3 rounds per reviewer; then Fable decides unilaterally, logs dissent in the decision table.
6. Done when every reviewer returns PASS on the same version → human go/no-go → execute.

Conflicts: Fable rules on merit, records rationale in the decision table; the overruled side gets decision + reasoning in its own thread, never the other's identity or words.
