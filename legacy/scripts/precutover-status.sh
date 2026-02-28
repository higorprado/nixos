#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/precutover-status.sh

Environment:
  STATUS_REQUIRE_PERF_OK=1
    Fail when perf verdict is INCONCLUSIVE.
  STATUS_REQUIRE_VALIDATE_OK=1
    Fail when validate-host status is not ok.
EOF
  exit 0
fi

require_perf_ok="${STATUS_REQUIRE_PERF_OK:-0}"
require_validate_ok="${STATUS_REQUIRE_VALIDATE_OK:-0}"

latest_run="$(find .migration-audit -maxdepth 1 -mindepth 1 -type d -name 'precutover-*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | awk '{print $2}' | head -n1)"

if [ -z "${latest_run:-}" ]; then
  echo "[status] no precutover runs found"
  exit 1
fi

summary="$latest_run/SUMMARY.md"
if [ ! -f "$summary" ]; then
  echo "[status] missing summary: $summary"
  exit 1
fi

gate_status="$(grep -m1 '^- Status:' "$summary" | sed 's/^- Status: //' || true)"
unknown_warnings="$(grep -m1 '^- Warnings unknown:' "$summary" | sed 's/^- Warnings unknown: //' || true)"
validate_status="$(grep -m1 '^- Validate host status:' "$summary" | sed 's/^- Validate host status: //' || true)"
service_parity_status="$(grep -m1 '^- User services parity status:' "$summary" | sed 's/^- User services parity status: //' || true)"
dotfiles_parity_status="$(grep -m1 '^- Dotfiles parity status:' "$summary" | sed 's/^- Dotfiles parity status: //' || true)"

latest_report="$(ls -1t .migration-audit/precutover-report-*.md 2>/dev/null | head -n1 || true)"
matching_report=""
for report in $(ls -1t .migration-audit/precutover-report-*.md 2>/dev/null || true); do
  if grep -q "^- Latest run: \`$latest_run\`" "$report"; then
    matching_report="$report"
    break
  fi
done
if [ -n "$matching_report" ]; then
  latest_report="$matching_report"
fi
perf_verdict="N/A"
if [ -n "$latest_report" ]; then
  perf_verdict="$(grep -m1 '^- Perf verdict (latest vs previous):' "$latest_report" | sed 's/^- Perf verdict (latest vs previous): //' || true)"
fi

echo "[status] run=$latest_run"
if [ -n "$latest_report" ]; then
  echo "[status] report=$latest_report"
else
  echo "[status] report=N/A"
fi
echo "[status] gate_status=${gate_status:-UNKNOWN}"
echo "[status] unknown_warnings=${unknown_warnings:-UNKNOWN}"
echo "[status] validate_status=${validate_status:-UNKNOWN}"
echo "[status] service_parity_status=${service_parity_status:-UNKNOWN}"
echo "[status] dotfiles_parity_status=${dotfiles_parity_status:-UNKNOWN}"
echo "[status] perf_verdict=${perf_verdict:-N/A}"
echo "[status] require_perf_ok=$require_perf_ok"
echo "[status] require_validate_ok=$require_validate_ok"

if [ "${gate_status:-}" != "PASS" ]; then
  echo "[status] FAIL: gate status is not PASS"
  exit 1
fi

if [ "${unknown_warnings:-0}" != "0" ]; then
  echo "[status] FAIL: unknown warnings present"
  exit 1
fi

if [ "${service_parity_status:-unknown}" = "fail" ]; then
  echo "[status] FAIL: user services parity failed"
  exit 1
fi

if [ "${dotfiles_parity_status:-unknown}" = "fail" ]; then
  echo "[status] FAIL: dotfiles parity failed"
  exit 1
fi

if [ "${service_parity_status:-unknown}" = "warn-precutover" ]; then
  echo "[status] WARN: user services parity has pre-cutover drift on non-NixOS host"
fi

if [ "${dotfiles_parity_status:-unknown}" = "warn-precutover" ]; then
  echo "[status] WARN: dotfiles parity has pre-cutover drift on non-NixOS host"
fi

if [ "${validate_status:-unknown}" != "ok" ] && [ "${validate_status:-unknown}" != "ok-cached" ]; then
  if [ "$require_validate_ok" = "1" ]; then
    echo "[status] FAIL: validate-host status is ${validate_status:-unknown} and STATUS_REQUIRE_VALIDATE_OK=1"
    exit 1
  fi
  echo "[status] WARN: validate-host status is ${validate_status:-unknown}"
fi

if [ "${perf_verdict:-N/A}" = "REGRESSION" ]; then
  echo "[status] FAIL: perf verdict is REGRESSION"
  exit 1
fi

if [ "${perf_verdict:-N/A}" = "INCONCLUSIVE" ]; then
  if [ "$require_perf_ok" = "1" ]; then
    echo "[status] FAIL: perf verdict is INCONCLUSIVE and STATUS_REQUIRE_PERF_OK=1"
    exit 1
  fi
  echo "[status] WARN: perf verdict is INCONCLUSIVE (non-idle snapshot)"
elif [ "${perf_verdict:-N/A}" = "N/A" ] && [ "$require_perf_ok" = "1" ]; then
  echo "[status] FAIL: perf verdict is N/A and STATUS_REQUIRE_PERF_OK=1"
  exit 1
else
  echo "[status] OK"
fi
