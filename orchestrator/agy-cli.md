# Antigravity CLI (`agy`, Gemini)

Shared contract: `SKILL.md` § CLI Worker Mechanics.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>
agy -p "<prompt>" --model gemini-3.7-flash --effort high --dangerously-skip-permissions \
  --output-format stream-json --print-timeout 30m > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"event":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.result.structured_output // .result.response' > <TMP_PATH>/<job>.final.txt
```

Files: log = NDJSON (`step_update` events = liveness); resume id = `conversation_id` in `init` line (first). Success also needs last result line `"status":"SUCCESS"`; errors → `"status":"ERROR"` + exit 1.

Flags:
- `--model gemini-3.7-flash --effort high` EVERY dispatch. Effort menu `low|medium|high`; ALWAYS `high` (free + fast, lower buys nothing). Slug form `gemini-3.7-flash-high` equivalent; slug + `--effort` together = hard error. Other `agy models` (Claude, Gemini Pro, GPT-OSS) BANNED — rostered only as Gemini 3.7 Flash.
- `--dangerously-skip-permissions`: required unattended (init line must show `"permission_mode":"always-proceed"`).
- `--mode plan` = analysis-only: blocks all writes; dumps plan docs under `~/.gemini/antigravity-cli/brain/<cid>/` — ignore, read only the reply.
- `--print-timeout 30m`: default 5m kills longer jobs mid-run — raise EVERY dispatch.
- `--json-schema '<inline JSON or path>'` → result gains `structured_output` (runner prefers).
- Worktree edits: `cd` in, or path in prompt + `--add-dir <dir>`. No cwd flag — always `cd`.
- Rare: `--sandbox` (terminal restrictions); `--input-format stream-json` (NDJSON turns, needs `--output-format stream-json`); `--agent`/`--project` unused.

Prompts:
- Fans out via native subagent tools (`define_subagent`/`invoke_subagent`/`manage_subagents`); remind explicitly.
- Superpowers: `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/using-superpowers/SKILL.md` (plain local files, shared with Codex; bump version # if plugin changes).

Follow-ups:
- Resume: `agy -p "<delta>" --conversation <conversation_id> --model gemini-3.7-flash --effort high --dangerously-skip-permissions --output-format stream-json` — same cwd, memory intact. `-c`/`--continue` = latest.
- Review: none — normal job + `--mode plan`.
