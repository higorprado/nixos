#!/usr/bin/env bash
set -euo pipefail

is_nixos=0
if [ -f /etc/os-release ] && grep -q '^ID=nixos$' /etc/os-release; then
  is_nixos=1
fi
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
flake_ref="path:$repo_root#predator"

nixf() {
  nix \
    --extra-experimental-features "nix-command flakes" \
    --option warn-dirty false \
    "$@"
}

write_validate_cache() {
  local stamp_user cache_file
  stamp_user="${SUDO_USER:-${USER:-unknown}}"
  cache_file="${TMPDIR:-/tmp}/nixos-validate-host-last-ok-${stamp_user}.txt"
  {
    echo "timestamp=$(date --iso-8601=seconds)"
    echo "repo=$(pwd)"
    echo "host=$(hostname)"
  } >"$cache_file" 2>/dev/null || return 0
  chmod 0644 "$cache_file" 2>/dev/null || true
}

echo "[validate] flake metadata"
nixf flake metadata >/dev/null

echo "[validate] build NixOS toplevel derivation (works on non-NixOS too)"
nixf build --no-link "path:$repo_root#nixosConfigurations.predator.config.system.build.toplevel"

if [ "$is_nixos" -eq 1 ]; then
  echo "[validate] NixOS host detected, running nixos-rebuild test"
  sudo nixos-rebuild test --flake "$flake_ref"
else
  echo "[validate] non-NixOS host detected; skipping nixos-rebuild test"
  echo "[validate] on target NixOS host, run:"
  echo "  sudo nixos-rebuild test --flake $flake_ref"
fi

write_validate_cache
