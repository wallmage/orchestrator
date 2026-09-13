# Orchestrator

Claude Code skill: an expensive model orchestrates, cheaper models execute. The orchestrator writes sealed-envelope contracts, verifies results from disk, and spends its own tokens only on judgment.

## Contents

- `SKILL.md` — delegation gates, model roster, dispatch mechanics, worktree/git protocol, reviewers, debugging rules.
- `debate.md` — spec + plan debate with an adversarial reviewer committee for jobs over an hour.
- `adversarial-reviewer.md`, `judgment-reviewer.md` — reviewer prompts, read by path.
- `codex-cli.md`, `codebuddy-cli.md` — per-CLI runners and flags (Cursor lives in `SKILL.md`; `grok-cli.md` parked).
- `dispatch.sh`, `watcher.sh` — fleet launcher and per-job watcher.
- `update-clis.sh` — update CLIs, diff help and models, flag doc drift. `sync-rules.sh` — copy the master AGENTS.md to each CLI's rules file.

Model names, slugs, and paths describe one machine's toolchain. Rewrite them for yours.

## Install

```bash
cp -r orchestrator ~/.claude/skills/orchestrator
```

Invoke with `/orchestrator` or "orchestrate this".

## License

MIT — see [LICENSE](LICENSE).
