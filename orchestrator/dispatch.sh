#!/bin/sh
# One-call CLI dispatch: launches the worker AND becomes its watcher.
# Instantiate via a single Monitor call — no separate Bash launch, nothing to forget:
#   Monitor(persistent:true, description:"<job>", command:
#     "CLI='<full CLI command with prompt>' WD=<workdir> JOB=<job> TMP=<state dir> \
#      sh ~/.claude/skills/orchestrator/dispatch.sh")
# Env: CLI (required, full command; run with cwd=WD), WD (required, must exist),
#      JOB (label), TMP (state dir for log/pid/final; default WD's parent)
# Everything watcher.sh accepts passes through (POLL_SECS, HEARTBEAT_SECS, ...).
# The first emitted event is the launch receipt; then watcher semantics take over.

JOB=${JOB:-job}
if [ -z "${CLI:-}" ] || [ -z "${WD:-}" ] || [ ! -d "${WD:-}" ]; then
  echo "LAUNCH FAILURE [$JOB]: CLI and an existing WD are required (WD=${WD:-unset})"
  exit 0
fi
TMP=${TMP:-$(dirname "$WD")}
LOG=${LOG:-$TMP/$JOB.log}
PIDFILE=${PIDFILE:-$TMP/$JOB.pid}
OUTFILE=${OUTFILE:-$TMP/$JOB.final.txt}
export LOG PIDFILE OUTFILE JOB

( cd "$WD" || exit 127; exec </dev/null; sh -c "$CLI" > "$LOG" 2>&1; printf '\nEXIT=%s\n' $? >> "$LOG" ) &
echo $! > "$PIDFILE"
echo "LAUNCHED [$JOB]: pid $(cat "$PIDFILE"), log $LOG"
exec sh "$(dirname "$0")/watcher.sh"
