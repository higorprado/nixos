#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

expected="$repo_root/config/apps/logid/logid.cfg"
current="/etc/logid.cfg"

if [ ! -f "$expected" ]; then
  echo "[logid-parity] fail: expected file missing: $expected"
  exit 1
fi

if [ ! -f "$current" ]; then
  echo "[logid-parity] warn: current host has no $current; skipping parity check"
  exit 0
fi

if diff -u "$expected" "$current" >/tmp/logid-parity.diff 2>&1; then
  echo "[logid-parity] ok: $current matches config/apps/logid/logid.cfg"
  exit 0
fi

echo "[logid-parity] fail: $current differs from config/apps/logid/logid.cfg"
cat /tmp/logid-parity.diff
exit 1
