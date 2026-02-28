#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/check-dotfiles-parity.sh

Environment:
  STRICT_DOTFILES_PARITY=1
    Exit non-zero when declared managed dotfiles are missing on host.
EOF
  exit 0
fi

strict="${STRICT_DOTFILES_PARITY:-0}"
fail=0

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
home_user_dir="$(find "$repo_root/home" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | head -n1)"
if [ -z "$home_user_dir" ]; then
  echo "[dotfiles-parity] warn: no user home module directory found under $repo_root/home"
  exit 0
fi
declare -a expected=()

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  expected+=("$HOME/.config/$rel")
done < <(
  rg -No 'xdg\.configFile\."[^"]+"(\.|[[:space:]]*=)' "$repo_root/home/$home_user_dir"/*.nix \
    | sed -E 's#.*xdg\.configFile\."([^"]+)".*#\1#' \
    | sort -u
)

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  case "$rel" in
    /*) expected+=("$rel") ;;
    *) expected+=("$HOME/$rel") ;;
  esac
done < <(
  rg -No 'home\.file\."[^"]+"(\.|[[:space:]]*=)' "$repo_root/home/$home_user_dir"/*.nix \
    | sed -E 's#.*home\.file\."([^"]+)".*#\1#' \
    | sort -u
)

if [ "${#expected[@]}" -eq 0 ]; then
  echo "[dotfiles-parity] warn: no declared dotfiles discovered in home/$home_user_dir/*.nix"
  exit 0
fi

echo "[dotfiles-parity] checking expected managed dotfiles"
for f in "${expected[@]}"; do
  if [ -e "$f" ]; then
    echo "[dotfiles-parity] ok: $f"
  else
    echo "[dotfiles-parity] warn: missing $f"
    fail=1
  fi
done

if [ "$fail" -eq 1 ]; then
  if [ "$strict" = "1" ]; then
    echo "[dotfiles-parity] FAIL: missing files and STRICT_DOTFILES_PARITY=1"
    exit 1
  fi
  echo "[dotfiles-parity] WARN: missing files (non-strict mode)"
  exit 0
fi

echo "[dotfiles-parity] ok: expected managed dotfiles exist"
