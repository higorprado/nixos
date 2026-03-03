#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/runtime_warning_budget.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/runtime_warning_budget.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF'
Usage:
  scripts/check-runtime-smoke.sh [--boot current|previous] [--allow-non-graphical] [--strict-backends] [--strict-logs] [--skip-log-budget]

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
skip_log_budget=0
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
    --skip-log-budget)
      skip_log_budget=1
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
if [ "$skip_log_budget" -eq 1 ]; then
  warn "log warning-budget scan skipped by flag"
  ok "runtime smoke passed"
  exit 0
fi

if ! runtime_warning_budget_scan "$scope" "$warning_budget_file" "$tmp_log" "$strict_logs" warning_overruns budget_expired; then
  exit 1
fi

if [ "$warning_overruns" -gt 0 ]; then
  warn "known warning budget overruns detected: ${warning_overruns}"
fi
if [ "$budget_expired" -gt 0 ]; then
  warn "warning budget entries past expiration date: ${budget_expired}"
fi

ok "runtime smoke passed"
