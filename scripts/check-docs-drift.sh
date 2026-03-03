#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

targets=(
  README.md
  docs/README.md
  docs/for-agents/000-operating-rules.md
  docs/for-agents/001-repo-map.md
  docs/for-agents/006-validation-and-safety-gates.md
  docs/for-agents/011-module-ownership-boundaries.md
  docs/for-humans/00-start-here.md
  docs/for-humans/03-multi-host-philosophy.md
  docs/for-humans/07-flake-and-structure-pattern.md
  docs/for-humans/08-validation-and-maintainability-release.md
)

resolve_reference() {
  local source_file="$1"
  local ref="$2"

  # Direct hit from repo root.
  if [ -e "$ref" ]; then
    return 0
  fi

  # Normalize leading ./ references.
  if [[ "$ref" == ./* ]] && [ -e "${ref#./}" ]; then
    return 0
  fi

  # Resolve relative to source doc directory.
  local source_dir
  source_dir="$(dirname "$source_file")"
  if [ -e "$source_dir/$ref" ]; then
    return 0
  fi

  # Common docs shorthand: same collection filename only.
  if [[ "$ref" == *.md && "$ref" != */* ]]; then
    if [[ "$source_dir" == docs/for-agents && -e "docs/for-agents/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-humans && -e "docs/for-humans/$ref" ]]; then
      return 0
    fi
  fi

  return 1
}

fail=0
checked=0

for source in "${targets[@]}"; do
  [ -f "$source" ] || continue

  # shellcheck disable=SC2016
  mapfile -t refs < <(
    {
      rg -No '`([A-Za-z0-9._/-]+\.(sh|nix|md|yml))`' "$source" | sed -E 's/.*`([^`]+)`.*/\1/'
      rg -No '\((docs/[A-Za-z0-9._/-]+\.md)\)' "$source" | sed -E 's/.*\((docs\/[A-Za-z0-9._\/-]+\.md)\).*/\1/'
    } | sed '/^$/d' | sort -u
  )

  for ref in "${refs[@]}"; do
    case "$ref" in
      http://*|https://*) continue ;;
    esac
    checked=$((checked + 1))
    if ! resolve_reference "$source" "$ref"; then
      log_fail "docs-drift" "missing referenced path from $source: $ref"
      fail=1
    fi
  done
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[docs-drift] ok: ${checked} references validated in living docs"
