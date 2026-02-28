#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/check-runtime-config-parity.sh

Checks tracked runtime config files against current host files.
EOF
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail=0

check_pair() {
  local tracked="$1"
  local host="$2"

  if [ ! -f "$tracked" ]; then
    echo "[runtime-parity] fail: tracked file missing: $tracked"
    fail=1
    return
  fi

  if [ ! -f "$host" ]; then
    echo "[runtime-parity] fail: host file missing: $host"
    fail=1
    return
  fi

  if cmp -s "$tracked" "$host"; then
    echo "[runtime-parity] ok: $host matches $(basename "$tracked")"
  else
    echo "[runtime-parity] fail: content mismatch"
    echo "  tracked: $tracked"
    echo "  host:    $host"
    fail=1
  fi
}

check_pair "$repo_root/config/apps/niri/config.kdl" "$HOME/.config/niri/config.kdl"
check_pair "$repo_root/config/apps/dms/settings.json" "$HOME/.config/DankMaterialShell/settings.json"
check_pair "$repo_root/config/apps/keyrs/config.toml" "$HOME/.config/keyrs/config.toml"
check_pair "$repo_root/config/apps/mpd/mpd.conf" "$HOME/.config/mpd/mpd.conf"

if [ "$fail" -ne 0 ]; then
  exit 1
fi
