#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

require_cmds "script-fixture-tests" "rg"

if [[ ! -x tests/scripts/run-validation-gates-fixture-test.sh ]]; then
  log_fail "script-fixture-tests" "missing executable test script: tests/scripts/run-validation-gates-fixture-test.sh"
  exit 1
fi

./tests/scripts/run-validation-gates-fixture-test.sh
log_ok "script-fixture-tests" "all fixture-based script tests passed"
