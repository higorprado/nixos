# Module Ownership Boundaries

## Objective
Keep ownership clear so changes stay local, reviewable, and regression-safe.

## Ownership Rules
1. Host selection only in `hosts/<host>/`:
   - host identity,
   - role/profile selection,
   - host-specific imports.
2. Shared NixOS behavior only in `modules/`:
   - `modules/core`, `modules/services`, `modules/hardware`, `modules/packages`, `modules/profiles`.
3. System option declarations only in `modules/options/`.
4. Home Manager option declarations only in `home/user/options/`.
5. Home user behavior only in `home/user/**` implementation modules.
6. Desktop profile behavior only in `modules/profiles/desktop/`.
7. Validation and safety automation only in `scripts/`.

## Boundary Violations (Do Not Do)
1. Declaring `options.*` in implementation modules (`modules/profiles/**`, `home/user/**` non-options paths).
2. Moving host-specific logic into shared modules without parameterization.
3. Adding desktop behavior into server-only host wiring.
4. Hardcoding local usernames in tracked CI/scripts/docs commands.

## Enforcement
1. `./scripts/check-option-declaration-boundary.sh`
2. `./scripts/check-config-contracts.sh`
3. `./scripts/check-desktop-capability-usage.sh`
4. `./scripts/check-extension-contracts.sh`
5. `./scripts/check-validation-source-of-truth.sh`
6. `./scripts/check-docs-drift.sh`
