#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/check-user-services-parity.sh

Environment:
  STRICT_USER_SERVICES_PARITY=1
    Exit non-zero when parity drift is found in checked user units.
EOF
  exit 0
fi

strict="${STRICT_USER_SERVICES_PARITY:-0}"
fail=0

units=(
  "keyrs.service"
  "awww-daemon.service"
  "dms-awww.service"
  "gtk-layer.service"
  "dotfiles-sync.service"
  "backup-restic-cerebelo.service"
  "backup-rsync-cerebelo.service"
)

check_has() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -q "$pattern" "$file"; then
    echo "[services-parity] warn: $label missing in $file"
    fail=1
  fi
}

echo "[services-parity] checking local user unit files"
for unit in "${units[@]}"; do
  f="$HOME/.config/systemd/user/$unit"
  if [ ! -f "$f" ]; then
    echo "[services-parity] info: $unit not present at $f"
    continue
  fi

  legacy="$(rg -n '/usr/local/bin|%h/\.local/bin|%h/\.cargo/bin|/usr/bin/dms|/usr/bin/awww-daemon' "$f" || true)"
  if [ -n "$legacy" ]; then
    echo "[services-parity] warn: legacy path patterns in $f"
    printf '%s\n' "$legacy"
    fail=1
  fi

  case "$unit" in
    keyrs.service)
      check_has "$f" '^After=graphical-session\.target$' "After=graphical-session.target"
      check_has "$f" '^Restart=on-failure$' "Restart=on-failure"
      check_has "$f" '^RestartSec=2$' "RestartSec=2"
      ;;
    awww-daemon.service)
      check_has "$f" '^After=graphical-session\.target$' "After=graphical-session.target"
      check_has "$f" '^Restart=always$' "Restart=always"
      ;;
    dms-awww.service)
      check_has "$f" '^After=dms\.service awww-daemon\.service$' "After=dms.service awww-daemon.service"
      check_has "$f" '^Requires=awww-daemon\.service$' "Requires=awww-daemon.service"
      check_has "$f" '^Restart=always$' "Restart=always"
      ;;
    gtk-layer.service)
      check_has "$f" '^Type=oneshot$' "Type=oneshot"
      ;;
    dotfiles-sync.service)
      check_has "$f" '^After=network-online\.target$' "After=network-online.target"
      check_has "$f" '^Type=oneshot$' "Type=oneshot"
      ;;
    backup-restic-cerebelo.service|backup-rsync-cerebelo.service)
      check_has "$f" '^After=network-online\.target$' "After=network-online.target"
      check_has "$f" '^Type=oneshot$' "Type=oneshot"
      check_has "$f" '^NoNewPrivileges=true$' "NoNewPrivileges=true"
      ;;
  esac
done

echo "[services-parity] checking enabled symlinks that target local unit files"
for wants_dir in "$HOME/.config/systemd/user/default.target.wants" "$HOME/.config/systemd/user/graphical-session.target.wants"; do
  [ -d "$wants_dir" ] || continue
  while IFS= read -r link; do
    target="$(readlink -f "$link" 2>/dev/null || true)"
    case "$target" in
      "$HOME/.config/systemd/user/"*)
        echo "[services-parity] warn: enabled unit symlink points to local unmanaged file: $link -> $target"
        fail=1
        ;;
    esac
  done < <(find "$wants_dir" -maxdepth 1 -type l 2>/dev/null | sort)
done

if [ "$fail" -eq 1 ]; then
  if [ "$strict" = "1" ]; then
    echo "[services-parity] FAIL: parity drift found and STRICT_USER_SERVICES_PARITY=1"
    exit 1
  fi
  echo "[services-parity] WARN: parity drift found (non-strict mode)"
  exit 0
fi

echo "[services-parity] ok: no parity drift detected in checked user units"
