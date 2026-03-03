#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

workflow_file=".github/workflows/validate.yml"
local_runner_file="scripts/run-full-validation.sh"
gate_runner="./scripts/run-validation-gates.sh"

fail=0

report_fail() {
  printf '[validation-source] fail: %s\n' "$1"
  fail=1
}

require_workflow_line() {
  local snippet="$1"
  if ! rg -q --fixed-strings "$snippet" "$workflow_file"; then
    report_fail "workflow missing expected gate runner command: $snippet"
  fi
}

require_workflow_line "${gate_runner} structure"
require_workflow_line "${gate_runner} predator"
require_workflow_line "${gate_runner} server-example"

if rg -n \
  'check-desktop-capability-usage\.sh|check-option-declaration-boundary\.sh|check-profile-matrix\.sh|nix flake metadata|nix eval path:\$PWD#nixosConfigurations\.(predator|server-example)|nix build --no-link path:\$PWD#nixosConfigurations\.(predator|server-example)' \
  "$workflow_file" >/dev/null; then
  report_fail "workflow contains direct gate commands; use ${gate_runner} stages instead"
fi

if ! rg -q 'run-validation-gates\.sh"?[[:space:]]+all' "$local_runner_file"; then
  report_fail "scripts/run-full-validation.sh must delegate to run-validation-gates.sh all"
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[validation-source] ok: CI/local validation are routed through ${gate_runner}"
