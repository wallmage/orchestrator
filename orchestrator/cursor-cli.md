# Cursor CLI

Shared contract: `SKILL.md` § CLI Workers.

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

Files: log = NDJSON (liveness); resume id = first `"session_id"` in log. Success also needs last result line `"is_error":false`.

Flags:
- `--model <slug>` EVERY dispatch; effort + fast baked into slug. Allowed ONLY:
  - Grok 4.6, always fast: `cursor-grok-4.6-medium-fast` | `cursor-grok-4.6-high-fast` | `cursor-grok-4.6-xhigh-fast`.
  - Kimi K3 (no fast variant): `kimi-k3-high` | `kimi-k3-max`.
  - Never non-fast grok slugs, `auto`, or others. `cursor-agent --list-models` to re-check.
- `--force`: REQUIRED — else headless shell/edits blocked. Deny rules in `~/.cursor/cli-config.json` still win.
- `--trust`: skip workspace-trust prompt.
- `--mode ask` = analysis-only (read-only); `--mode plan` = plan-only.
- Worktree edits: `cd` in, or `--add-dir <dir>`.
- No schema flag (demand JSON in prompt), no image flag.
- `-w/--worktree` BANNED — makes own worktree under `~/.cursor/worktrees`.

Prompts:
- Fans out via `Task` tool (built-in Explore/Bash/Browser, custom `.cursor/agents/*.md`; parallel when several calls in one message). Remind: "Use Task subagents in parallel to make the task faster".
- Superpowers: `~/.cursor/skills/using-superpowers/SKILL.md`.

Follow-ups:
- Resume: same cmd + `--resume <session_id>` — same cwd. `--continue` = latest.
- Review: none — normal job + `--mode ask`.
