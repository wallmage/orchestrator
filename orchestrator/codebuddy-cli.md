# CodeBuddy CLI
<!-- cli: codebuddy :: update: codebuddy update :: help: codebuddy --help :: models: codebuddy --help | grep -o 'Currently supported: ([^)]*)' :: changelog: awk -v o="$OLD" '/^## \[[0-9]/{if(index($0,o))exit; p=1} p' "$(npm root -g)/@tencent-ai/codebuddy-code/CHANGELOG.md" -->

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

Files: log = NDJSON (liveness); resume id = `session_id` (every line, first in `"type":"init"`). Success also needs last result line `"is_error":false`.

Flags:
- `--model <slug>` EVERY dispatch. Active: `kimi-k3-2` = debate seat 3 only. Dormant — no roster role, NEVER auto-triggered; the user promotes them by hand when Claude/Cursor quota is gone, or when the orchestrator has no Claude-side `Workflow` (e.g. a Codex/GPT orchestrator) and needs a workflow engine: `deepseek-v4.1-flash` (40 IQ / 74% SWE, fastest). All others BANNED (`glm-5.3-flash`, `hy4-preview` dropped).
- Effort per model (verified in the CLI's model catalog): `deepseek-v4.1-flash` has NO effort mapping — omit `--effort` (accepted, no-op); `kimi-k3-2` → `--effort max`. `--effort ultracode` is harness-side (any model, see below).
- Context tier: CLI exposes one slug per model (reports 1M window); the 300K/1M tiers in the WorkBuddy GUI are not selectable here. `--autocompact 300k` keeps every request under 300K input — add it if Tencent bills by request size (verify on the usage dashboard); cost = earlier compaction on long jobs.
- `-y` (`--dangerously-skip-permissions`): REQUIRED — else headless shell/edits blocked. HIGH/CRITICAL-risk commands still ask even under `-y` → headless = WAITING; only `CODEBUDDY_IS_SANDBOX=1` (env) passes them — set it only for jobs that legitimately need destructive shell.
- `--effort` help lists `minimal…max`; `ultracode` still accepted (not in help text).
- Analysis-only: `--permission-mode plan` INSTEAD of `-y` — Read/Grep/Glob allowed, Write + Bash denied (no `git diff` via shell; point it at files). Reads are cwd-scoped and `--add-dir` does NOT widen them — prompt points outside the project (skill templates) → `WD=$HOME` (verified: reads `~/.claude/...` fine from there).
- `--json-schema '<inline JSON Schema>'` (inline string, not file) → result line carries `structured_output`; extract `jq -r '.structured_output'`.
- Worktree edits: `cd` in, or `--add-dir <dir>`. `--add-dir` is variadic — never place it right before the prompt (prompt gets eaten as a directory → empty instant run, `"tools":[]`); put it before another flag.
- `-w/--worktree` BANNED — orchestrator owns worktrees.
- Rare: `--max-turns <n>`.

Prompts:
- Claude Code fork — fans out via `Agent` tool (parallel when several calls in one message). Remind: "Use subagents to make the task faster".
- Superpowers: `~/.codebuddy/plugins/marketplaces/codebuddy-plugins-official/external_plugins/superpowers/skills/using-superpowers/SKILL.md` (marketplace clone, plugin not installed; read-by-path works).

Ultracode / Dynamic Workflows (full Claude Code workflow engine — same engine, `ultracode` = model plans workflows unprompted, otherwise the prompt must ask). Use ONLY with a promoted dormant model AND a job that needs internal fan-out (no Claude-side `Workflow` available: quota loss, or a non-Claude orchestrator); single jobs run plain:
- Workflow model: `deepseek-v4.1-flash` (Workflow tool present in its tool list; 74% SWE, fastest).
- `--effort ultracode` = harness flag: sets `workflowEffortLevel` + injects the plan-workflows reminder, independent of the model's effort map (works on deepseek). Keyword `ultracode` in prompt arms it per-message too. Same runner otherwise.
- When to use over Claude-side `Workflow`: only when the fleet must outlive the orchestrator session (multi-hour mechanical fan-out; Claude-side Workflow dies with the session, CLI jobs keep writing `.final.txt` and are re-adopted via bare `watcher.sh`), or Claude is down. Otherwise Claude-side Workflow wins: in-session, no dispatch overhead, Opus agents, per-agent effort.
- Script API = Claude Code's minus per-agent `effort` (extra opts: `stallMs`, `maxTurns`); `args` arrives as stringified JSON (script `JSON.parse`s it). Tool is deferred — prompt must say "use the Workflow tool". `/workflows` lists runs.
- Prompt shape: "ultracode. Use the Workflow tool. <N> parallel agents: <job>. Final answer: <shape>."

Follow-ups:
- Resume: same cmd + `--resume <session_id>` — same cwd, memory intact. `--fork-session` + `--resume` = branch, original untouched.
- Review: none — normal job + `--permission-mode plan`.
