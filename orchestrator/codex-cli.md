# Codex CLI

Shared contract: `SKILL.md` § CLI Jobs.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>                 # never a worktree — session cwd files the Codex app's project list
codex exec --json -o <TMP_PATH>/<job>.final.txt -m <model> -c model_reasoning_effort=<effort> \
  -s workspace-write "<prompt>" > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
```

Files: `-o` writes `.final.txt` directly. Resume id = `thread_id` in log. `item.type":"error"` lines can be benign warnings — failure = `"type":"turn.failed"` or `EXIT≠0`, nothing else.

Flags:
- `-m` + `-c model_reasoning_effort=` EVERY dispatch.
- `gpt-6-astra` ONLY, `xhigh` = debate reviewer, no other lane. Levels `low…max`unused. Source: `supported_reasoning_levels` in `~/.codex/models_cache.json`.
- `-s read-only|workspace-write|danger-full-access`; `read-only` = analysis-only.
- `--output-schema <file>`: JSON Schema file fixing answer shape; `-o` then holds JSON. Every property needs explicit `type`; `uniqueItems` unsupported.
- `-C <dir>`, `--worktree` BANNED.
- Worktree edits: `--add-dir <dir>` makes it writable.

Prompts:

- Superpowers: `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/using-superpowers/SKILL.md` (bump version if plugin changes).

Follow-ups:
- Resume: `codex exec resume <thread_id> --json -o <f> -m <same model> -c model_reasoning_effort=<same> "<delta>"` — no `-C`/`-s`; restores the thread's saved cwd (lookup cwd-filtered; `--all` lifts). Accepts `--output-schema`.
- Fork: `codex exec fork <thread_id> --json -o <f> -m <model> "<delta>"` — branch, original untouched.
- Review: `codex exec review --uncommitted|--base <ref>|--commit <sha> --json -o <f>` (optional `-m`, `--title`, `--output-schema`).
