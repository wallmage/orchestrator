#!/bin/sh
# CANONICAL WATCHER — P5 Watchtower Protocol, implemented to the letter. NEVER write
# a watcher from memory: instantiate THIS file via Monitor with env vars. Improvements
# are edited INTO this file (same-turn skill sync) so no lesson can be dropped.
#
# Required env: LOG (absolute path to job log)
# Optional env: JOB (job id), MILESTONE_FILE + MILESTONE_MSG (launch-enabler),
#               POLL_SECS (60), HEARTBEAT_SECS (300), CPU_PATTERN (pgrep -f pattern,
#               default "codex"), CPU_IDLE_MAX (max cputime-seconds per poll that still
#               counts as idle, default 2), DEDUP_SECS (480)
#
# P5 clause → mechanism map (the arming checklist, mechanical):
# armed-OK    first event within 60s proves the LOG PATH IS REAL (script-bug killer).
# DEATH       log never appears by poll 2, or vanishes after being seen → immediate.
# ERROR       failure signature that is STILL UNRESOLVED ONE POLL LATER (still in the
#             log tail, or new failures accumulated). Self-healed errors are noise.
# STALL       2 zero-growth polls THEN idle CPU over the next poll (busy CPU with a
#             quiet log is legitimate LOCAL work, not a stall). Sockets disambiguate
#             the idle-CPU case: open connection = REMOTE-THINKING (model reasoning
#             in the data center, no local footprint — alive, long suppression);
#             zero sockets = true STALL (nothing local, nothing remote). Diagnosis
#             pre-packaged: cputime delta / open sockets / last line. Dedup ≤1 per
#             DEDUP_SECS (STALL) / REMOTE_DEDUP_SECS (REMOTE-THINKING).
# WAITING     waiting-for-input signature → immediate.
# FINISH      "Final output" — but finish is NOT success: final chunk scanned for
#             refusal/block signatures → FINISHED-SUSPECT if any match.
# MILESTONE   named file appears → fires once (downstream work can start NOW).
# RIGHT-WORK  one wake at ~3 min with the last log line so the orchestrator verifies
#             the job is doing the RIGHT work, not just work.
# HEARTBEAT   every HEARTBEAT_SECS with byte count — watcher proof-of-life. A missing
#             heartbeat means the watcher is dead: rebuild NOW. (User pulse rides
#             every second heartbeat — orchestrator side.)

JOB=${JOB:-job}
POLL=${POLL_SECS:-60}
HB=${HEARTBEAT_SECS:-300}
CPU_PATTERN=${CPU_PATTERN:-codex}
CPU_IDLE_MAX=${CPU_IDLE_MAX:-2}
DEDUP=${DEDUP_SECS:-480}
REMOTE_DEDUP=${REMOTE_DEDUP_SECS:-1800}

FAIL_SIGS='usage limit|quota|rate limit|Task failed|Cancelled|Blocked by workspace|只允许写入|权限阻止|沙箱拒绝|未修改任何文件'
WAIT_SIGS='waiting for (your )?input|requires approval|permission prompt|等待输入'

PIDS=""
cpu_secs() {
  PIDS=$(pgrep -f "$CPU_PATTERN" 2>/dev/null | head -20 | tr '\n' ',' | sed 's/,$//')
  if [ -z "$PIDS" ]; then echo "-1"; return; fi
  ps -o cputime= -p "$PIDS" 2>/dev/null | awk '{
    t=$1; d=0
    if (t ~ /-/) { split(t, dd, "-"); d=dd[1]; t=dd[2] }
    n=split(t, a, ":"); s=0
    if (n==3) s=a[1]*3600+a[2]*60+a[3]
    else if (n==2) s=a[1]*60+a[2]
    total += d*86400 + s
  } END { printf "%d", total }'
}

seen_log=0
missing_polls=0
prev_size=-1
zero_polls=0
stall_cpu_ref=-1
last_stall_wake=0
err_pend=0
ms_done=0
rw_done=0
armed_ts=0
last_hb=0

while true; do
  now=$(date +%s)

  if [ ! -f "$LOG" ]; then
    if [ "$seen_log" = "1" ]; then
      echo "DEATH [$JOB]: log vanished at $LOG"
      exit 0
    fi
    missing_polls=$((missing_polls+1))
    if [ "$missing_polls" -ge 2 ]; then
      echo "LAUNCH FAILURE [$JOB]: log never appeared at $LOG — wrong state dir or dead launch. Fix NOW."
      exit 0
    fi
  else
    if [ "$seen_log" = "0" ]; then
      seen_log=1
      armed_ts=$now
      last_hb=$now
      echo "ARMED OK [$JOB]: log exists, $(wc -c < "$LOG" | tr -d ' ') bytes"
    fi

    # ERROR — wake only if still unresolved one poll later
    if grep -qE "$FAIL_SIGS" "$LOG" 2>/dev/null; then
      if [ "$err_pend" = "1" ]; then
        if tail -c 4000 "$LOG" | grep -qE "$FAIL_SIGS"; then
          echo "ERROR [$JOB] (unresolved one poll later): $(grep -E "$FAIL_SIGS" "$LOG" | tail -1 | cut -c1-300)"
          exit 0
        fi
        err_pend=0   # scrolled out of the tail: worker self-healed, noise
      else
        err_pend=1   # first sighting: note it, wake only if it survives a poll
      fi
    else
      err_pend=0
    fi

    W=$(grep -E "$WAIT_SIGS" "$LOG" 2>/dev/null | tail -1)
    if [ -n "$W" ]; then
      echo "WAITING FOR INPUT [$JOB]: $(printf '%s' "$W" | cut -c1-300)"
      exit 0
    fi

    if grep -q "Final output" "$LOG" 2>/dev/null; then
      TAILTXT=$(tail -c 1200 "$LOG" | tr '\n' ' ')
      if printf '%s' "$TAILTXT" | grep -qE "$FAIL_SIGS"; then
        echo "FINISHED-SUSPECT [$JOB]: final message carries a failure signature: ...$(printf '%s' "$TAILTXT" | tail -c 600)"
      else
        echo "FINISHED [$JOB]: ...$(printf '%s' "$TAILTXT" | tail -c 700)"
      fi
      exit 0
    fi

    if [ "$ms_done" = "0" ] && [ -n "${MILESTONE_FILE:-}" ] && [ -f "$MILESTONE_FILE" ]; then
      echo "MILESTONE [$JOB]: ${MILESTONE_MSG:-$MILESTONE_FILE exists}"
      ms_done=1
    fi

    if [ "$rw_done" = "0" ] && [ $((now - armed_ts)) -ge 180 ]; then
      echo "RIGHT-WORK CHECK [$JOB]: 3 min in — last: $(tail -1 "$LOG" | cut -c1-200)"
      rw_done=1
    fi

    # STALL — 2 zero-growth polls, then idle CPU over the next poll confirms it
    size=$(stat -f %z "$LOG" 2>/dev/null || stat -c %s "$LOG" 2>/dev/null || echo 0)
    if [ "$size" = "$prev_size" ]; then
      zero_polls=$((zero_polls+1))
      if [ "$zero_polls" -ge 2 ]; then
        cpu_now=$(cpu_secs)
        if [ "$cpu_now" = "-1" ]; then
          if [ $((now - last_stall_wake)) -ge "$DEDUP" ]; then
            echo "STALL [$JOB]: log frozen $((zero_polls*POLL))s at $size bytes and NO process matches '$CPU_PATTERN' — likely dead. Last: $(tail -1 "$LOG" | cut -c1-200)"
            last_stall_wake=$now
          fi
        elif [ "$stall_cpu_ref" = "-1" ]; then
          stall_cpu_ref=$cpu_now   # start CPU observation window
        else
          delta=$((cpu_now - stall_cpu_ref))
          stall_cpu_ref=$cpu_now
          if [ "$delta" -le "$CPU_IDLE_MAX" ]; then
            socks=$(lsof -i -a -p "$PIDS" 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
            if [ "$socks" -gt 0 ]; then
              # Idle local CPU + live connection = the model is reasoning in the
              # data center (no local footprint). Alive, not stalled — long
              # suppression so an hour of thinking doesn't spam wakes.
              if [ $((now - last_stall_wake)) -ge "$REMOTE_DEDUP" ]; then
                echo "REMOTE-THINKING [$JOB]: log frozen $((zero_polls*POLL))s, local CPU idle, $socks open sockets to the model service — waiting on data-center reasoning. Last: $(tail -1 "$LOG" | cut -c1-200)"
                last_stall_wake=$now
              fi
            elif [ $((now - last_stall_wake)) -ge "$DEDUP" ]; then
              # Idle CPU AND no connection: nothing local, nothing remote — stalled.
              echo "STALL [$JOB]: log frozen $((zero_polls*POLL))s at $size bytes, cputime +${delta}s/poll (idle), 0 open sockets. Last: $(tail -1 "$LOG" | cut -c1-200)"
              last_stall_wake=$now
            fi
          fi
        fi
      fi
    else
      zero_polls=0
      stall_cpu_ref=-1
    fi
    prev_size=$size

    if [ $((now - last_hb)) -ge "$HB" ]; then
      echo "HEARTBEAT [$JOB]: alive, $size bytes"
      last_hb=$now
    fi
  fi

  sleep "$POLL"
done
