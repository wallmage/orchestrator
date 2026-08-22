# Grok Build CLI

Shared contract (runner shape, files, success rule, superpowers, resume/cancel): `SKILL.md` § CLI Worker Mechanics.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>                 # sessions are keyed by cwd — resume must run from the same dir
grok -p "<prompt>" -m grok-4.6 --effort <effort> --always-approve \
  --output-format streaming-messages-json > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
grep -a '"type":"result"' <TMP_PATH>/<job>.log | tail -1 | jq -r '.structured_output // .result' > <TMP_PATH>/<job>.final.txt
```

Files: log is an NDJSON stream (watcher liveness); resume id = first `"session_id"` in the log. Signal kills exit 130/143, session saved up to the last tool call.

Flags:
- `-m grok-4.6` + `--effort` on EVERY dispatch. Menu for grok-4.6: `low|medium|high|xhigh` (default high if omitted; `--reasoning-effort` is the long form). Never `grok-4.5`.
- `--always-approve` (alias `--yolo`, = `--permission-mode bypassPermissions`): required for unattended runs; deny rules and hooks still apply.
- `--sandbox read-only` for analysis-only jobs (writes only `~/.grok` + temp; irreversible; network block is Linux-only). Default `off` — worktree edits need only the path in the prompt.
- `--json-schema '<inline JSON>'` (string, not file): lands in `structured_output` of the `result` line (runner prefers it).
- `--prompt-file <path>` instead of `-p` for long prompts.
- `--cwd <dir>` BANNED — always `cd`. `-w/--worktree` BANNED (headless ignores it anyway).
- Rare: `--max-turns <N>` (`stopReason: max_turn_requests`); `--deny 'Bash(rm -rf *)'`; `--disable-web-search`; `--no-subagents` for trivial jobs.

Prompts:
- Fans out via `spawn_subagent` (types `general-purpose|explore|plan`, depth 1, parallel, own context); remind it explicitly.
- Superpowers path: `~/.grok/installed-plugins/superpowers-5993746a/skills/using-superpowers/SKILL.md` (plugin is installed natively; `grok inspect` lists its skills; update dir if plugin changes).

Follow-ups:
- Resume: `grok -p "<delta>" -r <session_id> -m grok-4.6 --effort <e> --always-approve --output-format streaming-messages-json` — same cwd, same `--sandbox` (a differing sandbox is refused).
- Review: no review subcommand — normal job with `--sandbox read-only`.
