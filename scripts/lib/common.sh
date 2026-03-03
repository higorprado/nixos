#!/usr/bin/env bash

script_dir() {
  cd -- "$(dirname -- "$1")" && pwd
}

repo_root_from_script() {
  local dir
  dir="$(script_dir "$1")"
  cd -- "$dir/.." && pwd
}

enter_repo_root() {
  REPO_ROOT="$(repo_root_from_script "$1")"
  export REPO_ROOT
  cd "$REPO_ROOT" || return 1
}

log_fail() {
  local scope="$1"
  local msg="$2"
  printf '[%s] fail: %s\n' "$scope" "$msg" >&2
}

require_cmd() {
  local scope="$1"
  local cmd="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_fail "$scope" "required command not found: $cmd"
    return 1
  fi
}

require_cmds() {
  local scope="$1"
  shift
  local cmd
  for cmd in "$@"; do
    require_cmd "$scope" "$cmd"
  done
}
