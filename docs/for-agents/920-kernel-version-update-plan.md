# Kernel Version Update Plan

## Goal
Move Predator from pinned kernel packages to latest kernel packages while keeping `linuwu-sense` working.

## Scope
1. `hosts/predator/hardware.nix` kernel package selection.
2. Validation that out-of-tree module `linuwu-sense` still compiles and is included.

## Plan
1. Replace pinned kernel package set:
   - from `pkgs.linuxPackages_6_18`
   - to `pkgs.linuxPackages_latest`
2. Run required validation gates:
   - `nix flake metadata`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
3. Confirm `linuwu-sense` build viability:
   - Verify system build succeeds with `boot.extraModulePackages = [ linuwu-sense ]`.
4. Rollback plan:
   - Revert `boot.kernelPackages` to the previous pinned set if build or runtime compatibility fails.

## Success Criteria
1. System build passes with latest kernel package set.
2. No evaluation/build failure from `linuwu-sense`.

## Execution Notes (2026-03-02)
1. `boot.kernelPackages` changed to `pkgs.linuxPackages_latest`.
2. Compatibility issue found:
   - `hardware.nvidia.open = true` failed to build on kernel `6.19.3` (`nvidia-open` API mismatch).
3. Resolution applied:
   - Set `hardware.nvidia.open = false`.
   - Keep NVIDIA package on `config.boot.kernelPackages.nvidiaPackages.beta`.
4. Validation result:
   - All five mandatory gates passed.
   - System closure confirms `linuwu-sense` present.
