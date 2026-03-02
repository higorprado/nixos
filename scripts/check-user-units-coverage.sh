#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/check-user-units-coverage.sh [--host <host>] [--user <hm-user>] [--allowlist <path>] [--artifact-dir <dir>] [--include-emacs]

Environment:
  USER_UNITS_COVERAGE_HOST=<host>      # default: predator
  USER_UNITS_COVERAGE_USER=<user>      # optional override
  USER_UNITS_COVERAGE_ALLOWLIST=<path> # default: scripts/user-units-coverage-allowlist.txt
  USER_UNITS_INCLUDE_EMACS=1           # default: 0 (emacs.* excluded)
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

host="${USER_UNITS_COVERAGE_HOST:-predator}"
hm_user="${USER_UNITS_COVERAGE_USER:-}"
allowlist="${USER_UNITS_COVERAGE_ALLOWLIST:-$repo_root/scripts/user-units-coverage-allowlist.txt}"
artifact_dir=""
include_emacs="${USER_UNITS_INCLUDE_EMACS:-0}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      host="${2:-}"
      shift 2
      ;;
    --user)
      hm_user="${2:-}"
      shift 2
      ;;
    --allowlist)
      allowlist="${2:-}"
      shift 2
      ;;
    --artifact-dir)
      artifact_dir="${2:-}"
      shift 2
      ;;
    --include-emacs)
      include_emacs=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "[user-units-coverage] fail: jq is required for JSON parsing" >&2
  exit 1
fi

if [ -z "$artifact_dir" ]; then
  artifact_dir="$(mktemp -d "${TMPDIR:-/tmp}/user-units-coverage-XXXXXX")"
else
  mkdir -p "$artifact_dir"
fi

nixf() {
  nix --extra-experimental-features "nix-command flakes" --option warn-dirty false "$@"
}

if [ -z "$hm_user" ]; then
  hm_user="$(nixf eval --raw "path:$repo_root#nixosConfigurations.${host}.config.custom.user.name" 2>/dev/null || true)"
fi
if [ -z "$hm_user" ]; then
  echo "[user-units-coverage] fail: unable to determine Home Manager user" >&2
  exit 1
fi

enabled_file="$artifact_dir/enabled-user-units.txt"
declared_file="$artifact_dir/declared-user-units.txt"
result_file="$artifact_dir/user-units-coverage.csv"

systemctl --user list-unit-files --state=enabled --no-legend --no-pager \
  | awk '{print $1}' \
  | sed '/^$/d' \
  | sort -u >"$enabled_file"

if [ ! -s "$enabled_file" ]; then
  echo "[user-units-coverage] fail: no enabled user units discovered" >&2
  exit 1
fi

collect_declared() {
  local attr="$1"
  local ext="$2"
  set +e
  nixf eval --json "path:$repo_root#nixosConfigurations.${host}.${attr}" --apply builtins.attrNames \
    | jq -r '.[]' \
    | while IFS= read -r name; do
        [ -n "$name" ] || continue
        case "$name" in
          *.service|*.socket|*.timer) printf '%s\n' "$name" ;;
          *) printf '%s.%s\n' "$name" "$ext" ;;
        esac
      done
  local code=$?
  set -e
  return "$code"
}

{
  collect_declared "config.systemd.user.services" "service" || true
  collect_declared "config.systemd.user.sockets" "socket" || true
  collect_declared "config.systemd.user.timers" "timer" || true
  collect_declared "config.home-manager.users.${hm_user}.systemd.user.services" "service" || true
  collect_declared "config.home-manager.users.${hm_user}.systemd.user.sockets" "socket" || true
  collect_declared "config.home-manager.users.${hm_user}.systemd.user.timers" "timer" || true
} | sed '/^$/d' | sort -u >"$declared_file"

touch "$allowlist"
allowed_file="$artifact_dir/allowlisted-user-units.txt"
grep -Ev '^\s*#|^\s*$' "$allowlist" | sed '/^$/d' | sort -u >"$allowed_file" || true

status=0
{
  printf 'unit,status,reason\n'
  while IFS= read -r unit; do
    [ -n "$unit" ] || continue

    if [ "$include_emacs" != "1" ] && [[ "$unit" == emacs.* ]]; then
      printf '%s,%s,%s\n' "$unit" "excluded-emacs" "excluded-by-policy"
      continue
    fi

    if rg -Fx "$unit" "$declared_file" >/dev/null 2>&1; then
      printf '%s,%s,%s\n' "$unit" "covered" "declared-in-evaluated-config"
    elif rg -Fx "$unit" "$allowed_file" >/dev/null 2>&1; then
      printf '%s,%s,%s\n' "$unit" "allowlisted" "implicit-system-unit"
    else
      printf '%s,%s,%s\n' "$unit" "fail" "enabled-but-not-declared-or-allowlisted"
      status=1
    fi
  done <"$enabled_file"
} >"$result_file"

if [ "$status" -ne 0 ]; then
  echo "[user-units-coverage] FAIL: undeclared enabled units found (see $result_file)"
  exit 1
fi

echo "[user-units-coverage] PASS: all enabled user units are covered/allowlisted (see $result_file)"
