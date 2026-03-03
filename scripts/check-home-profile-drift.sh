#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF'
Usage:
  scripts/check-home-profile-drift.sh [--host <host>] [--user <hm-user>] [--artifact-dir <dir>]

Environment:
  HOME_PROFILE_DRIFT_HOST=<host>    # default: predator
  HOME_PROFILE_DRIFT_USER=<user>    # optional override
EOF
}

scope="home-profile-drift"

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
      log_fail "$scope" "unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

require_cmds "$scope" "head" "nix" "readlink" "sed" "systemctl"

if [ -z "$artifact_dir" ]; then
  artifact_dir="$(mktemp_dir_scoped home-profile-drift)"
else
  mkdir -p "$artifact_dir"
fi

nixf() {
  nix --extra-experimental-features "nix-command flakes" --option warn-dirty false "$@"
}

if [ -z "$hm_user" ]; then
  hm_user="$(nixf eval --raw "path:$REPO_ROOT#nixosConfigurations.${host}.config.custom.user.name" 2>/dev/null || true)"
fi

if [ -z "$hm_user" ]; then
  log_fail "$scope" "unable to determine Home Manager user"
  exit 1
fi

expected_home="$(nixf build --no-link --print-out-paths "path:$REPO_ROOT#nixosConfigurations.${host}.config.home-manager.users.${hm_user}.home.path")"
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
  log_fail "$scope" "unable to determine active Home Manager generation for $hm_user"
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
  log_fail "$scope" "unable to resolve active home-path from $active_generation"
  exit 1
fi

printf '%s\n' "$active_home_path" >"$artifact_dir/active-home-path.txt"

if [ "$active_home_path" = "$expected_home" ]; then
  log_ok "$scope" "active home-path matches expected ($active_home_path)"
  exit 0
fi

set +e
nixf store diff-closures "$active_home_path" "$expected_home" >"$artifact_dir/home-path-closure-diff.log" 2>&1
_diff_code=$?
set -e

log_fail "$scope" "active home-path differs from expected"
log_warn "$scope" "active:   $active_home_path"
log_warn "$scope" "expected: $expected_home"
log_warn "$scope" "diff:     $artifact_dir/home-path-closure-diff.log"
exit 1
