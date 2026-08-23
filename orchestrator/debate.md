# Debate and Align on Big Plans

Fable authors the spec, dispatches reviewers, arbitrates. Reviewers = independent top-tier CLI models, read-only, each in a private persistent thread, unaware of each other. Human sees only the final go/no-go. Cost irrelevant here. Observed: solo ≈6/10 → 1 partner ≈8 → 2 ≈9.3; returns are concave — cap at 3, spend surplus on depth (rounds, spikes), never on a 4th voice.

## Tiers

| Job size | Partners | Time box |
|---|---|---|
| <30 min, reversible | 0 | — |
| 30–60 min | 1 | ~5 min |
| >1 h | 2 | 15–20 min |
| >5 h / multi-day / irreversible | 3 | hours if needed; add a 2nd pass after the plan is split into task contracts |

Escalate one tier if a round agrees suspiciously fast.

## Committee

| Harness | Read-only flag | Dispatch |
|---|---|---|
| Codex CLI `gpt-5.6-sol` xhigh | `-s read-only` | `codex-cli.md` |
| Grok Build CLI `grok-4.6 --effort xhigh` | `--sandbox read-only` | `grok-cli.md` |
| Cursor CLI `kimi-k3-max` | `--mode ask` | `cursor-cli.md` |

- No roles per model: every reviewer runs the full battery below. Diversity comes from model family, not assigned lenses. Order of addition is arbitrary — rotate; record outcomes in the project ledger, promote a preference only on repeated evidence.
- Opus excluded: same family as Fable → correlated blind spots. Never add a 4th member.

## Battery (verbatim in every round-1 prompt)

Review under three lenses, in order:
1. **Wrong?** Verify every verifiable claim against ground truth — run commands, read code, check docs/platform facts. Cite evidence. Find everything that cannot work as written.
2. **Too much?** Attack complexity, scope, cost. Name what should not be built or decided at all; propose the simpler alternative; price the long-term cost.
3. **Missing / breaks later?** Assume adoption exactly as written. Find missing requirements, unhandled cases, invalidated assumptions, consequences nobody will re-check.

## Drafting

1. Fable writes a decision brief: goals, constraints, decisions taken, open questions (the only prose Fable authors).
2. Drafter expands it to the spec: Workflow `model:'opus', effort:'medium'`, prompt includes "Read and follow `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/brainstorming/SKILL.md` and `.../writing-plans/SKILL.md`" (local files; no plugin needed). Drafter never reviews.
3. Fable edits → v1 at `<project>/docs/orchestration/MM-DD-##.md`. Spec carries a version header, a changelog, and a numbered decision table (stable anchors for every contested choice).

## Rounds

1. Round 1: dispatch all reviewers in parallel on v1, round-1 template. Runner/watcher per `SKILL.md` § CLI Worker Mechanics; Fable reads only `.final.txt`.
2. Fable rules on every finding on merit. Merge accepted ones → bump version once; no concurrent versions after round 1.
3. Round N: resume each reviewer's own thread (CLI resume per its file) with the round-N template. Rejections explained only to that reviewer, briefly.
4. Stop when: all reviewers PASS on the same version; or a round yields zero accepted changes; or the time box is spent. Then Fable decides, logs dissent in the decision table → human go/no-go → execute.

## Templates

Round 1:
```
Read <spec path> (v1). Context: <1–2 sentences: purpose, consumer>.
<battery verbatim>
Output, terse: PASS or NO-GO; then numbered findings — severity, quoted anchor, issue, fix. Do not edit any file.
```
Round N:
```
<spec path> is now v<N>. Your #<ids> accepted. #<ids> rejected: <one line each>.
Re-review v<N> only for new or unresolved findings; same format; PASS if none.
```

## Hard rules

1. Single writer: only Fable edits the spec. Reviewers read-only; their only output is their reply.
2. Isolation: reviewers never learn others exist; never attribute origin; no shared docs, no cross-rebuttal. Conflicts: Fable rules, records rationale in the decision table; the overruled side gets decision + reason in its own thread.
3. Pointers, not payloads: reviewers run in the project root and read files themselves. Spikes/experiments go to `<TMP_PATH>`.
4. Superpowers: Fable none; reviewers and drafter keep their normal prefix.
5. No framework files. `<TMP_PATH>` holds only runner plumbing, never documents.
