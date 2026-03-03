#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

require_cmd "docs-drift" "rg"

targets=(
  README.md
  docs/README.md
  docs/for-agents/000-operating-rules.md
  docs/for-agents/001-repo-map.md
  docs/for-agents/006-validation-and-safety-gates.md
  docs/for-agents/007-private-overrides-and-public-safety.md
  docs/for-agents/009-private-ops-scripts.md
  docs/for-agents/018-doc-lifecycle-and-index.md
  docs/for-agents/plans/900-plans-index.md
  docs/for-agents/current-work/900-current-work-index.md
  docs/for-agents/reference/900-reference-index.md
  docs/for-agents/reference/011-module-ownership-boundaries.md
  docs/for-agents/reference/012-extensibility-contracts.md
  docs/for-agents/reference/013-option-migration-playbook.md
  docs/for-agents/reference/014-user-resolution-contract.md
  docs/for-agents/reference/015-profile-pack-schema.md
  docs/for-agents/reference/016-ci-lane-policy.md
  docs/for-agents/reference/017-config-test-pyramid.md
  docs/for-agents/reference/019-runtime-warning-budget.md
  docs/for-agents/reference/020-script-architecture-contract.md
  docs/for-agents/reference/021-maintainer-change-map.md
  docs/for-humans/00-start-here.md
  docs/for-humans/workflows/100-workflows-index.md
  docs/for-humans/workflows/101-host-and-profile-changes.md
  docs/for-humans/workflows/102-switch-and-rollback.md
  docs/for-humans/workflows/103-private-overrides.md
  docs/for-humans/workflows/104-validation-before-merge.md
  docs/for-humans/workflows/105-session-recovery.md
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
    if [[ "$source_dir" == docs/for-agents* && -e "docs/for-agents/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-humans* && -e "docs/for-humans/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-humans* && -e "docs/for-humans/workflows/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-agents* && -e "docs/for-agents/reference/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-agents* && -e "docs/for-agents/plans/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-agents* && -e "docs/for-agents/current-work/$ref" ]]; then
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
