# Debate and Align on Big Plans

Fable authors spec + implementation plan, dispatches reviewers, arbitrates. Reviewers = independent top-tier CLI models, read-only, each in a private persistent thread, unaware of each other. Human sees only the final go/no-go. Cost irrelevant here. Observed: solo ≈6/10 → 1 partner ≈8 → 2 ≈9.3; returns concave — cap committee at 3, spend surplus on rounds and depth, never a 4th voice.

## Tiers

| Job size | Partners | Time box |
|---|---|---|
| <30 min, reversible | 0 | — |
| 30–60 min | 1 | ~5 min (spec+plan may be one doc, one debate) |
| >1 h | 2 | 15–20 min |
| >5 h / multi-day / irreversible | 3 | hours if needed |

Escalate one tier if a round agrees suspiciously fast.

## Committee

| Harness | Read-only flag | Dispatch |
|---|---|---|
| Codex CLI `gpt-5.6-sol` xhigh | `-s read-only` | `codex-cli.md` |
| Grok Build CLI `grok-4.6 --effort xhigh` | `--sandbox read-only` | `grok-cli.md` |
| Cursor CLI `kimi-k3-max` | `--mode ask` | `cursor-cli.md` |

- No roles per model: every reviewer runs the full battery. Diversity comes from model family. Order of addition arbitrary — rotate; record outcomes in the project ledger; prefer a model only on repeated evidence.
- Opus excluded (Fable's family → correlated blind spots). Never a 4th member.

## Drafting (Fable)

1. One-time read, this job only: `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/brainstorming/SKILL.md` and `.../writing-plans/SKILL.md` (local files; superpowers is deliberately NOT installed in Claude Code — no hooks, no auto-trigger). Use their design checklist and plan format; skip their interactive Q&A and execution-handoff parts. Their `*-reviewer-prompt.md` siblings may extend the battery.
2. Write the spec at `<project>/docs/orchestration/MM-DD-##-spec.md`; debate it to all-PASS. Then write the plan at `...-plan.md` from the agreed spec; debate it to all-PASS. Plans follow writing-plans format (TDD steps are for workers, not Fable).
3. Each doc carries a version header, changelog, and numbered decision table (stable anchors for every contested choice). Only Fable edits.

## Conversation mechanics

- A reviewer is a CLI process: no shared mind. Its memory = its CLI session (resume id); its voice = its final reply, which the runner writes to `<TMP_PATH>/<reviewer>.r<N>.final.txt` (new file per round, never overwrite; `.log` alongside). Fable reads `.final.txt` only; the `.log` holds the full transcript (reasoning, tool calls) — open it only when a reply looks unfounded.
- Round N = resume that reviewer's thread (per its CLI file, same cwd) with the round-N template; runner + watcher per `SKILL.md` § CLI Worker Mechanics. All reviewers per round in parallel.
- This is a real conversation: reviewer remembers everything; Fable sends only deltas.

## Battery (verbatim in round 1)

Review under three lenses, in order:
1. **Wrong?** Verify every verifiable claim against ground truth — run commands, read code, check docs/platform facts. Cite evidence. Find everything that cannot work as written.
2. **Too much?** Attack complexity, scope, cost. Name what should not be built or decided at all; propose the simpler alternative; price the long-term cost.
3. **Missing / breaks later?** Assume adoption exactly as written. Find missing requirements, unhandled cases, invalidated assumptions, consequences nobody will re-check.

Honesty clause (verbatim, every round, binds Fable too): "Be 100% honest. Accept or reject only on facts and reasoning. Do not defer, do not agree to be agreeable; hold your ground while you believe you are right, and always explain why. Concede only when convinced."

## Rounds

1. Round 1: all reviewers in parallel on v1.
2. Fable rules on every finding on merit. Merge accepted ones → bump version once; never concurrent versions.
3. Round N: resume each thread with the round-N template; rejections explained to that reviewer only, one line each.
4. No round cap. Done only when every reviewer returns PASS on the same version → human go/no-go → execute. Stalemate (one item unchanged 3 rounds, both sides holding) → that single item goes to the human; everything else continues.

## Templates

Round 1:
```
Read <doc path> (v1). Context: <1–2 sentences: purpose, consumer>.
<battery verbatim> <honesty clause>
Output, terse: PASS or NO-GO; then numbered findings — severity, quoted anchor, issue, fix. Do not edit any file.
```
Round N:
```
<doc path> is now v<N>. Your #<ids> accepted. #<ids> rejected: <one line each>. <honesty clause>
Re-review v<N>: new or unresolved findings only, same format; PASS if none.
```

## Hard rules

1. Single writer: only Fable edits the docs. Reviewers read-only; their only output is their reply.
2. Isolation: reviewers never learn others exist; never attribute origin; no shared docs, no cross-rebuttal. Conflicts: Fable rules, records rationale in the decision table; the overruled side gets decision + reason in its own thread.
3. Pointers, not payloads: reviewers run in the project root and read files themselves. Spikes/experiments go to `<TMP_PATH>`.
4. Superpowers: Fable reads the two skill files above for this job only; reviewers keep their normal prefix.
5. No framework files. `<TMP_PATH>` is transport only, never documentation.
