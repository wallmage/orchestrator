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
# QUIET=1: per-job ARMED OK / REMOTE-THINKING / RIGHT-WORK CHECK / clean FINISHED muted;
#          one WORK CHECK [fleet] at 3 min; FLEET DONE lists exit + final size per job.
#          Use when nothing can happen until every job lands (debate rounds, N-version, batch verify).
#
# Wake economics (the whole point):
# - Incidents (DEATH, dead-process STALL, ERROR, LAUNCH FAILURE, WAITING, RESOURCE)
#   and terminal FINISHED events pass through IMMEDIATELY from per-job watchers.
# - Routine status is consolidated: per-job heartbeats are silenced (fleet mode) and
#   the parent emits ONE combined heartbeat per HEARTBEAT_SECS (default 300) listing
#   every job's state. One wake per interval regardless of fleet size.
# - When the last job settles its watcher exits; the parent then kills the heartbeat
#   loop and exits itself. No watcher ever outlives the fleet.

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HB=${HEARTBEAT_SECS:-300}
if [ -z "${JOBS:-}" ] && [ -n "${CLI:-}" ]; then
  JOBS="${JOB:-job}|${WD:-}|$CLI"
fi
if [ -z "${JOBS:-}" ]; then
  echo "LAUNCH FAILURE [dispatch]: set JOBS='name|workdir|command' (one per line) or CLI/WD/JOB"
  exit 0
fi

NAMES=""; LOGS=""; WPIDS=""
OLDIFS=$IFS; IFS='
'
for line in $JOBS; do
  IFS=$OLDIFS
  [ -n "$line" ] || continue
  name=${line%%|*}; rest=${line#*|}; wd=${rest%%|*}; cmd=${rest#*|}
  if [ -z "$name" ] || [ ! -d "$wd" ] || [ -z "$cmd" ]; then
    echo "LAUNCH FAILURE [$name]: bad job line or missing workdir ($wd)"
    IFS='
'
    continue
  fi
  state=${TMP:-$(dirname "$wd")}
  log="$state/$name.log"; pidf="$state/$name.pid"; outf="$state/$name.final.txt"
  ( cd "$wd" || exit 127; exec </dev/null; sh -c "$cmd" > "$log" 2>&1; printf '\nEXIT=%s\n' $? >> "$log" ) &
  echo $! > "$pidf"
  echo "LAUNCHED [$name]: pid $(cat "$pidf"), log $log"
  # Children: incidents immediate, routine status muted — the parent consolidates it.
  LOG=$log PIDFILE=$pidf OUTFILE=$outf JOB=$name HEARTBEAT_SECS=99999999 sh "$DIR/watcher.sh" &
  WPIDS="$WPIDS $!"
  NAMES="$NAMES $name"
  LOGS="$LOGS $log"
  IFS='
'
done
IFS=$OLDIFS
[ -n "$WPIDS" ] || { echo "LAUNCH FAILURE [dispatch]: no job started"; exit 0; }

# One combined heartbeat per HB covering every job.
(
  if [ "${QUIET:-0}" = 1 ]; then
    sleep 180; line=""; set -- $NAMES
    for log in $LOGS; do name=$1; shift; line="$line$name: $(tail -1 "$log" 2>/dev/null | cut -c1-120) | "; done
    echo "WORK CHECK [fleet]: ${line%??}"
  fi
  while :; do
    sleep "$HB"
    line=""
    set -- $NAMES
    for log in $LOGS; do
      name=$1; shift
      if tail -c 64 "$log" 2>/dev/null | grep -qE '^EXIT=[0-9]+'; then
        st="done(exit=$(tail -c 64 "$log" | grep -aE '^EXIT=' | tail -1 | cut -d= -f2))"
      elif [ -f "$log" ]; then
        st="alive, $(wc -c < "$log" | tr -d ' ')B"
      else
        st="no log"
      fi
      line="$line$name: $st | "
    done
    echo "HEARTBEAT [fleet]: ${line%??}"
  done
) &
HBPID=$!

for p in $WPIDS; do wait "$p"; done
kill "$HBPID" 2>/dev/null
line=""; set -- $NAMES
for log in $LOGS; do name=$1; shift; f=$(wc -c < "${log%.log}.final.txt" 2>/dev/null | tr -d ' '); line="$line$name exit=$(grep -aE '^EXIT=' "$log" | tail -1 | cut -d= -f2) final=${f:-0}B | "; done
echo "FLEET DONE: ${line%??}"
