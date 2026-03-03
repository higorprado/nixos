#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

out_dir="reports/nixos/artifacts/runtime-warning-budget"
mkdir -p "$out_dir"

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out_file="${out_dir}/${ts}-runtime-smoke.txt"

./scripts/check-runtime-smoke.sh --allow-non-graphical "$@" 2>&1 | tee "$out_file"
printf '[runtime-warning-report] ok: %s\n' "$out_file"
