#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

ts="$(date +%Y%m%d-%H%M%S-%N)"
out_dir=".migration-audit/precutover-$ts"
mkdir -p "$out_dir"
used_sudo_retry=0
validate_status="ok"
validate_reason=""
validate_cache_file="${TMPDIR:-/tmp}/nixos-validate-host-last-ok-${USER}.txt"
service_parity_status="ok"
dotfiles_parity_status="ok"
service_parity_rc=0
dotfiles_parity_rc=0
allow_unknown_warnings="${GATE_ALLOW_UNKNOWN_WARNINGS:-0}"
require_validate_host="${GATE_REQUIRE_VALIDATE_HOST:-0}"
allowlist_file="$repo_root/scripts/warnings-allowlist.txt"
perf_wait_idle_sec="${PERF_WAIT_IDLE_SEC:-20}"
perf_idle_threshold="${PERF_IDLE_THRESHOLD:-0.50}"
perf_poll_sec="${PERF_POLL_SEC:-2}"
host_is_nixos=0
if [ -f /etc/os-release ] && grep -q '^ID=nixos$' /etc/os-release; then
  host_is_nixos=1
fi

echo "[gate] writing outputs to: $out_dir"

echo "[gate] checking git-tracked flake inputs"
"$repo_root/scripts/check-flake-tracked.sh" >"$out_dir/check-tracked.log" 2>&1

echo "[gate] checking declarative runtime paths"
"$repo_root/scripts/check-declarative-paths.sh" >"$out_dir/check-paths.log" 2>&1

echo "[gate] checking known deprecations in local nix files"
"$repo_root/scripts/check-nix-deprecations.sh" >"$out_dir/check-deprecations.log" 2>&1

echo "[gate] checking logid config parity with current host"
"$repo_root/scripts/check-logid-parity.sh" >"$out_dir/check-logid-parity.log" 2>&1

echo "[gate] checking runtime config parity with current host"
"$repo_root/scripts/check-runtime-config-parity.sh" >"$out_dir/check-runtime-config-parity.log" 2>&1

echo "[gate] checking user-services parity with current host"
if "$repo_root/scripts/check-user-services-parity.sh" >"$out_dir/check-user-services-parity.log" 2>&1; then
  service_parity_status="ok"
else
  service_parity_rc=$?
  service_parity_status="fail"
  echo "[gate] warn: check-user-services-parity failed (rc=$service_parity_rc)"
fi
if rg -q '\[services-parity\] WARN:' "$out_dir/check-user-services-parity.log" 2>/dev/null; then
  service_parity_status="warn"
fi

echo "[gate] checking managed dotfiles parity with current host"
if "$repo_root/scripts/check-dotfiles-parity.sh" >"$out_dir/check-dotfiles-parity.log" 2>&1; then
  dotfiles_parity_status="ok"
else
  dotfiles_parity_rc=$?
  dotfiles_parity_status="fail"
  echo "[gate] warn: check-dotfiles-parity failed (rc=$dotfiles_parity_rc)"
fi
if rg -q '\[dotfiles-parity\] WARN:' "$out_dir/check-dotfiles-parity.log" 2>/dev/null; then
  dotfiles_parity_status="warn"
fi

echo "[gate] checking dev dotfiles parity with current host"
"$repo_root/scripts/check-dev-dotfiles-parity.sh" >"$out_dir/check-dev-dotfiles-parity.log" 2>&1 || {
  echo "[gate] dev dotfiles parity failed; see $out_dir/check-dev-dotfiles-parity.log"
  exit 1
}

echo "[gate] running baseline audit"
"$repo_root/scripts/migration-baseline-audit.sh" >"$out_dir/baseline-audit.log" 2>&1

echo "[gate] collecting performance snapshot"
perf_output="$("$repo_root/scripts/perf-snapshot.sh" \
  "$out_dir" \
  --wait-idle-sec "$perf_wait_idle_sec" \
  --idle-threshold "$perf_idle_threshold" \
  --poll-sec "$perf_poll_sec" \
  2>&1 | tee "$out_dir/perf-snapshot.log")"
perf_file="$(printf '%s\n' "$perf_output" | sed -n 's/^\[perf\] wrote snapshot: //p' | tail -n1)"

echo "[gate] running host validation"
"$repo_root/scripts/validate-host.sh" >"$out_dir/validate-host.log" 2>&1 || {
  if rg -q "/nix/var/nix/db/big-lock.*Permission denied|single-user Nix installation" "$out_dir/validate-host.log"; then
    echo "[gate] validate-host hit nix lock permissions; retrying with sudo"
    used_sudo_retry=1
    if sudo "$repo_root/scripts/validate-host.sh" >"$out_dir/validate-host.log" 2>&1; then
      validate_status="ok"
    else
      validate_status="skipped"
      validate_reason="sudo retry failed (likely non-interactive/no credentials)"
      echo "[gate] warn: $validate_reason"
      {
        echo
        echo "[gate] note: validate-host skipped after sudo retry failure"
      } >>"$out_dir/validate-host.log"
    fi
  else
    echo "[gate] validate-host failed; see $out_dir/validate-host.log"
    exit 1
  fi
}

echo "[gate] summary"
if rg -n "^error:|\\[validate\\].*error|\\[smoke\\]\\[fail\\]" "$out_dir" >/dev/null 2>&1; then
  echo "[gate] FAIL: errors detected; see logs under $out_dir"
  exit 1
fi

warnings_file="$out_dir/warnings.txt"
unknown_warnings_file="$out_dir/warnings-unknown.txt"
rg -n "^warning:|^evaluation warning:" "$out_dir/validate-host.log" >"$warnings_file" || true
warnings_count="$(wc -l <"$warnings_file" | tr -d ' ')"

cp "$warnings_file" "$unknown_warnings_file"
if [ -f "$allowlist_file" ]; then
  while IFS= read -r pattern; do
    case "$pattern" in
      "" | \#*) continue ;;
    esac
    tmp="$(mktemp)"
    rg -v -- "$pattern" "$unknown_warnings_file" >"$tmp" || true
    mv "$tmp" "$unknown_warnings_file"
  done <"$allowlist_file"
fi

unknown_count="$(wc -l <"$unknown_warnings_file" | tr -d ' ')"
known_count="$((warnings_count - unknown_count))"
status="PASS"
status_reason=""
declare -a fail_reasons=()
if [ "$validate_status" = "skipped" ] && [ "$require_validate_host" = "1" ]; then
  if [ -f "$validate_cache_file" ] && rg -q "^repo=$repo_root$" "$validate_cache_file" 2>/dev/null; then
    validate_status="ok-cached"
    validate_reason="using cached successful validate-host run from $validate_cache_file"
  else
    fail_reasons+=("validate-host skipped but GATE_REQUIRE_VALIDATE_HOST=1")
  fi
fi
if [ "$service_parity_status" = "fail" ]; then
  if [ "$host_is_nixos" -eq 1 ]; then
    fail_reasons+=("user-services parity check failed")
  else
    service_parity_status="warn-precutover"
  fi
fi
if [ "$dotfiles_parity_status" = "fail" ]; then
  if [ "$host_is_nixos" -eq 1 ]; then
    fail_reasons+=("dotfiles parity check failed")
  else
    dotfiles_parity_status="warn-precutover"
  fi
fi

echo "[gate] warnings: total=$warnings_count known=$known_count"
if [ "$unknown_count" -gt 0 ]; then
  echo "[gate] unknown warnings detected:"
  cat "$unknown_warnings_file" || true
  if [ "$allow_unknown_warnings" = "1" ]; then
    echo "[gate] unknown warnings are allowed by GATE_ALLOW_UNKNOWN_WARNINGS=1"
  else
    fail_reasons+=("unknown warnings present")
  fi
fi

if [ "${#fail_reasons[@]}" -gt 0 ]; then
  status="FAIL"
  status_reason="$(IFS='; '; echo "${fail_reasons[*]}")"
fi

summary_md="$out_dir/SUMMARY.md"
{
  echo "# Pre-cutover Gate Summary"
  echo
  echo "- Timestamp: $(date --iso-8601=seconds)"
  echo "- Status: $status"
  if [ -n "$status_reason" ]; then
    echo "- Status reason: $status_reason"
  fi
  echo "- Sudo retry used: $used_sudo_retry"
  echo "- Warnings total: $warnings_count"
  echo "- Warnings known: $known_count"
  echo "- Warnings unknown: $unknown_count"
  echo "- Unknown warning override: $allow_unknown_warnings"
  echo "- Validate host status: $validate_status"
  if [ -n "$validate_reason" ]; then
    echo "- Validate host reason: $validate_reason"
  fi
  echo "- Validate host cache file: $validate_cache_file"
  echo "- Validate host required: $require_validate_host"
  echo "- User services parity status: $service_parity_status"
  echo "- Dotfiles parity status: $dotfiles_parity_status"
  echo "- Host is NixOS: $host_is_nixos"
  echo "- Perf idle wait sec: $perf_wait_idle_sec"
  echo "- Perf idle threshold: $perf_idle_threshold"
  echo
  echo "## Logs"
  echo "- check-tracked: \`$out_dir/check-tracked.log\`"
  echo "- check-paths: \`$out_dir/check-paths.log\`"
  echo "- check-deprecations: \`$out_dir/check-deprecations.log\`"
  echo "- check-logid-parity: \`$out_dir/check-logid-parity.log\`"
  echo "- check-runtime-config-parity: \`$out_dir/check-runtime-config-parity.log\`"
  echo "- check-user-services-parity: \`$out_dir/check-user-services-parity.log\`"
  echo "- check-dotfiles-parity: \`$out_dir/check-dotfiles-parity.log\`"
  echo "- check-dev-dotfiles-parity: \`$out_dir/check-dev-dotfiles-parity.log\`"
  echo "- baseline-audit: \`$out_dir/baseline-audit.log\`"
  echo "- perf-snapshot: \`$out_dir/perf-snapshot.log\`"
  if [ -n "${perf_file:-}" ]; then
    echo "- perf-data: \`$perf_file\`"
  fi
  echo "- validate-host: \`$out_dir/validate-host.log\`"
  echo "- warnings: \`$out_dir/warnings.txt\`"
  echo "- warnings-unknown: \`$out_dir/warnings-unknown.txt\`"
  echo "- warning allowlist: \`$allowlist_file\`"
  echo
  if [ "$unknown_count" -gt 0 ]; then
    echo "## Unknown Warnings"
    cat "$unknown_warnings_file" || true
  else
    echo "## Unknown Warnings"
    echo "None."
  fi

  if [ "$validate_status" = "skipped" ]; then
    echo
    echo "## Validate Host"
    echo "- Status: skipped"
    echo "- Reason: $validate_reason"
    echo "- Action: run \`sudo ./scripts/validate-host.sh\` on the host and re-run gate."
  fi

  if [ "$host_is_nixos" -eq 0 ] && { [ "$service_parity_status" = "warn-precutover" ] || [ "$dotfiles_parity_status" = "warn-precutover" ]; }; then
    echo
    echo "## Pre-cutover Host Notes"
    echo "- This host is non-NixOS, so strict parity checks against live user units/dotfiles are marked as pre-cutover warnings."
    echo "- These checks remain blocking on target NixOS host."
  fi

  if [ -n "${perf_file:-}" ] && [ -f "$perf_file" ]; then
    perf_idle_gate="$(sed -n 's/^# idle-gate-result: //p' "$perf_file" | head -n1 || true)"
    perf_idle_load1="$(sed -n 's/^# idle-gate-load1: //p' "$perf_file" | head -n1 || true)"
    echo
    echo "## Perf Snapshot Highlights"
    if [ -n "$perf_idle_gate" ]; then
      echo "- Idle gate: $perf_idle_gate (load1=$perf_idle_load1)"
    fi
    echo "- Load1: $(sed -n '/^## uptime-load/{n;p;}' "$perf_file" | awk -F'load average: ' '{print $2}' | cut -d',' -f1 | tr -d ' ' || true)"
    echo "- Memory: used=$(awk '/^Mem:/ {print $3; exit}' "$perf_file" || true) total=$(awk '/^Mem:/ {print $2; exit}' "$perf_file" || true)"
    echo "- dms RSS (KB): $(awk '$2=="dms" {print $4; exit}' "$perf_file" || true)"
    echo "- qs RSS (KB): $(awk '$2=="qs" {print $4; exit}' "$perf_file" || true)"
    echo "- keyrs RSS (KB): $(awk '$2=="keyrs" {print $4; exit}' "$perf_file" || true)"
    echo "- mpd RSS (KB): $(awk '$2=="mpd" {print $4; exit}' "$perf_file" || true)"
  fi
} >"$summary_md"

if [ "$status" = "FAIL" ]; then
  echo "[gate] FAIL: $status_reason"
  echo "[gate] see summary: $summary_md"
  exit 1
fi

echo "[gate] PASS: pre-cutover checks completed"
echo "[gate] logs:"
echo "  $out_dir/check-tracked.log"
echo "  $out_dir/check-paths.log"
echo "  $out_dir/check-deprecations.log"
echo "  $out_dir/check-logid-parity.log"
echo "  $out_dir/check-runtime-config-parity.log"
echo "  $out_dir/check-user-services-parity.log"
echo "  $out_dir/check-dotfiles-parity.log"
echo "  $out_dir/check-dev-dotfiles-parity.log"
echo "  $out_dir/baseline-audit.log"
echo "  $out_dir/perf-snapshot.log"
if [ -n "${perf_file:-}" ]; then
  echo "  $perf_file"
fi
echo "  $out_dir/validate-host.log"
echo "  $out_dir/warnings.txt"
echo "  $out_dir/warnings-unknown.txt"
echo "  $out_dir/SUMMARY.md"
