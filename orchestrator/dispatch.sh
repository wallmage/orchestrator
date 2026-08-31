#!/bin/sh
# Fleet dispatch: ONE Monitor call launches 1..N CLI workers AND watches them all.
# No separate watcher step exists — launching and watching are the same action.
#
#   Monitor(persistent:true, description:"<fleet>", command:
#     "TMP=<state dir> JOBS='<name>|<workdir>|<full CLI command>
#      <name>|<workdir>|<full CLI command>' sh ~/.claude/skills/orchestrator/dispatch.sh")
#
# JOBS: one job per line, fields split on the FIRST TWO '|' only — the command may
#       itself contain '|'; name and workdir must not. Blank lines ignored.
# Single-job shorthand: CLI='<cmd>' WD=<workdir> JOB=<name> (compiled into JOBS).
# TMP: state dir for <name>.log/.pid/.final.txt (default: parent of each job's workdir).
# watcher.sh tunables (POLL_SECS, HEARTBEAT_SECS, ...) pass through to every watcher.
# Each job gets its own watcher.sh child; all events merge into this Monitor's stream
# (every line is [name]-tagged). Exits when the last watcher exits.

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "${JOBS:-}" ] && [ -n "${CLI:-}" ]; then
  JOBS="${JOB:-job}|${WD:-}|$CLI"
fi
if [ -z "${JOBS:-}" ]; then
  echo "LAUNCH FAILURE [dispatch]: set JOBS='name|workdir|command' (one per line) or CLI/WD/JOB"
  exit 0
fi

OLDIFS=$IFS; IFS='
'
for line in $JOBS; do
  IFS=$OLDIFS
  [ -n "$line" ] || continue
  name=${line%%|*}; rest=${line#*|}; wd=${rest%%|*}; cmd=${rest#*|}
  if [ -z "$name" ] || [ ! -d "$wd" ] || [ -z "$cmd" ]; then
    echo "LAUNCH FAILURE [$name]: bad job line or missing workdir ($wd)"
    continue
  fi
  state=${TMP:-$(dirname "$wd")}
  log="$state/$name.log"; pidf="$state/$name.pid"; outf="$state/$name.final.txt"
  ( cd "$wd" || exit 127; exec </dev/null; sh -c "$cmd" > "$log" 2>&1; printf '\nEXIT=%s\n' $? >> "$log" ) &
  echo $! > "$pidf"
  echo "LAUNCHED [$name]: pid $(cat "$pidf"), log $log"
  LOG=$log PIDFILE=$pidf OUTFILE=$outf JOB=$name sh "$DIR/watcher.sh" &
  IFS='
'
done
IFS=$OLDIFS
wait
echo "FLEET DONE: all watchers closed"
