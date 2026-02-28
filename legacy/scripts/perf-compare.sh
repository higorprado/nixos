#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/perf-compare.sh [--strict] <old-perf-file> <new-perf-file>

Example:
  scripts/perf-compare.sh \
    .migration-audit/precutover-20260222-010636/perf-20260222-010637.txt \
    .migration-audit/precutover-20260222-010929/perf-20260222-010930.txt
EOF
}

strict=0
if [ "${1:-}" = "--strict" ]; then
  strict=1
  shift
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

old="$1"
new="$2"

[ -f "$old" ] || { echo "[perf-compare] missing file: $old" >&2; exit 1; }
[ -f "$new" ] || { echo "[perf-compare] missing file: $new" >&2; exit 1; }

num_norm() { printf '%s' "${1:-0}" | tr ',' '.'; }

get_load1() {
  sed -n '/^## uptime-load/{n;p;}' "$1" | awk -F'load average: ' '{print $2}' | cut -d',' -f1 | tr -d ' ' | tr ',' '.'
}

get_mem_used() { awk '/^Mem:/ {print $3; exit}' "$1"; }
get_mem_total() { awk '/^Mem:/ {print $2; exit}' "$1"; }
get_rss() { awk -v name="$2" '$2==name {print $4; exit}' "$1"; }
get_header() {
  local file="$1" key="$2"
  sed -n "s/^# ${key}: //p" "$file" | head -n1
}

to_mib() {
  v="$(num_norm "${1:-0}")"
  case "$v" in
    *Gi) awk -v x="${v%Gi}" 'BEGIN{printf "%.2f", x*1024}' ;;
    *Mi) awk -v x="${v%Mi}" 'BEGIN{printf "%.2f", x}' ;;
    *Ki) awk -v x="${v%Ki}" 'BEGIN{printf "%.2f", x/1024}' ;;
    *) awk -v x="$v" 'BEGIN{printf "%.2f", x}' ;;
  esac
}

old_load="$(get_load1 "$old")"
new_load="$(get_load1 "$new")"

old_mem_used="$(get_mem_used "$old")"
new_mem_used="$(get_mem_used "$new")"
old_mem_used_mib="$(to_mib "$old_mem_used")"
new_mem_used_mib="$(to_mib "$new_mem_used")"

old_dms="$(get_rss "$old" dms)"
new_dms="$(get_rss "$new" dms)"
old_qs="$(get_rss "$old" qs)"
new_qs="$(get_rss "$new" qs)"
old_keyrs="$(get_rss "$old" keyrs)"
new_keyrs="$(get_rss "$new" keyrs)"
old_mpd="$(get_rss "$old" mpd)"
new_mpd="$(get_rss "$new" mpd)"

delta_num() { awk -v a="$(num_norm "$1")" -v b="$(num_norm "$2")" 'BEGIN{printf "%.2f", b-a}'; }
delta_int() { awk -v a="${1:-0}" -v b="${2:-0}" 'BEGIN{printf "%d", b-a}'; }

delta_load="$(delta_num "$old_load" "$new_load")"
delta_mem_mib="$(delta_num "$old_mem_used_mib" "$new_mem_used_mib")"
delta_dms="$(delta_int "$old_dms" "$new_dms")"
delta_qs="$(delta_int "$old_qs" "$new_qs")"
delta_keyrs="$(delta_int "$old_keyrs" "$new_keyrs")"
delta_mpd="$(delta_int "$old_mpd" "$new_mpd")"

# Conservative thresholds for idle-ish snapshots.
max_load_delta="0.50"
max_mem_delta_mib="512.00"
max_dms_delta_kb="51200"
max_qs_delta_kb="102400"
max_keyrs_delta_kb="8192"
max_mpd_delta_kb="8192"

fail=0
check_threshold() {
  local label="$1" delta="$2" max="$3"
  if awk -v d="$(num_norm "$delta")" -v m="$(num_norm "$max")" 'BEGIN{exit !(d>m)}'; then
    echo "[perf-compare][warn] $label regression: delta=$delta threshold=$max"
    fail=1
  fi
}

# Non-strict mode assumes this is an idle-ish comparison.
# If either snapshot has high load, treat result as inconclusive.
# This threshold is host-profile dependent; allow override.
idle_load_max="${PERF_COMPARE_IDLE_LOAD_MAX:-1.20}"
is_busy=0
old_idle_gate="$(get_header "$old" "idle-gate-result")"
new_idle_gate="$(get_header "$new" "idle-gate-result")"
has_idle_meta=0
if [ -n "$old_idle_gate" ] && [ -n "$new_idle_gate" ]; then
  has_idle_meta=1
fi
if awk -v o="$(num_norm "$old_load")" -v n="$(num_norm "$new_load")" -v m="$idle_load_max" 'BEGIN{exit !((o>m)||(n>m))}'; then
  is_busy=1
fi

echo "[perf-compare] old=$old"
echo "[perf-compare] new=$new"
echo
echo "metric	old	new	delta"
echo "load1	$old_load	$new_load	$delta_load"
echo "mem_used_mib	$old_mem_used_mib	$new_mem_used_mib	$delta_mem_mib"
echo "dms_rss_kb	${old_dms:-0}	${new_dms:-0}	$delta_dms"
echo "qs_rss_kb	${old_qs:-0}	${new_qs:-0}	$delta_qs"
echo "keyrs_rss_kb	${old_keyrs:-0}	${new_keyrs:-0}	$delta_keyrs"
echo "mpd_rss_kb	${old_mpd:-0}	${new_mpd:-0}	$delta_mpd"

check_threshold "load1" "$delta_load" "$max_load_delta"
check_threshold "memory" "$delta_mem_mib" "$max_mem_delta_mib"
check_threshold "dms_rss" "$delta_dms" "$max_dms_delta_kb"
check_threshold "qs_rss" "$delta_qs" "$max_qs_delta_kb"
check_threshold "keyrs_rss" "$delta_keyrs" "$max_keyrs_delta_kb"
check_threshold "mpd_rss" "$delta_mpd" "$max_mpd_delta_kb"

if [ "$strict" -ne 1 ]; then
  if [ "$has_idle_meta" -eq 1 ]; then
    if [ "$old_idle_gate" != "satisfied" ] || [ "$new_idle_gate" != "satisfied" ]; then
      if awk -v o="$(num_norm "$old_load")" -v n="$(num_norm "$new_load")" -v m="$(num_norm "$idle_load_max")" 'BEGIN{exit !((o<=m)&&(n<=m))}'; then
        echo "[perf-compare] note: idle gate not satisfied in one snapshot, but load is within relaxed idle max (old_load=$old_load new_load=$new_load max=$idle_load_max)"
      else
        echo "[perf-compare] RESULT: INCONCLUSIVE (idle gate not satisfied: old=$old_idle_gate new=$new_idle_gate)"
        exit 0
      fi
    fi
  elif [ "$is_busy" -eq 1 ]; then
    echo "[perf-compare] RESULT: INCONCLUSIVE (non-idle snapshot: old_load=$old_load new_load=$new_load)"
    exit 0
  fi
fi

if [ "$fail" -eq 1 ]; then
  echo "[perf-compare] RESULT: REGRESSION"
  exit 1
fi

echo "[perf-compare] RESULT: OK"
