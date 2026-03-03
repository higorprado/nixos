#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF'
Usage:
  scripts/check-runtime-smoke.sh [--boot current|previous] [--allow-non-graphical] [--strict-backends] [--strict-logs]

Environment:
  RUNTIME_SMOKE_PORTAL_PIDNS_WARN_MAX=<n>   # override L101 max from warning budget file
  RUNTIME_SMOKE_PORTAL_INHIBIT_WARN_MAX=<n> # override L102 max from warning budget file
  RUNTIME_SMOKE_WPSTATE_WARN_MAX=<n>        # override L103 max from warning budget file
  RUNTIME_SMOKE_GKR_WARN_MAX=<n>            # override L104 max from warning budget file
  RUNTIME_SMOKE_NM_P2P_WARN_MAX=<n>         # override L105 max from warning budget file
EOF
}

boot="current"
allow_non_graphical=0
strict_backends=0
strict_logs=0
warning_overruns=0
budget_expired=0
scope="runtime-smoke"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --boot)
      boot="${2:-}"
      shift 2
      ;;
    --allow-non-graphical)
      allow_non_graphical=1
      shift
      ;;
    --strict-backends)
      strict_backends=1
      shift
      ;;
    --strict-logs)
      strict_logs=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_fail "$scope" "unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

ok() {
  log_ok "$scope" "$1"
}

warn() {
  log_warn "$scope" "$1"
}

fail() {
  log_fail "$scope" "$1"
  exit 1
}

require_system_unit_active() {
  local unit="$1"
  if systemctl is-active --quiet "$unit"; then
    ok "system unit active: $unit"
  else
    fail "system unit not active: $unit"
  fi
}

require_user_unit_active() {
  local unit="$1"
  if systemctl --user is-active --quiet "$unit"; then
    ok "user unit active: $unit"
  else
    fail "user unit not active: $unit"
  fi
}

expect_user_unit_active() {
  local unit="$1"
  if systemctl --user is-active --quiet "$unit"; then
    ok "user unit active: $unit"
    return 0
  fi

  if [ "$strict_backends" -eq 1 ]; then
    fail "expected backend user unit not active: $unit"
  fi
  warn "expected backend user unit not active: $unit"
}

require_user_unit_enabled() {
  local unit="$1"
  if systemctl --user is-enabled "$unit" >/dev/null 2>&1; then
    ok "user unit enabled: $unit"
  else
    fail "user unit not enabled: $unit"
  fi
}

if [ "$(id -u)" -eq 0 ]; then
  fail "run as regular user so user services can be checked"
fi

if ! [ -f /etc/os-release ] || ! grep -q '^ID=nixos$' /etc/os-release; then
  fail "this smoke check must run on a NixOS host"
fi

require_cmds "$scope" "jq" "rg"

case "${boot}" in
  current|previous) ;;
  *)
    fail "invalid --boot value: ${boot} (use current|previous)"
    ;;
esac

require_system_unit_active "greetd.service"

if [ "$allow_non_graphical" -eq 0 ]; then
  case "${XDG_SESSION_TYPE:-}" in
    wayland|x11)
      ok "graphical session type detected: ${XDG_SESSION_TYPE}"
      ;;
    *)
      fail "no graphical session detected (set --allow-non-graphical to bypass)"
      ;;
  esac
else
  warn "non-graphical session allowed by flag"
fi

if [ -n "${XDG_SESSION_ID:-}" ]; then
  if [ "$(loginctl show-session "$XDG_SESSION_ID" -p Active --value 2>/dev/null || echo no)" = "yes" ]; then
    ok "session is active: ${XDG_SESSION_ID}"
  else
    warn "could not confirm active state for session: ${XDG_SESSION_ID}"
  fi
else
  warn "XDG_SESSION_ID is unset"
fi

host_role="$(nix eval --raw "path:$PWD#nixosConfigurations.predator.config.custom.host.role")"
if [ "$host_role" != "desktop" ]; then
  fail "runtime smoke expects desktop host role, got: ${host_role}"
fi

caps_json="$(nix eval --json "path:$PWD#nixosConfigurations.predator.config.custom.desktop.capabilities")"
keyrs_enabled="$(nix eval --json "path:$PWD#nixosConfigurations.predator.config.custom.desktop.keyrs.enable" | jq -r '.')"

cap_niri="$(jq -r '.niri' <<<"$caps_json")"
cap_hyprland="$(jq -r '.hyprland' <<<"$caps_json")"
cap_dms="$(jq -r '.dms' <<<"$caps_json")"

ok "capabilities: niri=${cap_niri} hyprland=${cap_hyprland} dms=${cap_dms} keyrs=${keyrs_enabled}"

if command -v gdbus >/dev/null 2>&1; then
  if gdbus call --session \
    --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1; then
    ok "portal DBus ping succeeded"
  else
    fail "portal DBus ping failed"
  fi
else
  warn "gdbus not available; skipping portal ping"
fi

require_user_unit_active "xdg-desktop-portal.service"
expect_user_unit_active "xdg-desktop-portal-gtk.service"

if [ "$cap_niri" = "true" ]; then
  expect_user_unit_active "xdg-desktop-portal-gnome.service"
fi

if [ "$cap_hyprland" = "true" ]; then
  expect_user_unit_active "xdg-desktop-portal-hyprland.service"
fi

if [ "$keyrs_enabled" = "true" ]; then
  require_user_unit_enabled "keyrs.service"
fi

if [ "$cap_dms" = "true" ]; then
  require_user_unit_enabled "awww-daemon.service"
  require_user_unit_enabled "dms-awww.service"
fi

tmp_log="$(mktemp_file_scoped runtime-smoke-log)"
trap 'rm -f "$tmp_log"' EXIT

set +e
journalctl -b --no-pager >"$tmp_log" 2>/dev/null
sys_code=$?
journalctl --user -b --no-pager >>"$tmp_log" 2>/dev/null
usr_code=$?
set -e

if [ "$sys_code" -ne 0 ] && [ "$usr_code" -ne 0 ]; then
  fail "unable to read both system and user journals for smoke log scan"
fi

warning_budget_file="config/validation/runtime-warning-budget.json"
if [[ ! -f "$warning_budget_file" ]]; then
  fail "missing warning budget file: ${warning_budget_file}"
fi
if ! jq -e '.version == 1 and (.failPatterns | type == "array") and (.warningThresholds | type == "array")' "$warning_budget_file" >/dev/null; then
  fail "invalid warning budget schema in ${warning_budget_file}"
fi

count_pattern() {
  local pattern="$1"
  (rg -F "$pattern" "$tmp_log" || true) | wc -l | tr -d ' '
}

fail_if_pattern_seen() {
  local id="$1"
  local pattern="$2"
  local count
  count="$(count_pattern "$pattern")"
  if [ "$count" -gt 0 ]; then
    fail "${id}: found ${count} occurrences of '${pattern}'"
  fi
  ok "${id}: no occurrences for '${pattern}'"
}

warn_or_fail_threshold() {
  local id="$1"
  local pattern="$2"
  local max="$3"
  local owner="$4"
  local expires_on="$5"
  local count
  local today_utc
  count="$(count_pattern "$pattern")"

  if [[ -n "$expires_on" ]]; then
    today_utc="$(date -u +%F)"
    if [[ "$expires_on" < "$today_utc" ]]; then
      if [ "$strict_logs" -eq 1 ]; then
        fail "${id}: accepted warning budget expired on ${expires_on} (owner: ${owner})"
      fi
      warn "${id}: accepted warning budget expired on ${expires_on} (owner: ${owner})"
      budget_expired=$((budget_expired + 1))
    fi
  fi

  if [ "$count" -gt "$max" ]; then
    if [ "$strict_logs" -eq 1 ]; then
      fail "${id}: count ${count} exceeds max ${max} for '${pattern}' (owner: ${owner}, expiresOn: ${expires_on})"
    fi
    warn "${id}: count ${count} exceeds max ${max} for '${pattern}' (owner: ${owner}, expiresOn: ${expires_on})"
    warning_overruns=$((warning_overruns + 1))
    return 0
  fi
  ok "${id}: count ${count} <= ${max} for '${pattern}' (owner: ${owner}, expiresOn: ${expires_on})"
}

# New/unaccepted warning classes (must be zero).
while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  id="$(jq -r '.id' <<<"$entry")"
  pattern="$(jq -r '.pattern' <<<"$entry")"
  owner="$(jq -r '.owner // "unowned"' <<<"$entry")"
  fail_if_pattern_seen "$id" "$pattern"
  ok "${id}: owner=${owner}"
done < <(jq -c '.failPatterns[]' "$warning_budget_file")

# Known accepted warnings with threshold budgets.
while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  id="$(jq -r '.id' <<<"$entry")"
  pattern="$(jq -r '.pattern' <<<"$entry")"
  default_max="$(jq -r '.defaultMax' <<<"$entry")"
  env_override="$(jq -r '.envOverride // ""' <<<"$entry")"
  owner="$(jq -r '.owner // "unowned"' <<<"$entry")"
  expires_on="$(jq -r '.expiresOn // ""' <<<"$entry")"

  max="$default_max"
  if [[ -n "$env_override" ]]; then
    override_value="${!env_override:-}"
    if [[ -n "$override_value" ]]; then
      max="$override_value"
    fi
  fi

  warn_or_fail_threshold "$id" "$pattern" "$max" "$owner" "$expires_on"
done < <(jq -c '.warningThresholds[]' "$warning_budget_file")

if [ "$warning_overruns" -gt 0 ]; then
  warn "known warning budget overruns detected: ${warning_overruns}"
fi
if [ "$budget_expired" -gt 0 ]; then
  warn "warning budget entries past expiration date: ${budget_expired}"
fi

ok "runtime smoke passed"
