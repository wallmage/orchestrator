# Codex CLI

Shared contract: `SKILL.md` § CLI Workers.

Runner:

```sh
exec </dev/null
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>                 # never a worktree — session cwd files the Codex app's project list
codex exec --json -o <TMP_PATH>/<job>.final.txt -m <model> -c model_reasoning_effort=<effort> \
  -s workspace-write "<prompt>" > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
```

Files: `-o` writes `.final.txt` directly. Resume id = `thread_id` in log. Log `item.type":"error"` can be benign warnings ("Under-development features enabled") — failure = `"type":"turn.failed"` or `EXIT≠0`, nothing else.

Flags:
- `-m` + `-c model_reasoning_effort=` EVERY dispatch (config default `gpt-5.6-luna` xhigh — never rely on it).
- Models: `gpt-5.6-sol` | `gpt-5.6-luna` only (bare `gpt-5.6` invalid). Effort `low|medium|high|xhigh` only.
- `-s read-only` = analysis-only (`read-only|workspace-write|danger-full-access`).
- `--output-schema <file>`: JSON Schema file fixing answer shape; `-o` then holds JSON. Every property needs explicit `type`; `uniqueItems` unsupported.
- `-C <dir>` BANNED — always `cd` to project root.
- Worktree edits: path in prompt ("Work in `<path>`") + `--add-dir <dir>` to make writable.
- Rare: `-i <img>` attaches an image.

Prompts:
- Parent thread fans out 3 parallel subagents (max 4 workers); remind explicitly.
- Superpowers: `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/using-superpowers/SKILL.md` (bump version # if plugin changes).

Follow-ups:
- Resume: `codex exec resume <thread_id> --json -o <f> -m <same model> -c model_reasoning_effort=<same> "<delta>"` — without `-m` silently falls back to config model. Takes no `-C`/`-s`; inherits shell cwd (session lookup cwd-filtered; `--all` lifts). Accepts `--output-schema`.
- Fork: `codex exec fork <thread_id> --json -o <f> -m <model> "<delta>"` — branch, original untouched.
- Review: `codex exec review --uncommitted|--base <ref>|--commit <sha> --json -o <f>` (optional `-m`, `--title`, `--output-schema`).
