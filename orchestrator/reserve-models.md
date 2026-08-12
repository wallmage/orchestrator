# Reserve Models

## Kimi K3 (`kimi-code/k3-256k`, effort max) — taste-critical front-end design; user trigger only

- Binary `kimi` (config `~/.kimi-code/config.toml`, default model k3-256k). One-shot: `kimi -p "<prompt>" --output-format stream-json`; harvest `{"role":"assistant","content":…}` text (skip null/tool events). Reply cleaning: as-is parse → fenced block → outermost braces. Resume: `-r <id>`. `-p` takes NO permission flag (`-y`/`--auto` rejected).
- No background, no `-o`: same runner shape as Codex, but `kimi -p` is immune to the live-stdin freeze. Capture `rc=$?` BEFORE harvesting into `<job>.final.txt` (or you record the harvest's status), then `echo "EXIT=$rc" >> <job>.log`. Watcher env: `PIDFILE=... OUTFILE=... CPU_PATTERN=kimi`. Reports no usage stats.
- Git: NEVER. Kimi's system rule demands human confirmation — it builds the worktree then stalls forever (work stranded, watcher reads success). Always give it §7's default no-git prompt; never the exception.
