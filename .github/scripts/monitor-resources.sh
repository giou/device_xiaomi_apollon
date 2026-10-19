#!/usr/bin/env bash
# Background resource sampler for CI builds. Writes CSV samples and echoes the
# same lines to stdout (the job log survives a lost runner). SIGTERM to stop.
# Usage: monitor-resources.sh <csv-path>
set -u
out="${1:?usage: $0 <csv>}"
[ -f "$out" ] || echo 'ts,mem_used_mb,swap_used_mb,soong_rss_kb,soong_swap_kb,psi_mem_avg10,psi_io_avg10,pswpout' > "$out"
env_shown=0
while :; do
  ts=$(date -u +%FT%TZ)
  mem=$(free -m 2>/dev/null | awk '/^Mem:/{print $3}')
  swap=$(free -m 2>/dev/null | awk '/^Swap:/{print $3}')
  pid=$(pgrep -x soong_build 2>/dev/null | head -1)
  rss=0
  vsw=0
  if [ -n "${pid:-}" ]; then
    rss=$(awk '/VmRSS/{print $2}' "/proc/$pid/status" 2>/dev/null)
    vsw=$(awk '/VmSwap/{print $2}' "/proc/$pid/status" 2>/dev/null)
    if [ "$env_shown" = 0 ]; then
      tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -E '^(GOGC|GOMEMLIMIT|GODEBUG)=' | sed 's/^/soong-env: /'
      env_shown=1
    fi
  fi
  pm=$(awk '/^some/{print $2}' /proc/pressure/memory 2>/dev/null | cut -d= -f2)
  pi=$(awk '/^some/{print $2}' /proc/pressure/io 2>/dev/null | cut -d= -f2)
  po=$(awk '/^pswpout/{print $2}' /proc/vmstat 2>/dev/null)
  printf '%s,%s,%s,%s,%s,%s,%s,%s\n' "$ts" "${mem:-}" "${swap:-}" "${rss:-0}" "${vsw:-0}" "${pm:-}" "${pi:-}" "${po:-}" | tee -a "$out"
  sleep 30
done
