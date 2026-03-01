#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/check-runtime-config-parity.sh

Environment:
  STRICT_RUNTIME_MUTABLE_PARITY=1
    Treat mutable-target drift as failure.
  MUTABLE_RUNTIME_WARN_ALLOWLIST="path1:path2"
    Mutable host paths allowed to drift without WARN status.
    Default includes known copy-once mutable runtime files.

Checks tracked runtime config files against current host files.
EOF
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail=0
warn=0
strict_mutable="${STRICT_RUNTIME_MUTABLE_PARITY:-0}"
default_mutable_allowlist="$HOME/.config/DankMaterialShell/settings.json:$HOME/.config/keyrs/config.toml"
mutable_warn_allowlist="${MUTABLE_RUNTIME_WARN_ALLOWLIST:-$default_mutable_allowlist}"

path_is_allowlisted() {
  local path="$1"
  IFS=':' read -r -a allow_paths <<< "$mutable_warn_allowlist"
  for allowed in "${allow_paths[@]}"; do
    [ -n "$allowed" ] || continue
    if [ "$path" = "$allowed" ]; then
      return 0
    fi
  done
  return 1
}

check_pair() {
  local tracked="$1"
  local host="$2"
  local mode="$3"

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
    if [ "$mode" = "mutable" ] && [ "$strict_mutable" != "1" ]; then
      if path_is_allowlisted "$host"; then
        echo "[runtime-parity] info: mutable content drift accepted by allowlist"
      else
        echo "[runtime-parity] warn: mutable content drift detected"
        warn=1
      fi
    else
      echo "[runtime-parity] fail: content mismatch"
      fail=1
    fi
    echo "  tracked: $tracked"
    echo "  host:    $host"
  fi
}

check_pair "$repo_root/config/apps/niri/config.kdl" "$HOME/.config/niri/config.kdl" "immutable"
check_pair "$repo_root/config/apps/dms/settings.json" "$HOME/.config/DankMaterialShell/settings.json" "mutable"
check_pair "$repo_root/config/apps/keyrs/config.toml" "$HOME/.config/keyrs/config.toml" "mutable"
check_pair "$repo_root/config/apps/mpd/mpd.conf" "$HOME/.config/mpd/mpd.conf" "immutable"

if [ "$fail" -ne 0 ]; then
  exit 1
fi

if [ "$warn" -ne 0 ]; then
  echo "[runtime-parity] WARN: mutable runtime drift detected"
  exit 0
fi
