# Repo Map

## Active Topology
1. `flake.nix`: entrypoint, inputs, host wiring, home-manager module wiring.
2. `hosts/<host>/`: host-specific imports and selections.
3. `modules/`: shared NixOS behavior (core/hardware/packages/profiles/services/options).
4. `home/<user>/`: user environment (core, shell, programs, desktop, dev, services).
5. `config/`: payload configs consumed by symlink/sync/copy-once logic.
6. `pkgs/`: custom derivations.
7. `scripts/`: shared validation/safety scripts (public-repo scope only).
8. `legacy/`: archived state; not active unless user explicitly requests.

## Private Script Boundary
1. Personal/host-specific ops scripts live outside this repo:
   - `~/ops/nixos-private-scripts/bin`
2. See `009-private-ops-scripts.md`.

## Critical Options
1. `custom.desktop.profile`
2. `custom.desktop.keyrs.enable`
