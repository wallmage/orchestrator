# Cursor CLI

PARKED — subscription cancelled, binary removed. Never dispatch. Unpark = restore a roster row in `SKILL.md`.

Shared contract: `SKILL.md` § CLI Jobs.

JOBS command (one line, no single quotes — JOBS is single-quoted):

```sh
cursor-agent -p --force --trust --output-format stream-json --model <slug> "$(cat <TMP_PATH>/<job>.prompt)"; rc=$?; grep -a \"type\":\"result\" <TMP_PATH>/<job>.log | tail -1 | jq -r .result > <TMP_PATH>/<job>.final.txt; exit $rc
```

Files: log = NDJSON; resume id = first `"session_id"` in log. Success also needs last result line `"is_error":false`.

Flags:
- `--model cursor-grok-4.6-medium-fast` (worker, task reviewer) or `cursor-grok-4.6-xhigh-fast` (debate/judgment reviewer); every other slug BANNED. Ladder: `cursor-agent --list-models | grep grok`.
- `--force`: REQUIRED, else headless shell/edits blocked. Deny rules in `~/.cursor/cli-config.json` still win.
- `--trust`: skips workspace-trust prompt. `--approve-mcps` only if the job needs MCP servers.
- `--mode ask` = read-only; `--mode plan` = plan-only.
- Worktree edits: `cd` in, or `--add-dir <dir>`.
- No schema or image flag.
- ~300k context.
- `-w/--worktree`, `--workspace` BANNED.

Prompts:
- Fan-out = `Task` tool (built-in Explore/Bash/Browser, custom `.cursor/agents/*.md`; parallel when several calls share one message). Remind: "Use Task subagents in parallel to make the task faster".
- Superpowers: `~/.cursor/skills/using-superpowers/SKILL.md`.

Follow-ups:
- Resume: `--resume <session_id>`; `--continue` = latest.
