# Grok Build CLI
<!-- cli: grok :: update: grok update :: help: grok --help -->

Shared contract: `SKILL.md` § CLI Jobs.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>
grok -p "<prompt>" -m grok-4.6 --effort <medium|xhigh> --always-approve \
  --output-format streaming-messages-json > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"type":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.structured_output // .result' > <TMP_PATH>/<job>.final.txt
```

Files: log = NDJSON; resume id = first `"session_id"` in log. Signal kills exit 130/143, session saved to last tool call.

Flags:
- `-m grok-4.6` + `--effort` EVERY dispatch: `medium` = worker, `xhigh` = escalated/reviewer (omitted = `high`, no lane). Never `grok-4.5`.
- `--always-approve`: deny rules + hooks still apply.
- `--sandbox read-only` for analysis jobs; default `off` (no extra-dir flag needed).
- `--json-schema '<inline JSON>'` (string, not file) → `structured_output` in result line.
- `--prompt-file <path>` for long prompts.
- `--cwd`, `-w/--worktree` BANNED.
- `--max-turns <N>` for runaway risk (`stopReason: max_turn_requests`).

Prompts:
- Fans out via `spawn_subagent` (`general-purpose|explore|plan`, depth 1, parallel, own context).
- Superpowers: `~/.grok/installed-plugins/superpowers-5993746a/skills/using-superpowers/SKILL.md`

Follow-ups:
- Resume: `grok -p "<delta>" -r <session_id> -m grok-4.6 --effort <same> --always-approve --output-format streaming-messages-json` — same `--sandbox` (differing refused).
