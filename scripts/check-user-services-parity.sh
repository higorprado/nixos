#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/check-user-services-parity.sh

Environment:
  STRICT_USER_SERVICES_PARITY=1
    Exit non-zero when parity drift is found in checked user units.
  USER_SERVICES_PARITY_EXTRA_UNITS="unit1.service unit2.service"
    Optional extra units to check on this host.
  WARN_LOCAL_UNIT_WANTS=1
    Warn when enabled wants symlinks point to local unit files.
    Default is 0 (info only) to reduce false positives on transitional hosts.
EOF
  exit 0
fi

strict="${STRICT_USER_SERVICES_PARITY:-0}"
warn_local_unit_wants="${WARN_LOCAL_UNIT_WANTS:-0}"
fail=0

units=(
  "keyrs.service"
  "awww-daemon.service"
  "dms-awww.service"
  "gtk-layer.service"
  "dotfiles-sync.service"
)

if [ -n "${USER_SERVICES_PARITY_EXTRA_UNITS:-}" ]; then
  # Accept whitespace or comma-separated unit names.
  extra_units_normalized="$(printf '%s' "${USER_SERVICES_PARITY_EXTRA_UNITS}" | tr ',' ' ')"
  # shellcheck disable=SC2206
  extra_units=( $extra_units_normalized )
  for unit in "${extra_units[@]}"; do
    [ -n "$unit" ] || continue
    units+=("$unit")
  done
fi

check_has() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -q "$pattern" "$file"; then
    echo "[services-parity] warn: $label missing in $file"
    fail=1
  fi
}

choose_unit_file() {
  local unit="$1"
  local local_file="$HOME/.config/systemd/user/$unit"
  local fragment=""

  fragment="$(systemctl --user show -p FragmentPath --value "$unit" 2>/dev/null || true)"

  if [ -n "$fragment" ] && [ -f "$fragment" ]; then
    echo "$fragment"
    return 0
  fi

  if [ -f "$local_file" ]; then
    echo "$local_file"
    return 0
  fi

  return 1
}

echo "[services-parity] checking local user unit files"
for unit in "${units[@]}"; do
  if ! f="$(choose_unit_file "$unit")"; then
    echo "[services-parity] info: $unit has no readable fragment/local file"
    continue
  fi
  echo "[services-parity] info: checking $unit from $f"

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
      check_has "$f" '^Restart=on-failure$' "Restart=on-failure"
      check_has "$f" '^RestartSec=2$' "RestartSec=2"
      ;;
    dms-awww.service)
      check_has "$f" '^After=graphical-session\.target$' "After=graphical-session.target"
      check_has "$f" '^After=awww-daemon\.service$' "After=awww-daemon.service"
      check_has "$f" '^Requires=awww-daemon\.service$' "Requires=awww-daemon.service"
      check_has "$f" '^Restart=on-failure$' "Restart=on-failure"
      check_has "$f" '^RestartSec=5$' "RestartSec=5"
      ;;
    gtk-layer.service)
      check_has "$f" '^Type=oneshot$' "Type=oneshot"
      ;;
    dotfiles-sync.service)
      check_has "$f" '^After=network-online\.target$' "After=network-online.target"
      check_has "$f" '^Type=oneshot$' "Type=oneshot"
      ;;
    backup-*.service)
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
        if [ "$warn_local_unit_wants" = "1" ]; then
          echo "[services-parity] warn: enabled unit symlink points to local unit file: $link -> $target"
          fail=1
        else
          echo "[services-parity] info: local unit symlink detected (warn disabled): $link -> $target"
        fi
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
