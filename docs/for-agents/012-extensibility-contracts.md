# Extensibility Contracts

## Objective
Keep extension work local and predictable: adding hosts, desktop profiles, and optional packs should require minimal, obvious edits.

## Contracts

### Host Extension Contract
1. Host role/profile selections are declared in `hosts/<host>/default.nix`.
2. Shared defaults remain in options modules only:
   - `modules/options/core-options.nix`
   - `modules/options/desktop-options.nix`
3. Host registration is centralized in `flake.nix` host registry (`hostRegistry`).
4. New host onboarding should not require edits in shared behavior modules.

### Desktop Profile Extension Contract
1. Every profile has one implementation module:
   - `modules/profiles/desktop/profile-<name>.nix`
2. Every profile is registered in:
   - `modules/profiles/desktop/profile-registry.nix`
3. Every profile name is declared in:
   - `modules/options/desktop-options.nix` enum
4. Desktop profile aggregator consumes the registry:
   - `modules/profiles/desktop/default.nix`
5. Every profile is represented in capability mapping:
   - `modules/profiles/profile-capabilities.nix`
6. Validation profile matrix list must stay synchronized:
   - `scripts/check-profile-matrix.sh`

### Optional Pack Extension Contract
1. Pack implementation lives in a dedicated `home/user/desktop/<pack>.nix` module.
2. Pack registration is centralized in `home/user/desktop/pack-registry.nix`.
3. Pack wiring must be visible in `home/user/desktop/default.nix` via `packRegistry.packModules`.
4. If a pack needs new capability gating, add it via profile capability source; do not add ad-hoc host conditionals.

## Enforcement
1. `./scripts/check-extension-contracts.sh`
2. `./scripts/check-option-declaration-boundary.sh`
3. `./scripts/check-desktop-capability-usage.sh`
4. `./scripts/check-config-contracts.sh`
