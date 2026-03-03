#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

run_structure_gates() {
  echo "[validation-gates] structure gates"
  ./scripts/check-desktop-capability-usage.sh
  ./scripts/check-option-declaration-boundary.sh
  ./scripts/check-validation-source-of-truth.sh
}

run_predator_gates() {
  echo "[validation-gates] predator gates"
  local hm_user
  hm_user="$(nix eval --raw "path:$PWD#nixosConfigurations.predator.config.custom.user.name")"

  ./scripts/check-profile-matrix.sh
  nix flake metadata
  nix eval "path:$PWD#nixosConfigurations.predator.config.system.stateVersion"
  nix eval "path:$PWD#nixosConfigurations.predator.config.home-manager.users.${hm_user}.home.stateVersion"
  nix build --no-link "path:$PWD#nixosConfigurations.predator.config.home-manager.users.${hm_user}.home.path"
  nix build --no-link "path:$PWD#nixosConfigurations.predator.config.system.build.toplevel"
}

run_server_example_gates() {
  echo "[validation-gates] server-example gates"
  nix eval "path:$PWD#nixosConfigurations.server-example.config.custom.host.role"
  nix eval --json "path:$PWD#nixosConfigurations.server-example.config.custom.desktop.capabilities"
  nix build --no-link "path:$PWD#nixosConfigurations.server-example.config.system.build.toplevel"
}

usage() {
  cat <<'EOF'
Usage: scripts/run-validation-gates.sh [structure|predator|server-example|all]

Commands:
  structure       Run structure/policy gates only.
  predator        Run predator eval/build gates only.
  server-example  Run server-example eval/build gates only.
  all             Run structure + predator + server-example gates (default).
EOF
}

stage="${1:-all}"

case "$stage" in
  structure)
    run_structure_gates
    ;;
  predator)
    run_predator_gates
    ;;
  server-example)
    run_server_example_gates
    ;;
  all)
    run_structure_gates
    run_predator_gates
    run_server_example_gates
    echo "[validation-gates] ok"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "[validation-gates] unknown stage: $stage" >&2
    usage >&2
    exit 1
    ;;
esac
