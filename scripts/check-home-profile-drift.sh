#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/check-home-profile-drift.sh [--host <host>] [--user <hm-user>] [--artifact-dir <dir>]

Environment:
  HOME_PROFILE_DRIFT_HOST=<host>    # default: predator
  HOME_PROFILE_DRIFT_USER=<user>    # optional override
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

host="${HOME_PROFILE_DRIFT_HOST:-predator}"
hm_user="${HOME_PROFILE_DRIFT_USER:-}"
artifact_dir=""

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
    --artifact-dir)
      artifact_dir="${2:-}"
      shift 2
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

if [ -z "$artifact_dir" ]; then
  artifact_dir="$(mktemp -d "${TMPDIR:-/tmp}/home-profile-drift-XXXXXX")"
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
  echo "[home-profile-drift] fail: unable to determine Home Manager user" >&2
  exit 1
fi

expected_home="$(nixf build --no-link --print-out-paths "path:$repo_root#nixosConfigurations.${host}.config.home-manager.users.${hm_user}.home.path")"
printf '%s\n' "$expected_home" >"$artifact_dir/expected-home-path.txt"

active_profile=""
active_generation=""
active_source=""

# Prefer the generation wired into the system home-manager service, which is the
# authoritative activation path on NixOS module-managed setups.
hm_service="home-manager-${hm_user}.service"
if systemctl cat "$hm_service" >/dev/null 2>&1; then
  service_gen="$(systemctl cat "$hm_service" | sed -n 's#^ExecStart=.* \(/nix/store/[^ ]*-home-manager-generation\).*$#\1#p' | head -n1)"
  if [ -n "$service_gen" ] && [ -e "$service_gen" ]; then
    active_generation="$service_gen"
    active_source="system-service"
  fi
fi

# Fallback to profile symlink locations when service-backed generation is unavailable.
if [ -z "$active_generation" ]; then
  for candidate in \
    "$HOME/.local/state/nix/profiles/home-manager" \
    "/nix/var/nix/profiles/per-user/$hm_user/home-manager" \
    "/etc/profiles/per-user/$hm_user/home-manager"; do
    if [ -e "$candidate" ]; then
      active_profile="$candidate"
      active_generation="$(readlink -f "$candidate")"
      active_source="profile-link"
      break
    fi
  done
fi

if [ -z "$active_generation" ]; then
  echo "[home-profile-drift] fail: unable to determine active Home Manager generation for $hm_user" >&2
  exit 1
fi

printf '%s\n' "${active_source:-unknown}" >"$artifact_dir/active-generation-source.txt"
printf '%s\n' "$active_profile" >"$artifact_dir/active-home-profile-link.txt"
printf '%s\n' "$active_generation" >"$artifact_dir/active-home-generation.txt"

active_home_path=""
if [ -e "$active_generation/home-path" ]; then
  active_home_path="$(readlink -f "$active_generation/home-path")"
fi
if [ -z "$active_home_path" ] && [[ "$active_generation" == *"-home-manager-path" ]]; then
  active_home_path="$active_generation"
fi

if [ -z "$active_home_path" ]; then
  echo "[home-profile-drift] fail: unable to resolve active home-path from $active_generation" >&2
  exit 1
fi

printf '%s\n' "$active_home_path" >"$artifact_dir/active-home-path.txt"

if [ "$active_home_path" = "$expected_home" ]; then
  echo "[home-profile-drift] PASS: active home-path matches expected ($active_home_path)"
  exit 0
fi

set +e
nixf store diff-closures "$active_home_path" "$expected_home" >"$artifact_dir/home-path-closure-diff.log" 2>&1
_diff_code=$?
set -e

echo "[home-profile-drift] FAIL: active home-path differs from expected"
echo "[home-profile-drift] active:   $active_home_path"
echo "[home-profile-drift] expected: $expected_home"
echo "[home-profile-drift] diff:     $artifact_dir/home-path-closure-diff.log"
exit 1
