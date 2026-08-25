# CodeBuddy CLI

Shared contract: `SKILL.md` § CLI Worker Mechanics.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>
codebuddy -p -y --output-format stream-json --model <slug> --effort max \
  "<prompt>" > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"type":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.result' > <TMP_PATH>/<job>.final.txt
```

Files: log = NDJSON (liveness); resume id = `session_id` (every line, first in `"type":"init"`). Success also needs last result line `"is_error":false`.

Flags:
- `--model <slug>` + `--effort` EVERY dispatch. Allowed ONLY: `kimi-k3-2` (Kimi K3, `max`) | `glm-5.3` (GLM 5.3, `max`) | `deepseek-v4-flash` (DeepSeek V4 Flash, `max`) | `hy3` (Hunyuan Hy3, `high` — free trivia lane, speed over depth). All others (hy3-x, minimax*, deepseek-v4-pro, older kimi/glm) BANNED. Ctx: K3/GLM/DS-Flash 1M, Hy3 192k. Max output: K3 32k, GLM 48k, DS-Flash 50k, Hy3 64k.
- `-y` (`--dangerously-skip-permissions`): REQUIRED — else headless shell/edits blocked.
- Analysis-only: `--permission-mode plan` INSTEAD of `-y` — Read/Grep/Glob allowed, Write + Bash denied (no `git diff` via shell; point it at files).
- `--json-schema '<inline JSON Schema>'` (inline string, not file — unlike Codex) → result line carries `structured_output`; extract `jq -r '.structured_output'`.
- Worktree edits: `cd` in, or `--add-dir <dir>`.
- `-w/--worktree` BANNED — orchestrator owns worktrees.
- Rare: `--max-turns <n>`; `--fallback-model <slug>` (`-p` only); `--tools "Bash,Edit,Read"` restricts built-ins.

Prompts:
- Claude Code fork — fans out via `Agent` tool (parallel when several calls in one message). Remind: "Use subagents to make the task faster".
- Superpowers: `~/.codebuddy/plugins/marketplaces/codebuddy-plugins-official/external_plugins/superpowers/skills/using-superpowers/SKILL.md` (marketplace clone, plugin not installed; read-by-path works).

Follow-ups:
- Resume: same cmd + `--resume <session_id>` — same cwd, memory intact. `-c/--continue` = latest. `--fork-session` + `--resume` = branch, original untouched.
- Review: none — normal job + `--permission-mode plan`.
