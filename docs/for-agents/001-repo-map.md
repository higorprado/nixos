# Repo Map

## Active Topology

1. `flake.nix`: entrypoint, inputs, host wiring, home-manager module wiring.
2. `hosts/<host>/`: host-specific imports and selections.
   - Includes `hosts/server-example/` as a minimal server-role skeleton for non-desktop eval/build checks.
3. `modules/`: shared NixOS behavior (core/hardware/packages/profiles/services/options).
   - Option declarations live under `modules/options/`.
   - Desktop profile implementation lives under `modules/profiles/desktop/`.
4. `home/<user>/`: user environment (core, shell, programs, desktop, dev, services).
   - Home option declarations live under `home/user/options/`.
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

## Boundary Contract

1. Ownership boundaries are defined in `011-module-ownership-boundaries.md`.
