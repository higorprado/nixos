#!/usr/bin/env bash
set -euo pipefail

out_dir="${1:-./.migration-audit}"
mkdir -p "$out_dir"

ts="$(date +%Y%m%d-%H%M%S)"
prefix="$out_dir/$ts"

echo "[audit] writing baseline snapshot to $prefix.*"

{
  echo "# format-version: 2"
  echo
  echo "# system"
  uname -a
  echo
  cat /etc/os-release || true
} > "$prefix.system.txt"

{
  echo "# format-version: 2"
  echo
  echo "# enabled system services"
  systemctl list-unit-files --type=service --state=enabled --no-pager || true
  echo
  echo "# enabled user services"
  systemctl --user list-unit-files --type=service --state=enabled --no-pager || true
  echo
  echo "# enabled user timers"
  systemctl --user list-unit-files --type=timer --state=enabled --no-pager || true
} > "$prefix.units.txt"

{
  echo "# format-version: 2"
  echo
  echo "# user and groups"
  id
  echo
  getent group | rg 'docker|wheel|audio|video|networkmanager|input|uinput|rfkill|linuwu_sense' || true
} > "$prefix.identity.txt"

{
  echo "# format-version: 2"
  echo
  echo "# dns"
  cat /etc/resolv.conf || true
  echo
  resolvectl dns || true
  echo
  resolvectl domain || true
  echo
  nmcli general status || true
  echo
  nmcli --terse --fields NAME,UUID,TYPE,DEVICE connection show --active || true
} > "$prefix.dns.txt"

{
  echo "# format-version: 2"
  echo
  echo "# kernel modules"
  lsmod | rg 'linuwu|acer|nvidia|platform_profile' || true
  echo
  echo "# platform profile"
  cat /sys/firmware/acpi/platform_profile 2>/dev/null || true
  cat /sys/firmware/acpi/platform_profile_choices 2>/dev/null || true
} > "$prefix.hardware.txt"

{
  echo "# format-version: 2"
  echo
  echo "# session critical user units"
  for unit in dms.service keyrs.service awww-daemon.service dms-awww.service mpd.service; do
    echo "## $unit"
    systemctl --user is-enabled "$unit" 2>&1 || true
    systemctl --user show "$unit" \
      -p ActiveState \
      -p SubState \
      -p UnitFileState \
      -p FragmentPath \
      -p ExecStart \
      -p EnvironmentFiles 2>&1 || true
    pid="$(systemctl --user show "$unit" -p MainPID --value 2>/dev/null || true)"
    if [ -n "$pid" ] && [ "$pid" -gt 0 ] 2>/dev/null; then
      echo "MainPID=$pid"
      readlink -f "/proc/$pid/exe" 2>/dev/null || true
    fi
    echo
  done
} > "$prefix.session-services.txt"

echo "[audit] done"
