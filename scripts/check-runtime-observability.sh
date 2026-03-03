#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF'
Usage:
  scripts/check-runtime-observability.sh [--artifact-dir <dir>]
EOF
}

scope="runtime-observability"
artifact_dir=""
while [ "$#" -gt 0 ]; do
  case "$1" in
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

require_cmds "$scope" "dmesg" "journalctl"

if [ -z "$artifact_dir" ]; then
  artifact_dir="$(mktemp_dir_scoped runtime-observability)"
else
  mkdir -p "$artifact_dir"
fi

kernel_journal_log="$artifact_dir/kernel-journal.log"
dmesg_log="$artifact_dir/dmesg.log"
summary="$artifact_dir/summary.txt"

set +e
journalctl -k -p 0..4 --no-pager -n 200 >"$kernel_journal_log" 2>&1
jc=$?
dmesg --level=err,warn >"$dmesg_log" 2>&1
dc=$?
set -e

{
  echo "journalctl_kernel_exit_code=$jc"
  echo "dmesg_exit_code=$dc"
  if [ "$jc" -eq 0 ]; then
    echo "selected_source=journalctl-kernel"
  elif [ "$dc" -eq 0 ]; then
    echo "selected_source=dmesg"
  else
    echo "selected_source=none"
  fi
} >"$summary"

if [ "$jc" -eq 0 ]; then
  log_ok "$scope" "kernel signal accessible via journalctl (see $summary)"
  exit 0
fi

if [ "$dc" -eq 0 ]; then
  log_ok "$scope" "kernel signal accessible via dmesg fallback (see $summary)"
  exit 0
fi

log_fail "$scope" "neither journalctl -k nor dmesg is accessible (see $summary)"
exit 1
