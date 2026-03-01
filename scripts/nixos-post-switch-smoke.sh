#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/nixos-post-switch-smoke.sh

Environment:
  SMOKE_EXTRA_USER_TIMERS="timer1.timer timer2.timer"
    Optional extra user timers to verify.
  SMOKE_EXTRA_DOTFILES="path1:path2"
    Optional extra files to verify.
EOF
  exit 0
fi

fail() {
  echo "[smoke][fail] $*" >&2
  exit 1
}

warn() {
  echo "[smoke][warn] $*" >&2
}

ok() {
  echo "[smoke][ok] $*"
}

if [ "$(id -u)" -eq 0 ]; then
  fail "run as regular user (not root) so user services can be checked"
fi

if ! [ -f /etc/os-release ] || ! grep -q '^ID=nixos$' /etc/os-release; then
  fail "this script must run on a NixOS host"
fi

echo "[smoke] system generation"
sudo nixos-rebuild list-generations | tail -n 5

echo "[smoke] user groups"
id

echo "[smoke] systemd-resolved"
if resolvectl status >/dev/null; then
  ok "resolvectl responds"
else
  fail "resolvectl failed"
fi

echo "[smoke] key system units"
for unit in NetworkManager.service systemd-resolved.service greetd.service; do
  if systemctl is-enabled "$unit" >/dev/null 2>&1; then
    ok "$unit is enabled"
  else
    warn "$unit is not enabled"
  fi
done

echo "[smoke] key user units"
for unit in keyrs.service awww-daemon.service dms-awww.service; do
  if systemctl --user is-enabled "$unit" >/dev/null 2>&1; then
    ok "$unit is enabled"
  else
    warn "$unit is not enabled"
  fi
  fragment="$(systemctl --user show -p FragmentPath --value "$unit" 2>/dev/null || true)"
  case "$fragment" in
    /nix/store/*|/etc/systemd/user/*|/run/current-system/*)
      ok "$unit fragment is declarative: $fragment"
      ;;
    "")
      warn "$unit fragment path unavailable"
      ;;
    *)
      warn "$unit fragment may be unmanaged: $fragment"
      ;;
  esac
done

echo "[smoke] timer units"
timers=("dotfiles-sync.timer")
if [ -n "${SMOKE_EXTRA_USER_TIMERS:-}" ]; then
  # Accept whitespace or comma-separated timer names.
  timers_normalized="$(printf '%s' "${SMOKE_EXTRA_USER_TIMERS}" | tr ',' ' ')"
  # shellcheck disable=SC2206
  extra_timers=( $timers_normalized )
  for timer in "${extra_timers[@]}"; do
    [ -n "$timer" ] || continue
    timers+=("$timer")
  done
fi
for unit in "${timers[@]}"; do
  if systemctl --user is-enabled "$unit" >/dev/null 2>&1; then
    ok "$unit is enabled"
  else
    warn "$unit is not enabled"
  fi
done

echo "[smoke] key binaries"
for bin in keyrs dms-awww; do
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin found at $(command -v "$bin")"
  else
    warn "$bin not found in PATH"
  fi
done

echo "[smoke] managed dotfiles"
dotfiles=(
  "$HOME/.config/ghostty/config"
  "$HOME/.config/direnv/direnvrc"
)
if [ -n "${SMOKE_EXTRA_DOTFILES:-}" ]; then
  IFS=':' read -r -a extra_dotfiles <<< "${SMOKE_EXTRA_DOTFILES}"
  for path in "${extra_dotfiles[@]}"; do
    [ -n "$path" ] || continue
    dotfiles+=("$path")
  done
fi
for file in "${dotfiles[@]}"; do
  if [ -e "$file" ]; then
    ok "$file exists"
  else
    warn "$file missing"
  fi
done

echo "[smoke] completed"
