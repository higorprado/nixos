#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/check-dev-dotfiles-parity.sh

Environment:
  STRICT_DEV_DOTFILES_PARITY=1
    Exit non-zero when required dev dotfiles are missing.
  DEV_DOTFILES_EXTRA_REQUIRED="path1:path2"
    Optional extra paths to enforce on this host.
EOF
  exit 0
fi

strict="${STRICT_DEV_DOTFILES_PARITY:-0}"
fail=0
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
home_user_dir="$(find "$repo_root/home" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | head -n1)"
if [ -z "$home_user_dir" ]; then
  echo "[dev-dotfiles] warn: no user home module directory found under $repo_root/home"
fi

required=(
  "$HOME/.config/fish/config.fish"
  "$HOME/.config/nvim/init.lua"
  "$HOME/.config/nvim/lazy-lock.json"
)

if [ -n "${DEV_DOTFILES_EXTRA_REQUIRED:-}" ]; then
  IFS=':' read -r -a extra_required <<< "${DEV_DOTFILES_EXTRA_REQUIRED}"
  for extra in "${extra_required[@]}"; do
    [ -n "$extra" ] || continue
    required+=("$extra")
  done
fi

echo "[dev-dotfiles] checking required dev dotfiles"
for f in "${required[@]}"; do
  if [ -e "$f" ]; then
    echo "[dev-dotfiles] ok: $f"
  else
    echo "[dev-dotfiles] warn: missing $f"
    fail=1
  fi
done

if [ -d "$HOME/.config/nvim/.git" ]; then
  if git -C "$HOME/.config/nvim" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    head="$(git -C "$HOME/.config/nvim" rev-parse --short HEAD 2>/dev/null || true)"
    remote="$(git -C "$HOME/.config/nvim" remote get-url origin 2>/dev/null || true)"
    echo "[dev-dotfiles] info: nvim git repo detected (head=${head:-unknown})"
    [ -n "$remote" ] && echo "[dev-dotfiles] info: nvim origin=$remote"
  fi
fi

expected_git_editor=""
if [ -n "$home_user_dir" ] && [ -f "$repo_root/home/$home_user_dir/programs/tools/git.nix" ]; then
  expected_git_editor="$(
    sed -n 's/^[[:space:]]*core\.editor[[:space:]]*=[[:space:]]*"\([^"]*\)".*$/\1/p' "$repo_root/home/$home_user_dir/programs/tools/git.nix" | head -n1
  )"
fi
git_editor="$(git config --global core.editor 2>/dev/null || true)"
if [ -n "$git_editor" ]; then
  if [ -n "$expected_git_editor" ] && [ "$git_editor" != "$expected_git_editor" ]; then
    echo "[dev-dotfiles] warn: git core.editor is '$git_editor' (Nix config expects '$expected_git_editor')"
    fail=1
  else
    if [ -n "$expected_git_editor" ]; then
      echo "[dev-dotfiles] ok: git core.editor matches expected '$expected_git_editor'"
    else
      echo "[dev-dotfiles] ok: git core.editor is set ($git_editor)"
    fi
  fi
fi

if [ "$fail" -eq 1 ]; then
  if [ "$strict" = "1" ]; then
    echo "[dev-dotfiles] FAIL: required dev dotfiles missing and STRICT_DEV_DOTFILES_PARITY=1"
    exit 1
  fi
  echo "[dev-dotfiles] WARN: required dev dotfiles missing (non-strict mode)"
fi
