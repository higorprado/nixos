#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/run-production-remediation-gates.sh [--boot current|previous] [--since <time>] [--output-dir <dir>] [--host <host>] [--user <hm-user>] [--allow-dirty]
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

boot="current"
since=""
host="predator"
hm_user=""
output_dir=""
allow_dirty=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --boot)
      boot="${2:-}"
      shift 2
      ;;
    --since)
      since="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --host)
      host="${2:-}"
      shift 2
      ;;
    --user)
      hm_user="${2:-}"
      shift 2
      ;;
    --allow-dirty)
      allow_dirty=1
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

if [ -z "$output_dir" ]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  output_dir="$repo_root/reports/production-remediation-$ts/gates"
fi
mkdir -p "$output_dir"

if [ "$allow_dirty" -ne 1 ]; then
  dirty="$(git status --porcelain=v1 || true)"
  if [ -n "$dirty" ]; then
    echo "[run-production-remediation-gates] fail: dirty worktree (use --allow-dirty to override)" >&2
    printf '%s\n' "$dirty" >"$output_dir/dirty-worktree.txt"
    exit 1
  fi
fi

status_tsv="$output_dir/check-status.tsv"
printf 'check\texit_code\tartifact\n' >"$status_tsv"

run_check() {
  local name="$1"
  local log="$2"
  shift 2
  set +e
  "$@" >"$log" 2>&1
  local code=$?
  set -e
  printf '%s\t%s\t%s\n' "$name" "$code" "$log" >>"$status_tsv"
  return 0
}

session_args=(scripts/check-session-log-health.sh --boot "$boot" --output "$output_dir/session-log-health.tsv")
if [ -n "$since" ]; then
  session_args+=(--since "$since")
fi
run_check check-session-log-health "$output_dir/check-session-log-health.log" "${session_args[@]}"

home_args=(scripts/check-home-profile-drift.sh --host "$host" --artifact-dir "$output_dir/home-profile-drift")
if [ -n "$hm_user" ]; then
  home_args+=(--user "$hm_user")
fi
run_check check-home-profile-drift "$output_dir/check-home-profile-drift.log" "${home_args[@]}"

units_args=(scripts/check-user-units-coverage.sh --host "$host" --artifact-dir "$output_dir/user-units-coverage")
if [ -n "$hm_user" ]; then
  units_args+=(--user "$hm_user")
fi
run_check check-user-units-coverage "$output_dir/check-user-units-coverage.log" "${units_args[@]}"

run_check check-runtime-observability "$output_dir/check-runtime-observability.log" \
  scripts/check-runtime-observability.sh --artifact-dir "$output_dir/runtime-observability"

run_check check-repo-public-safety "$output_dir/check-repo-public-safety.log" \
  scripts/check-repo-public-safety.sh

fails="$(awk -F '\t' 'NR>1 && $2 != "0" {c++} END {print c+0}' "$status_tsv")"
if [ "$fails" -gt 0 ]; then
  echo "[run-production-remediation-gates] FAIL: $fails checks failed (see $status_tsv)"
  exit 1
fi

echo "[run-production-remediation-gates] PASS: all checks passed (see $status_tsv)"
