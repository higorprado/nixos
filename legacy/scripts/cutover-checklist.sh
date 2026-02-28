#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

runs=(
  $(find .migration-audit -maxdepth 1 -mindepth 1 -type d -name 'precutover-*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | awk '{print $2}')
)
latest_run="${runs[0]:-}"

if [ -z "$latest_run" ]; then
  echo "[checklist] no precutover runs found under .migration-audit/"
  exit 1
fi

summary="$latest_run/SUMMARY.md"
if [ ! -f "$summary" ]; then
  echo "[checklist] missing summary: $summary"
  exit 1
fi

latest_report=""
for report in $(ls -1t .migration-audit/precutover-report-*.md 2>/dev/null || true); do
  if grep -q "^- Latest run: \`$latest_run\`" "$report"; then
    latest_report="$report"
    break
  fi
done

gate_status="$(grep -m1 '^- Status:' "$summary" | sed 's/^- Status: //' || true)"
unknown_warnings="$(grep -m1 '^- Warnings unknown:' "$summary" | sed 's/^- Warnings unknown: //' || true)"
warnings_total="$(grep -m1 '^- Warnings total:' "$summary" | sed 's/^- Warnings total: //' || true)"
warnings_known="$(grep -m1 '^- Warnings known:' "$summary" | sed 's/^- Warnings known: //' || true)"
validate_status="$(grep -m1 '^- Validate host status:' "$summary" | sed 's/^- Validate host status: //' || true)"
service_parity_status="$(grep -m1 '^- User services parity status:' "$summary" | sed 's/^- User services parity status: //' || true)"
dotfiles_parity_status="$(grep -m1 '^- Dotfiles parity status:' "$summary" | sed 's/^- Dotfiles parity status: //' || true)"

perf_verdict="N/A"
overall_verdict="N/A"
overall_reason="N/A"
if [ -n "$latest_report" ] && [ -f "$latest_report" ]; then
  perf_verdict="$(grep -m1 '^- Perf verdict (latest vs previous):' "$latest_report" | sed 's/^- Perf verdict (latest vs previous): //' || true)"
  overall_verdict="$(grep -m1 '^- Overall verdict:' "$latest_report" | sed 's/^- Overall verdict: //' || true)"
  overall_reason="$(grep -m1 '^- Overall reason:' "$latest_report" | sed 's/^- Overall reason: //' || true)"
fi

cutover_decision="NO-GO"
decision_reason="blocking checks present"
if [ "$gate_status" = "PASS" ] && [ "${unknown_warnings:-0}" = "0" ]; then
  case "$overall_verdict" in
    READY)
      if [ "${validate_status:-unknown}" = "ok" ] || [ "${validate_status:-unknown}" = "ok-cached" ]; then
        cutover_decision="GO"
        decision_reason="all checks green"
      else
        cutover_decision="GO_WITH_NOTE"
        decision_reason="validate-host not fully confirmed on this machine"
      fi
      ;;
    READY_WITH_NOTE|N/A)
      cutover_decision="GO_WITH_NOTE"
      decision_reason="non-blocking caution (typically perf inconclusive)"
      ;;
  esac
fi

mark() {
  if [ "$1" = "1" ]; then
    echo "[x]"
  else
    echo "[ ]"
  fi
}

ok_gate=0
ok_unknown=0
ok_perf=0
ok_validate=0
[ "$gate_status" = "PASS" ] && ok_gate=1
[ "${unknown_warnings:-0}" = "0" ] && ok_unknown=1
if [ "$perf_verdict" = "OK" ] || [ "$perf_verdict" = "INCONCLUSIVE" ] || [ "$perf_verdict" = "N/A" ]; then
  ok_perf=1
fi
if [ "${validate_status:-unknown}" = "ok" ] || [ "${validate_status:-unknown}" = "ok-cached" ]; then
  ok_validate=1
fi

ts="$(date +%Y%m%d-%H%M%S-%N)"
out_file=".migration-audit/cutover-checklist-$ts.md"

{
  echo "# NixOS Cutover Checklist"
  echo
  echo "- Generated: $(date --iso-8601=seconds)"
  echo "- Latest run: \`$latest_run\`"
  if [ -n "$latest_report" ]; then
    echo "- Latest report: \`$latest_report\`"
  fi
  echo "- Gate status: $gate_status"
  echo "- Warnings: total=$warnings_total known=$warnings_known unknown=$unknown_warnings"
  echo "- Validate host status: ${validate_status:-UNKNOWN}"
  echo "- User services parity status: ${service_parity_status:-UNKNOWN}"
  echo "- Dotfiles parity status: ${dotfiles_parity_status:-UNKNOWN}"
  echo "- Perf verdict: $perf_verdict"
  echo "- Overall verdict: $overall_verdict"
  echo "- Overall reason: $overall_reason"
  echo "- Cutover decision: **$cutover_decision**"
  echo "- Decision reason: $decision_reason"
  echo

  echo "## Pre-cutover Criteria"
  echo "- $(mark "$ok_gate") Gate status is PASS"
  echo "- $(mark "$ok_unknown") Unknown warnings are 0"
  echo "- $(mark "$ok_validate") validate-host status is ok"
  echo "- $(mark "$ok_perf") Perf verdict is acceptable (OK/INCONCLUSIVE/N/A)"
  echo

  echo "## Final CachyOS Validation"
  echo "1. Run strict validation (recommended before installer boot):"
  echo '   ```bash'
  echo '   RUN_STRICT=1 PERF_WAIT_IDLE_SEC=60 PERF_IDLE_THRESHOLD=1.20 STRICT_USER_SERVICES_PARITY=1 STRICT_DOTFILES_PARITY=1 STRICT_DEV_DOTFILES_PARITY=1 ./scripts/precutover-run.sh'
  echo '   ```'
  echo "2. If strict run fails due non-idle perf, rerun when machine is idle."
  echo "3. Prefer 'Cutover decision: GO' before installation/switch window."
  echo

  echo "## NixOS Host Cutover Steps"
  echo "1. Boot/install target NixOS with this repository available."
  echo "2. Preferred scripted flow:"
  echo '   ```bash'
  echo '   ./scripts/cutover-execute.sh test'
  echo '   ./scripts/cutover-execute.sh switch'
  echo '   ```'
  echo "3. Equivalent manual flow:"
  echo '   ```bash'
  echo '   sudo nixos-rebuild test --flake path:$PWD#predator'
  echo '   sudo nixos-rebuild switch --flake path:$PWD#predator'
  echo '   ./scripts/nixos-post-switch-smoke.sh'
  echo '   ```'
  echo "4. Reboot and verify login path and critical services."
  echo

  echo "## Post-switch Verification"
  echo "1. Validate greetd -> niri -> DMS startup."
  echo "2. Validate DNS/VPN, audio/bluetooth, NVIDIA behavior, key remapping."
  echo "3. Validate user units: keyrs, awww-daemon, dms-awww, backup timers."
  echo

  echo "## Artifact References"
  echo "- Summary: \`$summary\`"
  if [ -n "$latest_report" ]; then
    echo "- Report: \`$latest_report\`"
  fi
  echo "- Run directory: \`$latest_run\`"
} >"$out_file"

echo "[checklist] wrote: $out_file"
