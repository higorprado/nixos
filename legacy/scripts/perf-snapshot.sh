#!/usr/bin/env bash
set -euo pipefail

out_dir="./.migration-audit"
wait_idle_sec=20
idle_threshold="0.50"
poll_sec=2

while [ "$#" -gt 0 ]; do
  case "$1" in
    --wait-idle-sec)
      wait_idle_sec="${2:-20}"
      shift 2
      ;;
    --idle-threshold)
      idle_threshold="${2:-0.50}"
      shift 2
      ;;
    --poll-sec)
      poll_sec="${2:-2}"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Usage:
  scripts/perf-snapshot.sh [out_dir] [--wait-idle-sec N] [--idle-threshold F] [--poll-sec N]
EOF
      exit 0
      ;;
    *)
      out_dir="$1"
      shift
      ;;
  esac
done

mkdir -p "$out_dir"

ts="$(date +%Y%m%d-%H%M%S)"
out_file="$out_dir/perf-$ts.txt"

cmd_exists() { command -v "$1" >/dev/null 2>&1; }
current_load1() { awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0"; }
idle_gate_result="disabled"
idle_gate_load1="N/A"

if [ "$wait_idle_sec" -gt 0 ] 2>/dev/null; then
  start_ts="$(date +%s)"
  idle_gate_result="timeout"
  while true; do
    load1="$(current_load1 | tr ',' '.')"
    idle_gate_load1="$load1"
    if awk -v l="$load1" -v t="$idle_threshold" 'BEGIN{exit !(l<=t)}'; then
      echo "[perf] idle gate satisfied: load1=$load1 threshold=$idle_threshold"
      idle_gate_result="satisfied"
      break
    fi

    now_ts="$(date +%s)"
    elapsed="$((now_ts - start_ts))"
    if [ "$elapsed" -ge "$wait_idle_sec" ]; then
      echo "[perf] idle gate timeout: load1=$load1 threshold=$idle_threshold waited=${wait_idle_sec}s"
      break
    fi

    sleep "$poll_sec"
  done
fi

{
  echo "# format-version: 1"
  echo "# timestamp: $(date --iso-8601=seconds)"
  echo "# idle-threshold: $idle_threshold"
  echo "# wait-idle-sec: $wait_idle_sec"
  echo "# idle-gate-result: $idle_gate_result"
  echo "# idle-gate-load1: $idle_gate_load1"
  echo

  echo "## system"
  uname -a || true
  cat /etc/os-release || true
  echo

  echo "## uptime-load"
  uptime || true
  cat /proc/loadavg || true
  echo

  echo "## memory"
  free -h || true
  echo
  swapon --show || true
  echo
  if cmd_exists zramctl; then
    zramctl || true
  fi
  echo

  echo "## cpu-top"
  ps -eo comm=,%cpu=,rss= --sort=-%cpu | head -n 15 || true
  echo

  echo "## rss-top"
  ps -eo comm=,rss=,%cpu= --sort=-rss | head -n 15 || true
  echo

  echo "## key-processes"
  ps -C dms -C qs -C keyrs -C mpd -o pid=,comm=,%cpu=,rss=,etimes=,cmd= || true
  echo

  echo "## boot"
  if cmd_exists systemd-analyze; then
    systemd-analyze time 2>/dev/null || echo "systemd-analyze unavailable in current execution context"
  else
    echo "systemd-analyze not available"
  fi
  echo

  echo "## gpu"
  if cmd_exists nvidia-smi; then
    nvidia-smi --query-gpu=name,driver_version,temperature.gpu,utilization.gpu,memory.total,memory.used --format=csv,noheader,nounits || true
    echo
    nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader,nounits || true
  else
    echo "nvidia-smi not available"
  fi
} >"$out_file"

echo "[perf] wrote snapshot: $out_file"
