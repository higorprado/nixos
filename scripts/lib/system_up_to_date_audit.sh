#!/usr/bin/env bash

audit_deps_for_script() {
  case "$1" in
    scripts/check-declarative-paths.sh) echo "rg" ;;
    scripts/check-dev-dotfiles-parity.sh) echo "find sort head git sed rg" ;;
    scripts/check-dotfiles-parity.sh) echo "find sort head rg sed" ;;
    scripts/check-flake-tracked.sh) echo "git rg cut" ;;
    scripts/check-logid-parity.sh) echo "diff cat" ;;
    scripts/check-nix-deprecations.sh) echo "rg" ;;
    scripts/check-nvim-contract.sh) echo "rg ps nvim pyright ruff lua-language-server vtsls node rust-analyzer lldb-dap" ;;
    scripts/check-repo-public-safety.sh) echo "rg grep mkdir mktemp wc cp id" ;;
    scripts/check-runtime-config-parity.sh) echo "cmp basename" ;;
    scripts/check-user-services-parity.sh) echo "rg readlink find sort" ;;
    scripts/nixos-post-switch-smoke.sh) echo "sudo nixos-rebuild id grep resolvectl systemctl command" ;;
    scripts/validate-host.sh) echo "nix sudo nixos-rebuild date hostname grep chmod" ;;
    *) echo "" ;;
  esac
}

audit_class_for_script() {
  case "$1" in
    scripts/check-dev-dotfiles-parity.sh|scripts/check-user-services-parity.sh|scripts/nixos-post-switch-smoke.sh)
      echo "move-private"
      ;;
    scripts/check-dotfiles-parity.sh|scripts/check-runtime-config-parity.sh|scripts/validate-host.sh)
      echo "repair"
      ;;
    *)
      echo "keep"
      ;;
  esac
}

audit_write_decision_baseline() {
  local out_file="$1"
  local exclude_emacs="$2"

  {
    printf 'decision_id\tsource_doc\trule\texpected_pattern\tseverity_if_broken\n'
    printf 'D001\tdocs/for-agents/009-private-ops-scripts.md\tRepo scripts should be shared/reproducible; personal ops scripts must stay private\tNo personal host identifiers or private backup endpoints in shared scripts\thigh\n'
    printf 'D002\tdocs/for-agents/006-validation-and-safety-gates.md\tFive Nix validation gates are mandatory after meaningful slices\tflake metadata + eval stateVersion + build home.path + build system.toplevel\thigh\n'
    printf 'D003\tdocs/for-agents/007-private-overrides-and-public-safety.md\tPublic safety gate must detect sensitive/path leakage\tNo unallowlisted local paths/private IP/personal email/tokens\thigh\n'
    printf 'D004\tAGENT.md\tMutable copy-once files can intentionally diverge\tParity checks must distinguish mutable drift from hard failures\tmedium\n'
    printf 'D005\tdocs/for-agents/003-multi-host-model.md\tShared scripts should avoid single-host hardcoding when not required\tAvoid fixed host/profile identifiers unless explicitly host-scoped\tmedium\n'
    printf 'D006\tdocs/for-agents/903-catppuccin-centralization-execution.md\tCatppuccin decisions are centralized and should remain consistent\tNo contradictory per-module catppuccin toggles outside central registry\tmedium\n'
    if [ "$exclude_emacs" -eq 1 ]; then
      printf 'D007\tdocs/for-agents/905-system-up-to-date-audit-plan.md\tEmacs checks excluded for this audit\tSkip emacs-specific findings\tlow\n'
    fi
  } >"$out_file"
}
