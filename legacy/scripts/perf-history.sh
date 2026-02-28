#!/usr/bin/env bash
set -euo pipefail

files=(
  $(find .migration-audit -maxdepth 2 -type f -name 'perf-*.txt' -printf '%T@ %p\n' 2>/dev/null | sort -rn | awk '{print $2}')
)
if [ "${#files[@]}" -eq 0 ]; then
  echo "[perf-history] no perf snapshots found under .migration-audit/"
  exit 0
fi

echo -e "file\ttimestamp\tload1\tmem_used\tmem_total\tdms_rss_kb\tqs_rss_kb\tkeyrs_rss_kb\tmpd_rss_kb"
for f in "${files[@]}"; do
  ts="$(sed -n 's/^# timestamp: //p' "$f" | head -n1)"
  load1="$(sed -n '/^## uptime-load/{n;p;}' "$f" | awk -F'load average: ' '{print $2}' | cut -d',' -f1 | tr -d ' ' || true)"
  mem_used="$(awk '/^Mem:/ {print $3; exit}' "$f" || true)"
  mem_total="$(awk '/^Mem:/ {print $2; exit}' "$f" || true)"

  dms_rss="$(awk '$2=="dms" {print $4; exit}' "$f" || true)"
  qs_rss="$(awk '$2=="qs" {print $4; exit}' "$f" || true)"
  keyrs_rss="$(awk '$2=="keyrs" {print $4; exit}' "$f" || true)"
  mpd_rss="$(awk '$2=="mpd" {print $4; exit}' "$f" || true)"

  echo -e "$f\t${ts:-}\t${load1:-}\t${mem_used:-}\t${mem_total:-}\t${dms_rss:-}\t${qs_rss:-}\t${keyrs_rss:-}\t${mpd_rss:-}"
done
