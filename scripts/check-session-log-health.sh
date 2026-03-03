#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF'
Usage:
  scripts/check-session-log-health.sh [--boot current|previous] [--since <time>] [--output <tsv>]

Environment:
  SESSION_LOG_PORTAL_PIDNS_MAX=<n>      # default: 5
  SESSION_LOG_PORTAL_INHIBIT_MAX=<n>    # default: 5
  SESSION_LOG_NM_P2P_MAX=<n>            # default: 0
EOF
}

scope="session-log-health"
boot="current"
since=""
output=""
portal_pidns_max="${SESSION_LOG_PORTAL_PIDNS_MAX:-5}"
portal_inhibit_max="${SESSION_LOG_PORTAL_INHIBIT_MAX:-5}"
nm_p2p_max="${SESSION_LOG_NM_P2P_MAX:-0}"

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
    --output)
      output="${2:-}"
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

case "$boot" in
  current|previous) ;;
  *)
    log_fail "$scope" "invalid --boot value: $boot (use current|previous)"
    exit 2
    ;;
esac

require_cmds "$scope" "journalctl" "rg" "sed" "wc"

if [ -z "$output" ]; then
  output="$(mktemp_file_scoped session-log-health)"
fi

tmp_all="$(mktemp_file_scoped session-log-all)"

sys_args=(journalctl -p 0..4 --no-pager)
usr_args=(journalctl --user -p 0..4 --no-pager)
if [ -n "$since" ]; then
  sys_args+=(--since "$since")
  usr_args+=(--since "$since")
else
  if [ "$boot" = "previous" ]; then
    sys_args+=(-b -1)
    usr_args+=(-b -1)
  else
    sys_args+=(-b)
    usr_args+=(-b)
  fi
fi

sys_log="$(mktemp_file_scoped session-log-system)"
usr_log="$(mktemp_file_scoped session-log-user)"
trap 'rm -f "$tmp_all" "$sys_log" "$usr_log"' EXIT

set +e
"${sys_args[@]}" >"$sys_log" 2>&1
sys_code=$?
"${usr_args[@]}" >"$usr_log" 2>&1
usr_code=$?
set -e

if [ "$sys_code" -ne 0 ] && [ "$usr_code" -ne 0 ]; then
  log_fail "$scope" "unable to read both system and user logs"
  log_warn "$scope" "system journal error:"
  sed -n '1,8p' "$sys_log" >&2 || true
  log_warn "$scope" "user journal error:"
  sed -n '1,8p' "$usr_log" >&2 || true
  exit 1
fi

cat "$sys_log" "$usr_log" >"$tmp_all"

count_pattern() {
  local pattern="$1"
  (rg -F "$pattern" "$tmp_all" || true) | wc -l | tr -d ' '
}

status=0
{
  printf 'id\tpattern\tcount\tlimit\tstatus\n'
  while IFS=$'\t' read -r id pattern limit; do
    c="$(count_pattern "$pattern")"
    s="pass"
    if [ "$c" -gt "$limit" ]; then
      s="fail"
      status=1
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$pattern" "$c" "$limit" "$s"
  done <<EOF
P001	dsearch.service: Failed with result 'exit-code'	0
P002	Configuration file /etc/systemd/user/dsearch.service is marked executable	0
P003	Theme parsing error:	0
P004	wp-state: failed to create directory /var/empty/.local/state/wireplumber	0
P005	Realtime error: Could not get pidns	$portal_pidns_max
P006	A backend call failed: Inhibiting other than idle not supported	$portal_inhibit_max
P007	Detected another IPv4 mDNS stack running on this host	0
P008	Unknown group "netdev" in message bus configuration file	0
P009	gkr-pam: unable to locate daemon control file	0
P010	error setting IPv4 forwarding to '1': Resource temporarily unavailable	$nm_p2p_max
EOF
} >"$output"

if [ "$status" -ne 0 ]; then
  log_fail "$scope" "threshold violations found (see $output)"
  exit 1
fi

log_ok "$scope" "no threshold violations (see $output)"
