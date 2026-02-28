#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/cutover-execute.sh <preflight|test|switch|full>

Commands:
  preflight  Run strict pre-cutover validation and require checklist GO.
  test       On NixOS host: run nixos-rebuild test and smoke checks.
  switch     On NixOS host: run nixos-rebuild switch and smoke checks.
  full       Run test then switch (NixOS host only).

Environment:
  CUTOVER_PREFLIGHT_MAX_RUNS=3
    Max strict preflight attempts before failing.
  CUTOVER_PREFLIGHT_SLEEP_SEC=20
    Delay between failed preflight attempts.
  CUTOVER_ALLOW_NOTE=0
    If set to 1, accept GO_WITH_NOTE as successful preflight result.
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
flake_ref="path:$repo_root#predator"

is_nixos_host() {
  [ -f /etc/os-release ] && grep -q '^ID=nixos$' /etc/os-release
}

latest_checklist() {
  ls -1t .migration-audit/cutover-checklist-*.md 2>/dev/null | head -n1 || true
}

assert_go_checklist() {
  local checklist decision
  checklist="$(latest_checklist)"
  if [ -z "$checklist" ]; then
    echo "[cutover] FAIL: no cutover checklist found"
    return 1
  fi

  decision="$(sed -n 's/^- Cutover decision: \*\*\(.*\)\*\*$/\1/p' "$checklist" | head -n1)"
  allow_note="${CUTOVER_ALLOW_NOTE:-0}"

  if [ "$decision" = "GO" ]; then
    echo "[cutover] GO checklist confirmed: $checklist"
    return 0
  fi

  if [ "$allow_note" = "1" ] && [ "$decision" = "GO_WITH_NOTE" ]; then
    echo "[cutover] GO_WITH_NOTE accepted by CUTOVER_ALLOW_NOTE=1: $checklist"
    return 0
  fi

  echo "[cutover] FAIL: latest checklist decision is '$decision': $checklist"
  if [ "$allow_note" != "1" ]; then
    echo "[cutover] hint: set CUTOVER_ALLOW_NOTE=1 to accept GO_WITH_NOTE"
  fi
  sed -n '1,40p' "$checklist" || true
  return 1
}

cmd="${1:-}"
if [ -z "$cmd" ] || [ "$cmd" = "-h" ] || [ "$cmd" = "--help" ]; then
  usage
  exit 0
fi

case "$cmd" in
  preflight)
    max_runs="${CUTOVER_PREFLIGHT_MAX_RUNS:-3}"
    sleep_sec="${CUTOVER_PREFLIGHT_SLEEP_SEC:-20}"
    attempt=1

    while true; do
      echo "[cutover] preflight attempt $attempt/$max_runs"
      if RUN_STRICT=1 ./scripts/precutover-run.sh; then
        run_ok=1
      else
        run_ok=0
        echo "[cutover] strict run returned non-zero (attempt $attempt)"
      fi

      if [ "$run_ok" -eq 1 ] && assert_go_checklist; then
        echo "[cutover] preflight OK"
        break
      fi

      if [ "$attempt" -ge "$max_runs" ]; then
        echo "[cutover] FAIL: preflight did not reach GO after $max_runs attempt(s)"
        exit 1
      fi

      echo "[cutover] retrying in ${sleep_sec}s"
      sleep "$sleep_sec"
      attempt="$((attempt + 1))"
    done
    ;;

  test)
    if ! is_nixos_host; then
      echo "[cutover] FAIL: test command must run on NixOS host"
      exit 1
    fi
    echo "[cutover] nixos-rebuild test"
    sudo nixos-rebuild test --flake "$flake_ref"
    echo "[cutover] post-switch smoke"
    ./scripts/nixos-post-switch-smoke.sh
    echo "[cutover] test phase OK"
    ;;

  switch)
    if ! is_nixos_host; then
      echo "[cutover] FAIL: switch command must run on NixOS host"
      exit 1
    fi
    echo "[cutover] nixos-rebuild switch"
    sudo nixos-rebuild switch --flake "$flake_ref"
    echo "[cutover] post-switch smoke"
    ./scripts/nixos-post-switch-smoke.sh
    echo "[cutover] switch phase OK"
    ;;

  full)
    if ! is_nixos_host; then
      echo "[cutover] FAIL: full command must run on NixOS host"
      exit 1
    fi
    "$0" test
    "$0" switch
    ;;

  *)
    usage
    exit 1
    ;;
esac
