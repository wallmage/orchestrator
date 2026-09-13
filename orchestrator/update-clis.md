# Update CLIs

Harness-agnostic. Run from the skill dir.

1. Weekly state: `sh update-clis.sh weekly` → `unset` = ask user once "Auto-run weekly? yes/no", store with `sh update-clis.sh weekly <answer>`; `yes` → create scheduled task (Claude: `create_scheduled_task` id `update-clis`, cron `0 9 * * 1`, prompt "update the CLIs"). `yes|no` = silent.
2. `sh update-clis.sh` → read output. Binaries now updated.
3. Inspect, per CLI: HELP-DIFF added/removed, MODELS-DIFF, DRIFT, CHANGELOG. Unknown new subcommand/flag → run its `--help`. Classify:
   - BROKEN: DRIFT hit, or doc runner/flag/slug removed → must fix.
   - RELEVANT: new headless/resume/schema/sandbox/model capability usable by the runner → propose.
   - NOISE: TUI, UI, unrelated → drop silently.
4. Propose: unified diff against the instruction files, ≤1 line reason per hunk, telegram style, no prose. Nothing written yet.
5. Gate: user approves per hunk. Unattended run → stop here, notify "CLIs updated: <versions>; <N> doc changes proposed — open session to approve".
6. Apply approved hunks only. Commit. Sync installed copy. Notice: versions before→after, doc lines changed, ≤5 bullets worth knowing.
