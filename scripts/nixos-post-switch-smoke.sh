#!/usr/bin/env bash
set -euo pipefail

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
resolvectl status >/dev/null && ok "resolvectl responds" || fail "resolvectl failed"

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
for unit in backup-restic-cerebelo.timer backup-rsync-cerebelo.timer dotfiles-sync.timer; do
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
for file in \
  "$HOME/.config/ghostty/config" \
  "$HOME/.config/direnv/direnvrc" \
  "$HOME/.config/claude/CLAUDE.md" \
  "$HOME/.config/claude/mcp_servers.json" \
  "$HOME/.config/crush/crush.json"
do
  if [ -e "$file" ]; then
    ok "$file exists"
  else
    warn "$file missing"
  fi
done

echo "[smoke] completed"
