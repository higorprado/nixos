#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/validate-host.sh [--host <name>]

Environment:
  VALIDATE_HOST_TARGET=<name>
    Host target under nixosConfigurations to validate.
    Default: predator
EOF
  exit 0
fi

host_target="${VALIDATE_HOST_TARGET:-predator}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      host_target="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [ -z "$host_target" ]; then
  echo "Host target can not be empty." >&2
  exit 2
fi

is_nixos=0
if [ -f /etc/os-release ] && grep -q '^ID=nixos$' /etc/os-release; then
  is_nixos=1
fi
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
flake_ref="path:$repo_root#$host_target"

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
    echo "target=$host_target"
  } >"$cache_file" 2>/dev/null || return 0
  chmod 0644 "$cache_file" 2>/dev/null || true
}

echo "[validate] flake metadata"
nixf flake metadata >/dev/null

echo "[validate] build NixOS toplevel derivation (works on non-NixOS too)"
nixf build --no-link "path:$repo_root#nixosConfigurations.${host_target}.config.system.build.toplevel"

if [ "$is_nixos" -eq 1 ]; then
  echo "[validate] NixOS host detected, running nixos-rebuild test for $host_target"
  sudo nixos-rebuild test --flake "$flake_ref"
else
  echo "[validate] non-NixOS host detected; skipping nixos-rebuild test"
  echo "[validate] on target NixOS host, run:"
  echo "  sudo nixos-rebuild test --flake $flake_ref"
fi

write_validate_cache
