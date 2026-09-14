# CodeBuddy CLI

Shared contract: `SKILL.md` § CLI Jobs.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>
codebuddy -p -y --output-format stream-json --model <slug> [--effort <level>] \
  "<prompt>" > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"type":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.result' > <TMP_PATH>/<job>.final.txt
```

Files: log = NDJSON; resume id = `session_id` (every line, first in `"type":"init"`). Success also needs last result line `"is_error":false`.

Flags:
- `--model <slug>` EVERY dispatch. `kimi-k3-2` = debate seat 3 only. `deepseek-v4.1-flash` (40 IQ / 74% SWE) = dormant, never auto-triggered. All others BANNED.
- `--effort`: `kimi-k3-2` → `max`; deepseek has no mapping — omit. `ultracode` accepted though absent from help (below).
- `-y` (`--dangerously-skip-permissions`): REQUIRED, else headless shell/edits blocked. HIGH/CRITICAL-risk commands still ask under `-y` → headless = WAITING; only `CODEBUDDY_IS_SANDBOX=1` (env) passes them — set only for jobs that legitimately need destructive shell.
- Analysis-only: `--permission-mode plan` INSTEAD of `-y` — Read/Grep/Glob allowed, Write + Bash denied (no `git diff` via shell; point it at files). Reads are cwd-scoped and `--add-dir` does NOT widen them — prompt pointing outside the project (skill templates) → `WD=$HOME`.
- `--json-schema '<inline JSON Schema>'` (inline string, not file) → result line carries `structured_output`; extract `jq -r '.structured_output'`.
- Worktree edits: `cd` in, or `--add-dir <dir>`. `--add-dir` is variadic — never place it right before the prompt (prompt gets eaten as a directory → empty instant run, `"tools":[]`); put it before another flag.
- `-w/--worktree` BANNED.

Prompts:
- Claude Code fork — fans out via `Agent` tool (parallel when several calls in one message).
- Superpowers: `~/.codebuddy/plugins/marketplaces/codebuddy-plugins-official/external_plugins/superpowers/skills/using-superpowers/SKILL.md`

Ultracode / Workflows (Claude Code's workflow engine; `ultracode` = model plans workflows unprompted, else the prompt must ask). Only on promoted deepseek, never by default.
- `--effort ultracode` (harness flag, independent of the model's effort map) or keyword `ultracode` in the prompt arms it. Same runner otherwise.
- Script API = Claude Code's minus per-agent `effort` (extra opts: `stallMs`, `maxTurns`); `args` arrives as stringified JSON (script `JSON.parse`s it). Tool is deferred — prompt must say "use the Workflow tool". `/workflows` lists runs.
- Prompt shape: "ultracode. Use the Workflow tool. <N> parallel agents: <job>. Final answer: <shape>."

Follow-ups:
- Resume: same cmd + `--resume <session_id>` — memory intact. `--fork-session` + `--resume` = branch, original untouched.
