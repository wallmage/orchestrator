# CodeBuddy CLI

Shared contract: `SKILL.md` § CLI Workers.

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
- `--model <slug>` + `--effort max` EVERY dispatch (`ultracode` for workflow jobs). Allowed ONLY: `kimi-k3-2` | `glm-5.3-flash` | `hy4-preview`. All others BANNED.
- `-y` (`--dangerously-skip-permissions`): REQUIRED — else headless shell/edits blocked.
- Analysis-only: `--permission-mode plan` INSTEAD of `-y` — Read/Grep/Glob allowed, Write + Bash denied (no `git diff` via shell; point it at files). Reads are cwd-scoped and `--add-dir` does NOT widen them — prompt points outside the project (skill templates) → `WD=$HOME`.
- `--json-schema '<inline JSON Schema>'` (inline string, not file) → result line carries `structured_output`; extract `jq -r '.structured_output'`.
- Worktree edits: `cd` in, or `--add-dir <dir>`. `--add-dir` is variadic — never place it right before the prompt (prompt gets eaten as a directory → empty instant run, `"tools":[]`); put it before another flag.
- `-w/--worktree` BANNED — orchestrator owns worktrees.
- Rare: `--max-turns <n>`.

Prompts:
- Claude Code fork — fans out via `Agent` tool (parallel when several calls in one message). Remind: "Use subagents to make the task faster".
- Superpowers: `~/.codebuddy/plugins/marketplaces/codebuddy-plugins-official/external_plugins/superpowers/skills/using-superpowers/SKILL.md` (marketplace clone, plugin not installed; read-by-path works).

Ultracode / Dynamic Workflows (full Claude Code workflow engine):
- Workflow model: `glm-5.3-flash` ONLY — parallelism over peak IQ.
- `--effort ultracode` = effort high + Workflow tool armed; keyword `ultracode` in prompt arms it per-message too. Same runner otherwise.
- Script API = Claude Code's minus per-agent `effort` (extra opts: `stallMs`, `maxTurns`); `args` arrives as stringified JSON (script `JSON.parse`s it). Tool is deferred — prompt must say "use the Workflow tool". `/workflows` lists runs.
- Prompt shape: "ultracode. Use the Workflow tool. <N> parallel agents: <job>. Final answer: <shape>."

Follow-ups:
- Resume: same cmd + `--resume <session_id>` — same cwd, memory intact. `--fork-session` + `--resume` = branch, original untouched.
- Review: none — normal job + `--permission-mode plan`.
