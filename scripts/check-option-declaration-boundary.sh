#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

allow_prefixes=(
  "modules/options/"
  "home/user/options/"
)

is_allowed() {
  local candidate="$1"
  local prefix
  for prefix in "${allow_prefixes[@]}"; do
    if [[ "$candidate" == "$prefix"* ]]; then
      return 0
    fi
  done
  return 1
}

matches="$(rg -n --glob '*.nix' '^\s*options\.' modules home || true)"

if [[ -z "$matches" ]]; then
  echo "[option-boundary] ok: no option declarations found"
  exit 0
fi

violations=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  file="${line%%:*}"
  if ! is_allowed "$file"; then
    violations+="$line"$'\n'
  fi
done <<<"$matches"

if [[ -n "$violations" ]]; then
  echo "[option-boundary] fail: option declarations found outside allowed option modules"
  printf '%s' "$violations"
  exit 1
fi

echo "[option-boundary] ok: option declarations limited to option modules"
