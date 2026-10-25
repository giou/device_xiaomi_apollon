#!/usr/bin/env bash
# Background resource sampler for CI builds. Writes CSV samples and echoes the
# same lines to stdout (the job log survives a lost runner). SIGTERM to stop.
# Usage: monitor-resources.sh <csv-path>
#
# mem_used_mb is free(1)'s "used" column: it excludes page cache and
# reclaimable slab, so it is not total RAM in use. mem_avail_mb, cached_mb and
# anon_mb show the rest of the picture.
set -u
out="${1:?usage: $0 <csv>}"
[ -f "$out" ] || echo 'ts,mem_total_mb,mem_used_mb,mem_free_mb,mem_avail_mb,cached_mb,anon_mb,slab_mb,swap_total_mb,swap_used_mb,soong_rss_kb,soong_swap_kb,psi_mem_some,psi_mem_full,psi_io_some,psi_io_full,psi_cpu_some,load1,procs_running,procs_blocked,pswpin,pswpout,pgscan_direct,pgsteal_direct,allocstall,pgmajfault,workingset_refault_anon,workingset_refault_file,dirty_mb,writeback_mb,zswap_pool_mb,zswap_stored_mb,zswap_written_back_mb,zswap_pool_limit_hit,top_rss_kb,top_comm' > "$out"

meminfo_mb() {
  awk -v k="$1:" '$1 == k { print int($2 / 1024); found = 1 } END { if (!found) print 0 }' /proc/meminfo
}

vmstat_counter() {
  awk -v k="$1" '$1 == k { print $2; found = 1 } END { if (!found) print 0 }' /proc/vmstat
}

env_shown=0
while :; do
  ts=$(date -u +%FT%TZ)
  read -r mem_total mem_used swap_total swap_used <<< "$(free -m 2>/dev/null | awk '/^Mem:/{a=$2;b=$3} /^Swap:/{c=$2;d=$3} END{print a+0,b+0,c+0,d+0}')"
  mem_free=$(meminfo_mb MemFree)
  mem_avail=$(meminfo_mb MemAvailable)
  cached=$(meminfo_mb Cached)
  anon=$(meminfo_mb AnonPages)
  slab=$(meminfo_mb Slab)
  dirty=$(meminfo_mb Dirty)
  writeback=$(meminfo_mb Writeback)

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

  pm_some=$(awk '/^some/{print $2}' /proc/pressure/memory 2>/dev/null | cut -d= -f2)
  pm_full=$(awk '/^full/{print $2}' /proc/pressure/memory 2>/dev/null | cut -d= -f2)
  pi_some=$(awk '/^some/{print $2}' /proc/pressure/io 2>/dev/null | cut -d= -f2)
  pi_full=$(awk '/^full/{print $2}' /proc/pressure/io 2>/dev/null | cut -d= -f2)
  pc_some=$(awk '/^some/{print $2}' /proc/pressure/cpu 2>/dev/null | cut -d= -f2)

  load1=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null)
  runq=$(awk '/^procs_running/{print $2}' /proc/stat 2>/dev/null)
  blockq=$(awk '/^procs_blocked/{print $2}' /proc/stat 2>/dev/null)

  pswpin=$(vmstat_counter pswpin)
  pswpout=$(vmstat_counter pswpout)
  pgscan_direct=$(vmstat_counter pgscan_direct)
  pgsteal_direct=$(vmstat_counter pgsteal_direct)
  allocstall=$(vmstat_counter allocstall)
  pgmajfault=$(vmstat_counter pgmajfault)
  ws_anon=$(vmstat_counter workingset_refault_anon)
  ws_file=$(vmstat_counter workingset_refault_file)

  zpool=0
  zstored=0
  zwritten=0
  zlimit=0
  if [ -d /sys/kernel/debug/zswap ]; then
    zpool=$(( $(sudo cat /sys/kernel/debug/zswap/pool_total_size 2>/dev/null || echo 0) / 1048576 ))
    zstored=$(( $(sudo cat /sys/kernel/debug/zswap/stored_pages 2>/dev/null || echo 0) * 4096 / 1048576 ))
    zwritten=$(( $(sudo cat /sys/kernel/debug/zswap/written_back_pages 2>/dev/null || echo 0) * 4096 / 1048576 ))
    zlimit=$(sudo cat /sys/kernel/debug/zswap/pool_limit_hit 2>/dev/null || echo 0)
  fi

  read -r top_rss top_comm <<< "$(ps -eo rss=,comm= --sort=-rss 2>/dev/null | head -1)"
  top_comm=${top_comm//,/ }

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$ts" "$mem_total" "$mem_used" "$mem_free" "$mem_avail" "$cached" "$anon" "$slab" \
    "$swap_total" "$swap_used" "$rss" "$vsw" \
    "${pm_some:-0}" "${pm_full:-0}" "${pi_some:-0}" "${pi_full:-0}" "${pc_some:-0}" \
    "${load1:-0}" "${runq:-0}" "${blockq:-0}" \
    "$pswpin" "$pswpout" "$pgscan_direct" "$pgsteal_direct" "$allocstall" "$pgmajfault" \
    "$ws_anon" "$ws_file" "$dirty" "$writeback" \
    "$zpool" "$zstored" "$zwritten" "$zlimit" "${top_rss:-0}" "${top_comm:-unknown}" \
    | tee -a "$out"

  sleep 30
done
