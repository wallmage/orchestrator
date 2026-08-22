# Cursor CLI

Shared contract (runner shape, files, success rule, superpowers, resume/cancel): `SKILL.md` § CLI Worker Mechanics.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>
cursor-agent -p --force --trust --output-format stream-json --model <slug> \
  "<prompt>" > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"type":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.result' > <TMP_PATH>/<job>.final.txt
```

Files: log is an NDJSON stream (watcher liveness); resume id = first `"session_id"` in the log. Success additionally requires the last `result` line to carry `"is_error":false`.

Flags:
- `--model <slug>` on EVERY dispatch; effort and fast are baked into the slug. Allowed slugs ONLY:
  - Grok 4.6, always fast: `cursor-grok-4.6-medium-fast` | `cursor-grok-4.6-high-fast` | `cursor-grok-4.6-xhigh-fast` (bracket form `'grok-4.6[effort=medium,fast=true]'` is equivalent).
  - Kimi K3 (no fast variant): `kimi-k3-high` | `kimi-k3-max`.
  - Never non-fast grok slugs, `auto`, or any other model. `cursor-agent --list-models` to re-check.
- `--force` (alias `--yolo`): REQUIRED — without it headless shell/edits are blocked. Deny rules in `~/.cursor/cli-config.json` still win.
- `--trust`: skip the workspace-trust prompt.
- `--mode ask` for analysis-only (read-only); `--mode plan` for plan-only.
- Worktree edits: `cd` into the worktree, or `--add-dir <dir>` as an extra root; `--workspace <path>` is the flag form of `cd`.
- No schema flag (demand JSON in the prompt), no image flag.
- `-w/--worktree` BANNED — makes its own worktree under `~/.cursor/worktrees`.
- Rare: `--sandbox enabled|disabled`; `--approve-mcps`; `--output-format json` single object (no liveness — keep stream-json).

Prompts:
- Fans out via the `Task` tool (built-in Explore/Bash/Browser, custom `.cursor/agents/*.md`; parallel when several Task calls go in one message). Remind: "Use Task subagents in parallel to make the task faster".
- Superpowers path: `~/.cursor/skills/using-superpowers/SKILL.md`.

Follow-ups:
- Resume: `cursor-agent -p --force --trust --output-format stream-json --model <slug> --resume <session_id> "<delta>"` — same cwd. `--continue` = most recent session.
- Review: no review subcommand — normal job with `--mode ask`.
