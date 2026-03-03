# Repo Map

## Active Topology

1. `flake.nix`: entrypoint, inputs, host wiring, home-manager module wiring.
   - Host composition registry lives in `flake.nix` (`hostRegistry`).
   - `keyrs` is consumed as an upstream flake module (`inputs.keyrs.nixosModules.default`), wired at host level.
2. `hosts/<host>/`: host-specific imports and selections.
   - Includes `hosts/server-example/` as a minimal server-role skeleton for non-desktop eval/build checks.
   - Desktop hosts enable `services.keyrs` when keyrs remapping is required.
3. `modules/`: shared NixOS behavior (core/hardware/packages/profiles/services/options).
   - Option declarations live under `modules/options/`.
   - Option migration registry and module wiring live under `modules/options/migration-registry.nix` and `modules/options/option-migrations.nix`.
   - Desktop profile implementation lives under `modules/profiles/desktop/`.
   - Desktop profile registry lives in `modules/profiles/desktop/profile-registry.nix`.
   - Desktop profile metadata lives in `modules/profiles/desktop/profile-metadata.nix`.
4. `home/<user>/`: user environment (core, shell, programs, desktop, dev, services).
   - Home option declarations live under `home/user/options/`.
   - Desktop optional pack registry + pack sets live in `home/user/desktop/pack-registry.nix`.
5. `config/`: payload configs consumed by symlink/sync/copy-once logic.
6. `pkgs/`: custom derivations.
7. `scripts/`: shared validation/safety scripts (public-repo scope only).
   - Canonical validation entrypoint: `scripts/run-validation-gates.sh`.
8. `legacy/`: archived state; not active unless user explicitly requests.

## Private Script Boundary

1. Personal/host-specific ops scripts live outside this repo:
   - `~/ops/nixos-private-scripts/bin`
2. See `009-private-ops-scripts.md`.

## Critical Options

1. `custom.desktop.profile`
2. `custom.desktop.keyrs.enable`

## Boundary Contract

1. Ownership boundaries are defined in `011-module-ownership-boundaries.md`.
2. Extension contracts are defined in `012-extensibility-contracts.md`.
3. Option migration/deprecation workflow is defined in `013-option-migration-playbook.md`.
