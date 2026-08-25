# CodeBuddy CLI

Shared contract (runner shape, files, success rule, superpowers, resume/cancel): `SKILL.md` § CLI Worker Mechanics.

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

Files: log is an NDJSON stream (watcher liveness); resume id = `session_id` (on every line, first in the `"type":"init"` line). Success additionally requires the last `result` line to carry `"is_error":false`.

Flags:
- `--model <slug>` + `--effort max` on EVERY dispatch. Allowed slugs ONLY: `kimi-k3-2` (Kimi K3) | `glm-5.3` (GLM 5.3); effort ALWAYS `max` for both. Every other listed model (hy3*, minimax*, deepseek*, older kimi/glm) BANNED. Both 1M ctx; max output K3 32k / GLM 48k.
- `-y` (`--dangerously-skip-permissions`): REQUIRED — without it headless shell/edits are blocked.
- Analysis-only: `--permission-mode plan` INSTEAD of `-y` — Read/Grep/Glob allowed, Write and Bash denied (no `git diff` via shell; point it at files).
- Structured answers: `--json-schema '<inline JSON Schema string>'` (inline, not a file — unlike Codex); result line then carries `structured_output` — extract with `jq -r '.structured_output'` instead of `.result`.
- Worktree edits: `cd` into the worktree, or `--add-dir <dir>` as an extra root.
- `-w/--worktree` BANNED — makes its own worktree; orchestrator owns worktrees.
- Rare: `--max-turns <n>`; `--fallback-model <slug>` (only with `-p`); `--tools "Bash,Edit,Read"` restricts built-in tools.

Prompts:
- Claude Code fork — fans out via the `Agent` tool (parallel when several calls go in one message). Remind: "Use subagents to make the task faster".
- Superpowers path: `~/.codebuddy/plugins/marketplaces/codebuddy-plugins-official/external_plugins/superpowers/skills/using-superpowers/SKILL.md` (marketplace clone — plugin not installed; read-by-path works).

Follow-ups:
- Resume: `codebuddy -p -y --output-format stream-json --model <same slug> --effort max --resume <session_id> "<delta>"` — same cwd; memory verified intact. `-c/--continue` = most recent session. `--fork-session` with `--resume` branches without touching the original.
- Review: no headless review subcommand — normal job with `--permission-mode plan`.
