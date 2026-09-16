#!/bin/sh
# Fleet dispatch: ONE Monitor call launches 1..N CLI jobs AND watches them all.
# Monitor expires <=30 min, kills its process group → fleet runs detached (FLEET=1 re-exec, own pgid, parent init),
# events → $TMP/fleet.events; foreground relays the file. Re-arm/adopt: RELAY=1 TMP=<dir> sh dispatch.sh (cursor $TMP/fleet.cursor).
# JOBS: one job per line, split on the FIRST TWO '|' only (command may contain '|'; name/workdir may not). Blank lines ignored.
# Single-job shorthand: CLI='<cmd>' WD=<workdir> JOB=<name>.
# TMP (required): state dir for <name>.log/.pid/.final.txt and fleet.events/.cursor/.pid/.wpids/.err.
# QUIET (default 1), BATCH, WORK_SECS (180), HEARTBEAT_SECS (900; 300 when QUIET=0): wake semantics in SKILL.md § Fleet Dispatch & Watcher Protocol.

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -n "${TMP:-}" ] || { echo "LAUNCH FAILURE [dispatch]: TMP unset"; exit 0; }
EV=$TMP/fleet.events; CUR=$TMP/fleet.cursor; FPID=$TMP/fleet.pid

if [ "${FLEET:-0}" != 1 ]; then
  if [ "${RELAY:-0}" = 1 ]; then
    [ -f "$FPID" ] || { echo "LAUNCH FAILURE [dispatch]: no fleet in $TMP (fleet.pid missing)"; exit 0; }
  else
    if [ -z "${JOBS:-}" ] && [ -n "${CLI:-}" ]; then JOBS="${JOB:-job}|${WD:-}|$CLI"; fi
    if [ -z "${JOBS:-}" ]; then echo "LAUNCH FAILURE [dispatch]: set JOBS='name|workdir|command' (one per line) or CLI/WD/JOB"; exit 0; fi
    if kill -0 "$(cat "$FPID" 2>/dev/null)" 2>/dev/null; then echo "LAUNCH FAILURE [dispatch]: fleet already running in $TMP (pid $(cat "$FPID")) — relay it with RELAY=1, or use a new TMP"; exit 0; fi
    mkdir -p "$TMP"; rm -f "$CUR"; : > "$EV"
    ( set -m; FLEET=1 JOBS=$JOBS sh "$0" >> "$EV" 2>> "$TMP/fleet.err" & echo $! > "$FPID" )
  fi
  s=$(cat "$CUR" 2>/dev/null || echo 0)
  relay() { n=$(wc -l < "$EV" 2>/dev/null | tr -d ' '); n=${n:-0}
            if [ "$n" -gt "$s" ]; then sed -n "$((s+1)),${n}p" "$EV"; s=$n; echo "$s" > "$CUR"; fi; }
  done_relayed() { [ "$s" -gt 0 ] && sed -n "${s}p" "$EV" | grep -qE '^FLEET (DONE|ABORTED)'; }
  while :; do
    relay; done_relayed && exit 0
    if ! kill -0 "$(cat "$FPID" 2>/dev/null)" 2>/dev/null; then
      relay; done_relayed && exit 0
      echo "FLEET DEAD [dispatch]: fleet gone before FLEET DONE — see $TMP/fleet.err; bare watcher.sh per unfinished job"; exit 0
    fi
    sleep 1
  done
fi

# ---- FLEET=1: detached fleet runner; stdout = $EV ----
QUIET=${QUIET:-1}; export QUIET
BATCH=${BATCH:-0}; export BATCH
HB=${HEARTBEAT_SECS:-$([ "$QUIET" = 1 ] && echo 900 || echo 300)}

NAMES=""; LOGS=""; WPIDS=""
OLDIFS=$IFS; IFS='
'
set -f; for line in $JOBS; do
  IFS=$OLDIFS
  [ -n "$line" ] || continue
  name=${line%%|*}; rest=${line#*|}; wd=${rest%%|*}; cmd=${rest#*|}
  if [ -z "$name" ] || [ ! -d "$wd" ] || [ -z "$cmd" ]; then
    echo "LAUNCH FAILURE [$name]: bad job line or missing workdir ($wd)"
    IFS='
'
    continue
  fi
  log="$TMP/$name.log"; pidf="$TMP/$name.pid"; outf="$TMP/$name.final.txt"
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
IFS=$OLDIFS; set +f
NAMES=${NAMES# }; LOGS=${LOGS# }; WPIDS=${WPIDS# }; echo "$WPIDS" > "$TMP/fleet.wpids"
[ -n "$WPIDS" ] || { echo "FLEET ABORTED: no job started"; exit 0; }

# One heartbeat subshell: first pass at WORK_SECS (3 min) = proof of work; then every HB.
# Each pass also catches a watcher that outlived its finished job.
(
  n=0
  while :; do
    if [ "$n" = 0 ]; then sleep "${WORK_SECS:-180}"; else sleep "$HB"; fi
    n=$((n+1)); line=""; work=""; i=0
    for log in $LOGS; do
      i=$((i+1)); name=$(echo "$NAMES" | cut -d' ' -f$i); wp=$(cut -d' ' -f$i "$TMP/fleet.wpids")
      if tail -c 64 "$log" 2>/dev/null | grep -qE '^EXIT=[0-9]+'; then
        st="done(exit=$(tail -c 64 "$log" | grep -aE '^EXIT=' | tail -1 | cut -d= -f2))"
        kill -0 "$wp" 2>/dev/null && sleep 5 && kill -0 "$wp" 2>/dev/null && echo "WATCHER STUCK [$name]: job wrote EXIT but its watcher never reported — read $log tail, kill watcher pid $wp"
      elif [ -f "$log" ]; then
        st="alive, $(wc -c < "$log" | tr -d ' ')B"
      else
        st="no log"
      fi
      line="$line$name: $st | "; work="$work$name: $(tail -1 "$log" 2>/dev/null | cut -c1-120) | "
    done
    if [ "$n" = 1 ]; then echo "WORK CHECK [fleet]: ${work%??}"; else echo "HEARTBEAT [fleet]: ${line%??}"; fi
  done
) &
HBPID=$!

# Fleet lives while any job lives (no EXIT=, wrapper pid alive); dead watcher mid-job respawned once.
RESPAWNED=""
while :; do
  i=0; new=""; live=0
  for wp in $WPIDS; do
    i=$((i+1)); name=$(echo "$NAMES" | cut -d' ' -f$i); log=$(echo "$LOGS" | cut -d' ' -f$i); pidf=${log%.log}.pid
    if ! tail -c 64 "$log" 2>/dev/null | grep -qE '^EXIT=[0-9]+' && kill -0 "$(cat "$pidf" 2>/dev/null)" 2>/dev/null; then
      live=$((live+1))
      if ! kill -0 "$wp" 2>/dev/null && ! echo " $RESPAWNED " | grep -q " $name "; then
        RESPAWNED="$RESPAWNED $name"
        LOG=$log PIDFILE=$pidf OUTFILE=${log%.log}.final.txt JOB=$name HEARTBEAT_SECS=99999999 sh "$DIR/watcher.sh" &
        wp=$!; [ "$QUIET" = 1 ] || echo "WATCHER RESPAWNED [$name]: watcher died mid-job, new pid $wp"
      fi
    fi
    new="$new $wp"
  done
  WPIDS=${new# }; echo "$WPIDS" > "$TMP/fleet.wpids"
  [ "$live" -gt 0 ] || break
  sleep 3
done
for p in $WPIDS; do wait "$p"; done
pkill -P "$HBPID" 2>/dev/null; kill "$HBPID" 2>/dev/null
line=""; abort=""; set -- $NAMES
for log in $LOGS; do name=$1; shift; f=$([ -f "${log%.log}.final.txt" ] && wc -c < "${log%.log}.final.txt" | tr -d ' '); ex=$(grep -aE '^EXIT=' "$log" | tail -1 | cut -d= -f2); [ -n "$ex" ] || abort="$abort $name"; line="$line$name exit=${ex:-NONE} final=${f:-0}B | "; done
if [ -n "$abort" ]; then echo "FLEET ABORTED (watcher died before job ended:$abort): ${line%??}"; else echo "FLEET DONE: ${line%??}"; fi
