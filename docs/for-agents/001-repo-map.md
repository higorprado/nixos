# Repo Map

## Configuration Topology
1. `flake.nix`: top-level wiring and host entrypoints.
2. `hosts/`: host-specific selections and identity.
3. `modules/`: shared NixOS behavior and options.
4. `home/`: Home Manager user behavior.
5. `config/`: payload configuration sources.
6. `pkgs/`: custom package derivations.
7. `scripts/`: shared validation and safety tooling.

## Host and Profile Registries
1. Host registry: `hosts/host-descriptors.nix`.
2. Desktop profile registry: `modules/profiles/desktop/profile-registry.nix`.
3. Desktop profile metadata: `modules/profiles/desktop/profile-metadata.nix`.
4. Desktop pack registry: `home/user/desktop/pack-registry.nix`.

## Docs Topology
1. `docs/for-humans/`: user/operator explanation and workflows.
2. `docs/for-agents/`: agent operating docs.
   - root: only critical operating docs.
   - `reference/`: supporting contracts/guides.
   - `plans/`: active plans.
   - `current-work/`: active execution notes.
   - `historical/`: completed/superseded records.

## Private Boundary
1. Private ops scripts must stay outside repo at `~/ops/nixos-private-scripts/bin`.
2. Private override structure and safety rules are defined in `docs/for-agents/007-private-overrides-and-public-safety.md`.
