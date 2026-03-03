# Extensibility Contracts

## Objective
Keep extension work local and predictable: adding hosts, desktop profiles, and optional packs should require minimal, obvious edits.

## Contracts

### Host Extension Contract
1. Host descriptor registry is centralized in `hosts/host-descriptors.nix`.
2. Host role/profile selections in `hosts/<host>/default.nix` must match descriptor values.
3. Shared defaults remain in options modules only:
   - `modules/options/core-options.nix`
   - `modules/options/desktop-options.nix`
4. `flake.nix` composes host modules from descriptors via `mkHostModules` and `hostRegistry = lib.mapAttrs mkHostModules hostDescriptors;`.
5. New host onboarding should require only:
   - `hosts/<host>/default.nix`
   - one descriptor entry in `hosts/host-descriptors.nix`
6. New host onboarding should not require edits in shared behavior modules.
7. Preferred bootstrap helper:
   - `scripts/new-host-skeleton.sh <host-name> [desktop|server] [desktop-profile]`

### Desktop Profile Extension Contract
1. Every profile has one implementation module:
   - `modules/profiles/desktop/profile-<name>.nix`
2. Every profile is registered in:
   - `modules/profiles/desktop/profile-registry.nix`
3. Every profile name is declared in:
   - `modules/options/desktop-options.nix` enum
4. Desktop profile aggregator consumes the registry:
   - `modules/profiles/desktop/default.nix`
5. Every profile has metadata contract:
   - `modules/profiles/desktop/profile-metadata.nix`
6. Capability mapping derives from metadata:
   - `modules/profiles/profile-capabilities.nix`
7. Validation profile matrix derives expected capabilities from metadata:
   - `scripts/check-profile-matrix.sh`
8. Metadata shape/version contract is defined in `015-profile-pack-schema.md`.

### Optional Pack Extension Contract
1. Pack implementation lives in a dedicated `home/user/desktop/<pack>.nix` module.
2. Pack registration is centralized in `home/user/desktop/pack-registry.nix`.
3. Pack-set definitions in `home/user/desktop/pack-registry.nix` are the only source for pack grouping.
4. Profile-to-pack-set selection is declared in `modules/profiles/desktop/profile-metadata.nix`.
5. Pack wiring must be visible in `home/user/desktop/default.nix` via selected pack modules from metadata pack sets.
6. If a pack needs new capability gating, add it via profile capability source; do not add ad-hoc host conditionals.
7. Pack registry shape/version contract is defined in `015-profile-pack-schema.md`.

## Enforcement
1. `./scripts/check-extension-contracts.sh`
2. `./scripts/check-extension-simulations.sh`
3. `./scripts/check-option-declaration-boundary.sh`
4. `./scripts/check-option-migrations.sh`
5. `./scripts/check-desktop-capability-usage.sh`
6. `./scripts/check-config-contracts.sh`
