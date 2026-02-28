#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/precutover-run.sh

Environment:
  RUN_STRICT=1
    Convenience mode that enables stricter defaults:
    - STATUS_REQUIRE_PERF_OK=1 (fail on INCONCLUSIVE perf verdict)
    - STATUS_REQUIRE_VALIDATE_OK=1 (fail when validate-host is skipped/not ok)
    - GATE_REQUIRE_VALIDATE_HOST=1 (require validate-host in gate; cache accepted)
    - PERF_WAIT_IDLE_SEC=60 (if not already set)
    - PERF_IDLE_THRESHOLD=1.20 (if not already set)
    - STRICT_USER_SERVICES_PARITY=1 (if not already set)
    - STRICT_DOTFILES_PARITY=1 (if not already set)
    - STRICT_DEV_DOTFILES_PARITY=1 (if not already set)
EOF
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ "${RUN_STRICT:-0}" = "1" ]; then
  export STATUS_REQUIRE_PERF_OK="${STATUS_REQUIRE_PERF_OK:-1}"
  export STATUS_REQUIRE_VALIDATE_OK="${STATUS_REQUIRE_VALIDATE_OK:-1}"
  export GATE_REQUIRE_VALIDATE_HOST="${GATE_REQUIRE_VALIDATE_HOST:-1}"
  export PERF_WAIT_IDLE_SEC="${PERF_WAIT_IDLE_SEC:-60}"
  export PERF_IDLE_THRESHOLD="${PERF_IDLE_THRESHOLD:-1.20}"
  export STRICT_USER_SERVICES_PARITY="${STRICT_USER_SERVICES_PARITY:-1}"
  export STRICT_DOTFILES_PARITY="${STRICT_DOTFILES_PARITY:-1}"
  export STRICT_DEV_DOTFILES_PARITY="${STRICT_DEV_DOTFILES_PARITY:-1}"
  echo "[run] strict mode enabled (RUN_STRICT=1)"
  echo "[run] STATUS_REQUIRE_PERF_OK=$STATUS_REQUIRE_PERF_OK"
  echo "[run] STATUS_REQUIRE_VALIDATE_OK=$STATUS_REQUIRE_VALIDATE_OK"
  echo "[run] GATE_REQUIRE_VALIDATE_HOST=$GATE_REQUIRE_VALIDATE_HOST"
  echo "[run] PERF_WAIT_IDLE_SEC=$PERF_WAIT_IDLE_SEC"
  echo "[run] PERF_IDLE_THRESHOLD=$PERF_IDLE_THRESHOLD"
  echo "[run] STRICT_USER_SERVICES_PARITY=$STRICT_USER_SERVICES_PARITY"
  echo "[run] STRICT_DOTFILES_PARITY=$STRICT_DOTFILES_PARITY"
  echo "[run] STRICT_DEV_DOTFILES_PARITY=$STRICT_DEV_DOTFILES_PARITY"
fi

echo "[run] executing pre-cutover gate"
"$repo_root/scripts/precutover-gate.sh"

echo "[run] generating consolidated report"
"$repo_root/scripts/precutover-report.sh"

echo "[run] generating cutover checklist"
"$repo_root/scripts/cutover-checklist.sh"

echo "[run] evaluating latest status"
status_output="$("$repo_root/scripts/precutover-status.sh" 2>&1)"
echo "$status_output"

latest_run="$(find .migration-audit -maxdepth 1 -mindepth 1 -type d -name 'precutover-*' -printf '%T@ %p\n' | sort -rn | awk '{print $2}' | head -n1)"
latest_report="$(ls -1t .migration-audit/precutover-report-*.md 2>/dev/null | head -n1 || true)"
latest_checklist="$(ls -1t .migration-audit/cutover-checklist-*.md 2>/dev/null | head -n1 || true)"

echo "[run] completed"
echo "[run] latest run dir: $latest_run"
if [ -n "$latest_report" ]; then
  echo "[run] latest report: $latest_report"
  overall_verdict="$(grep -m1 '^- Overall verdict:' "$latest_report" | sed 's/^- Overall verdict: //' || true)"
  overall_reason="$(grep -m1 '^- Overall reason:' "$latest_report" | sed 's/^- Overall reason: //' || true)"
  if [ -n "$overall_verdict" ]; then
    echo "[run] overall verdict: $overall_verdict"
  fi
  if [ -n "$overall_reason" ]; then
    echo "[run] overall reason: $overall_reason"
  fi
fi
if [ -n "$latest_checklist" ]; then
  echo "[run] latest checklist: $latest_checklist"
fi
