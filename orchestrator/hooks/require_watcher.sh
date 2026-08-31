#!/bin/sh
# PreToolUse hook (Bash matcher): block CLI worker launches that don't attest a watcher.
# A dispatch must be prefixed WATCHED=1 — the convention is: arm watcher.sh via Monitor
# in the SAME message batch, and prefix the launch command with WATCHED=1.
# Non-CLI commands pass through untouched.
IN=$(cat)
CMD=$(printf '%s' "$IN" | /usr/bin/python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)
case "$CMD" in
  *WATCHED=1*) exit 0 ;;
esac
if printf '%s' "$CMD" | grep -qE 'cursor-agent .*-p|codebuddy -p|codex exec|xg_retry\.sh|launch_cli'; then
  echo "BLOCKED by orchestrator watcher rule: CLI worker launches require a watcher. Re-issue this Bash call prefixed with WATCHED=1 and, in the SAME message batch, arm the watcher: Monitor(persistent:true, command:\"LOG=<log> JOB=<job> PIDFILE=<pid> OUTFILE=<final> sh ~/.claude/skills/orchestrator/watcher.sh\")." >&2
  exit 2
fi
exit 0
