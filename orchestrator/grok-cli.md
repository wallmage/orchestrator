# Grok Build CLI

Shared contract: `SKILL.md` § CLI Workers.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>                 # sessions keyed by cwd — resume must run from same dir
grok -p "<prompt>" -m grok-4.6 --effort <medium|xhigh> --always-approve \
  --output-format streaming-messages-json > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"type":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.structured_output // .result' > <TMP_PATH>/<job>.final.txt
```

Files: log = NDJSON (liveness); resume id = first `"session_id"` in log. Signal kills exit 130/143, session saved to last tool call.

Flags:
- `-m grok-4.6` + `--effort` EVERY dispatch: `medium` = worker, `xhigh` = escalated/reviewer (omitted defaults to `high` — neither lane). Never `grok-4.5`.
- `--always-approve`: required unattended; deny rules + hooks still apply.
- `--sandbox read-only` = analysis-only. Default `off` — worktree edits need only path in prompt.
- `--json-schema '<inline JSON>'` (string, not file) → `structured_output` in result line (runner prefers).
- `--prompt-file <path>` for long prompts.
- `--cwd` BANNED — always `cd`. `-w/--worktree` BANNED.
- `--max-turns <N>` for runaway risk (`stopReason: max_turn_requests`).

Prompts:
- Fans out via `spawn_subagent` (`general-purpose|explore|plan`, depth 1, parallel, own context); remind explicitly.
- Superpowers: `~/.grok/installed-plugins/superpowers-5993746a/skills/using-superpowers/SKILL.md`

Follow-ups:
- Resume: `grok -p "<delta>" -r <session_id> -m grok-4.6 --effort <same> --always-approve --output-format streaming-messages-json` — same cwd, same `--sandbox` (differing refused).
- Review: normal job + `--sandbox read-only`.
