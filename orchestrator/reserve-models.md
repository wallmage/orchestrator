# Reserve Models

## Kimi K3 — model `k3-256k` via the Kimi Code CLI, effort max — taste-critical front-end design; user trigger only

- CLI binary: `kimi`. Config `~/.kimi-code/config.toml` has `default_model = "kimi-code/k3-256k"` (provider/model) — no model flag needed.
- One-shot: `kimi -p "<prompt>" --output-format stream-json`.
- Answer = lines shaped `{"role":"assistant","content":…}`; skip null/tool events.
- Reply cleaning order: as-is parse → fenced block → outermost braces.
- Resume: `-r <id>`.
- `-p` takes NO permission flag (`-y`/`--auto` rejected).
- No background mode, no `-o`: use the Codex runner shape (`kimi -p` is immune to the live-stdin freeze).
- Harvest: capture `rc=$?` BEFORE extracting the assistant text into `<job>.final.txt`, then `echo "EXIT=$rc" >> <job>.log`.
- Watcher env: `PIDFILE=... OUTFILE=... CPU_PATTERN=kimi`.
