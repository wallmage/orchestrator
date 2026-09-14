#!/bin/sh
# Fleet dispatch: ONE Monitor call launches 1..N CLI jobs AND watches them all.
# JOBS: one job per line, split on the FIRST TWO '|' only (command may contain '|'; name/workdir may not). Blank lines ignored.
# Single-job shorthand: CLI='<cmd>' WD=<workdir> JOB=<name>.
# TMP: state dir for <name>.log/.pid/.final.txt (default: parent of each job's workdir).
# QUIET (default 1), BATCH, WORK_SECS (180), HEARTBEAT_SECS (900; 300 when QUIET=0): wake semantics in SKILL.md § Fleet Dispatch & Watcher Protocol.

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
  pid=$!; echo "$pid" > "$pidf"
  echo "LAUNCHED [$name]: pid $pid, log $log"
  # Children: incidents immediate, routine status muted (parent heartbeat covers it).
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
