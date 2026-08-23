# Codex CLI

Shared contract (runner shape, files, success rule, superpowers, resume/cancel): `SKILL.md` § CLI Worker Mechanics.

Runner:

```sh
exec </dev/null                   # live stdin pipe freezes codex exec
echo $$ > <TMP_PATH>/<job>.pid
cd <PROJECT ROOT>                 # never a worktree — session cwd files the Codex app's project list
codex exec --json -o <TMP_PATH>/<job>.final.txt -m <model> -c model_reasoning_effort=<effort> \
  -s workspace-write "<prompt>" > <TMP_PATH>/<job>.log 2>&1
printf '\nEXIT=%s\n' $? >> <TMP_PATH>/<job>.log
```

Files: `-o` writes `.final.txt` directly. Resume id = `thread_id` in the log. Log `item.type":"error"` entries can be benign warnings (e.g. "Under-development features enabled") — failure is `"type":"turn.failed"` or `EXIT≠0`, nothing else.

Flags:
- `-m` + `-c model_reasoning_effort=` on EVERY dispatch (config default is `gpt-5.6-luna` xhigh — never rely on it).
- Models: `gpt-5.6-sol` or `gpt-5.6-luna` only (bare `gpt-5.6` is invalid). Effort: `low|medium|high|xhigh` only. `max` and `ultra` exist but are BANNED — never pass them.
- `-s read-only` for analysis-only jobs (`-s` values: `read-only|workspace-write|danger-full-access`).
- `--output-schema <file>`: JSON Schema file fixing the final answer's shape; `-o` then holds the JSON. Every property must declare an explicit `type`; `uniqueItems` unsupported.
- `-C <dir>` BANNED — always `cd` to the project root.
- Worktree edits: name the path in the prompt ("Work in `<path>`") and add `--add-dir <dir>` to make it writable.
- Rare: `-i <img>` attaches an image; `--skip-git-repo-check` allows running outside a git repo; `--ephemeral` skips session persistence (no resume possible).

Prompts:
- Parent thread fans out 3 parallel subagents (max 4 workers); remind it explicitly.
- Superpowers path: `~/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/using-superpowers/SKILL.md` (update version # if plugin changes).

Follow-ups:
- Resume: `codex exec resume <thread_id> --json -o <f> -m <same model> -c model_reasoning_effort=<same> "<delta>"` — without `-m` it silently falls back to the config model and warns. Takes no `-C`/`-s`; inherits shell cwd (session lookup is cwd-filtered; `--all` lifts it). Accepts `--output-schema`.
- Fork: `codex exec fork <thread_id> --json -o <f> -m <model> "<delta>"` — branch a thread without touching the original.
- Review: `codex exec review --uncommitted|--base <ref>|--commit <sha> --json -o <f>` (optional `-m`, `--title`, `--output-schema`).
