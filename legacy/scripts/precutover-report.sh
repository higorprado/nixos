#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

runs=(
  $(find .migration-audit -maxdepth 1 -mindepth 1 -type d -name 'precutover-*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | awk '{print $2}')
)
latest_run="${runs[0]:-}"
prev_run=""

if [ -z "$latest_run" ]; then
  echo "[report] no precutover runs found under .migration-audit/"
  exit 1
fi

latest_summary="$latest_run/SUMMARY.md"
latest_perf="$(ls -1 "$latest_run"/perf-*.txt 2>/dev/null | head -n1 || true)"
prev_perf=""
for candidate in "${runs[@]:1}"; do
  candidate_perf="$(ls -1 "$candidate"/perf-*.txt 2>/dev/null | head -n1 || true)"
  if [ -n "$candidate_perf" ]; then
    prev_run="$candidate"
    prev_perf="$candidate_perf"
    break
  fi
done

perf_compare_output=""
perf_verdict="N/A"
if [ -n "$latest_perf" ] && [ -n "$prev_perf" ]; then
  perf_compare_output="$(./scripts/perf-compare.sh "$prev_perf" "$latest_perf" 2>&1 || true)"
  if printf '%s\n' "$perf_compare_output" | rg -q "RESULT: REGRESSION"; then
    perf_verdict="REGRESSION"
  elif printf '%s\n' "$perf_compare_output" | rg -q "RESULT: INCONCLUSIVE"; then
    perf_verdict="INCONCLUSIVE"
  elif printf '%s\n' "$perf_compare_output" | rg -q "RESULT: OK"; then
    perf_verdict="OK"
  fi
fi

gate_status="UNKNOWN"
unknown_warnings="UNKNOWN"
validate_status="UNKNOWN"
service_parity_status="UNKNOWN"
dotfiles_parity_status="UNKNOWN"
host_is_nixos="UNKNOWN"
if [ -f "$latest_summary" ]; then
  gate_status="$(grep -m1 '^- Status:' "$latest_summary" | sed 's/^- Status: //' || true)"
  unknown_warnings="$(grep -m1 '^- Warnings unknown:' "$latest_summary" | sed 's/^- Warnings unknown: //' || true)"
  validate_status="$(grep -m1 '^- Validate host status:' "$latest_summary" | sed 's/^- Validate host status: //' || true)"
  service_parity_status="$(grep -m1 '^- User services parity status:' "$latest_summary" | sed 's/^- User services parity status: //' || true)"
  dotfiles_parity_status="$(grep -m1 '^- Dotfiles parity status:' "$latest_summary" | sed 's/^- Dotfiles parity status: //' || true)"
  host_is_nixos="$(grep -m1 '^- Host is NixOS:' "$latest_summary" | sed 's/^- Host is NixOS: //' || true)"
fi

overall_verdict="READY"
overall_reason="all checks green"
if [ "$gate_status" != "PASS" ]; then
  overall_verdict="BLOCKED"
  overall_reason="gate status is not PASS"
elif [ "${unknown_warnings:-0}" != "0" ]; then
  overall_verdict="BLOCKED"
  overall_reason="unknown warnings present"
elif [ "$perf_verdict" = "REGRESSION" ]; then
  overall_verdict="BLOCKED"
  overall_reason="perf regression detected"
elif [ "$service_parity_status" = "fail" ] || [ "$dotfiles_parity_status" = "fail" ]; then
  overall_verdict="BLOCKED"
  overall_reason="strict parity checks failed"
else
  notes=()
  [ "$perf_verdict" = "INCONCLUSIVE" ] && notes+=("perf=inconclusive")
  if [ "$validate_status" != "ok" ] && [ "$validate_status" != "ok-cached" ]; then
    notes+=("validate-host=$validate_status")
  fi
  [ "$service_parity_status" = "warn" ] && notes+=("services-parity=warn")
  [ "$dotfiles_parity_status" = "warn" ] && notes+=("dotfiles-parity=warn")
  if [ "$host_is_nixos" = "1" ]; then
    [ "$service_parity_status" = "warn-precutover" ] && notes+=("services-parity=warn-precutover")
    [ "$dotfiles_parity_status" = "warn-precutover" ] && notes+=("dotfiles-parity=warn-precutover")
  fi
  if [ "${#notes[@]}" -gt 0 ]; then
    overall_verdict="READY_WITH_NOTE"
    overall_reason="$(IFS=', '; echo "${notes[*]}")"
  fi
fi

ts="$(date +%Y%m%d-%H%M%S-%N)"
out_file=".migration-audit/precutover-report-$ts.md"

{
  echo "# Pre-cutover Consolidated Report"
  echo
  echo "- Generated: $(date --iso-8601=seconds)"
  echo "- Latest run: \`$latest_run\`"
  if [ -n "$prev_run" ]; then
    echo "- Previous run: \`$prev_run\`"
  fi
  echo "- Gate status: $gate_status"
  echo "- Unknown warnings: $unknown_warnings"
  echo "- Validate host status: $validate_status"
  echo "- User services parity status: $service_parity_status"
  echo "- Dotfiles parity status: $dotfiles_parity_status"
  echo "- Host is NixOS: $host_is_nixos"
  echo "- Perf verdict (latest vs previous): $perf_verdict"
  echo "- Overall verdict: $overall_verdict"
  echo "- Overall reason: $overall_reason"
  echo

  echo "## Latest Summary"
  if [ -f "$latest_summary" ]; then
    sed -n '1,200p' "$latest_summary"
  else
    echo "Missing \`$latest_summary\`"
  fi
  echo

  echo "## Gate History"
  echo '```tsv'
  ./scripts/precutover-history.sh || true
  echo '```'
  echo

  echo "## Perf History"
  echo '```tsv'
  ./scripts/perf-history.sh || true
  echo '```'
  echo

  echo "## Perf Regression Check (Latest vs Previous)"
  if [ -n "$latest_perf" ] && [ -n "$prev_perf" ]; then
    echo "Comparing:"
    echo "- old: \`$prev_perf\`"
    echo "- new: \`$latest_perf\`"
    echo
    echo '```text'
    printf '%s\n' "$perf_compare_output"
    echo '```'
  else
    echo "Not enough perf snapshots to compare."
  fi
} >"$out_file"

echo "[report] wrote: $out_file"
