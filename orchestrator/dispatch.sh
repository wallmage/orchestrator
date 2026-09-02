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
# QUIET (default 1): per-job ARMED OK / REMOTE-THINKING / RIGHT-WORK CHECK never wake; each job's FINISHED still does;
#   one WORK CHECK [fleet] at WORK_SECS (180); ONE HEARTBEAT [fleet] per 900s covering every job; FLEET DONE lists exit + final size per job.
# BATCH=1 (debate rounds only): clean per-job FINISHED muted too — only FLEET DONE speaks.
#   Liveness without wakes: watcher dies early → FLEET ABORTED; job ends but watcher hangs → WATCHER STUCK.
#   QUIET=0 restores per-job chatter and a 300s heartbeat.
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
QUIET=${QUIET:-1}; export QUIET
BATCH=${BATCH:-0}; export BATCH
HB=${HEARTBEAT_SECS:-$([ "$QUIET" = 1 ] && echo 900 || echo 300)}
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
NAMES=${NAMES# }; LOGS=${LOGS# }; WPIDS=${WPIDS# }
[ -n "$WPIDS" ] || { echo "LAUNCH FAILURE [dispatch]: no job started"; exit 0; }

# One heartbeat subshell: first pass at WORK_SECS (3 min) = proof of work; then every HB.
# Each pass also catches a watcher that outlived its finished job.
(
  n=0
  while :; do
    if [ "$n" = 0 ]; then sleep "${WORK_SECS:-180}"; else sleep "$HB"; fi
    n=$((n+1)); line=""; work=""; i=0
    for log in $LOGS; do
      i=$((i+1)); name=$(echo "$NAMES" | cut -d' ' -f$i); wp=$(echo "$WPIDS" | cut -d' ' -f$i)
      if tail -c 64 "$log" 2>/dev/null | grep -qE '^EXIT=[0-9]+'; then
        st="done(exit=$(tail -c 64 "$log" | grep -aE '^EXIT=' | tail -1 | cut -d= -f2))"
        kill -0 "$wp" 2>/dev/null && echo "WATCHER STUCK [$name]: job wrote EXIT but its watcher never reported — read $log tail, kill watcher pid $wp"
      elif [ -f "$log" ]; then
        st="alive, $(wc -c < "$log" | tr -d ' ')B"
      else
        st="no log"
      fi
      line="$line$name: $st | "; work="$work$name: $(tail -1 "$log" 2>/dev/null | cut -c1-120) | "
    done
    if [ "$n" = 1 ] && [ "$QUIET" = 1 ]; then echo "WORK CHECK [fleet]: ${work%??}"; else echo "HEARTBEAT [fleet]: ${line%??}"; fi
  done
) &
HBPID=$!

for p in $WPIDS; do wait "$p"; done
pkill -P "$HBPID" 2>/dev/null; kill "$HBPID" 2>/dev/null
line=""; abort=""; set -- $NAMES
for log in $LOGS; do name=$1; shift; f=$([ -f "${log%.log}.final.txt" ] && wc -c < "${log%.log}.final.txt" | tr -d ' '); ex=$(grep -aE '^EXIT=' "$log" | tail -1 | cut -d= -f2); [ -n "$ex" ] || abort="$abort $name"; line="$line$name exit=${ex:-NONE} final=${f:-0}B | "; done
if [ -n "$abort" ]; then echo "FLEET ABORTED (watcher died before job ended:$abort): ${line%??}"; else echo "FLEET DONE: ${line%??}"; fi
