#!/usr/bin/env bash
set -euo pipefail

base=".migration-audit"
runs=(
  $(find "$base" -maxdepth 1 -mindepth 1 -type d -name 'precutover-*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | awk '{print $2}')
)

if [ "${#runs[@]}" -eq 0 ]; then
  echo "[history] no precutover runs found under $base"
  exit 0
fi

echo "run,status,sudo_retry,warnings_total,warnings_known,warnings_unknown,timestamp"
for run in "${runs[@]}"; do
  summary="$run/SUMMARY.md"
  if [ -f "$summary" ]; then
    status="$(grep -m1 '^- Status:' "$summary" | sed 's/^- Status: //' || true)"
    sudo_retry="$(grep -m1 '^- Sudo retry used:' "$summary" | sed 's/^- Sudo retry used: //' || true)"
    wt="$(grep -m1 '^- Warnings total:' "$summary" | sed 's/^- Warnings total: //' || true)"
    wk="$(grep -m1 '^- Warnings known:' "$summary" | sed 's/^- Warnings known: //' || true)"
    wu="$(grep -m1 '^- Warnings unknown:' "$summary" | sed 's/^- Warnings unknown: //' || true)"
    ts="$(grep -m1 '^- Timestamp:' "$summary" | sed 's/^- Timestamp: //' || true)"
  else
    validate_log="$run/validate-host.log"
    if [ -f "$validate_log" ] && rg -q "^error:|Build failed|\\[gate\\] FAIL" "$run"/*.log 2>/dev/null; then
      status="FAIL"
    else
      status="PASS"
    fi
    if [ -f "$validate_log" ] && rg -q "retrying with sudo" "$validate_log" 2>/dev/null; then
      sudo_retry="1"
    else
      sudo_retry="0"
    fi
    if [ -f "$validate_log" ]; then
      wt="$(rg -n "^warning:|^evaluation warning:" "$validate_log" 2>/dev/null | wc -l | tr -d ' ')"
      wk="$(rg -n "xorg\\.libxcb.*renamed to 'libxcb'" "$validate_log" 2>/dev/null | wc -l | tr -d ' ')"
    else
      wt="0"
      wk="0"
    fi
    wu="$((wt - wk))"
    ts="$(date -r "$run" --iso-8601=seconds 2>/dev/null || true)"
  fi

  echo "$run,${status:-UNKNOWN},${sudo_retry:-},${wt:-},${wk:-},${wu:-},${ts:-}"
done
