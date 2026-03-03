# Validation and Safety Gates

## Mandatory Gates

1. `nix flake metadata`
2. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
3. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
4. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
5. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

## Optional Pattern Gates

1. `./scripts/check-flake-pattern.sh`
2. `./scripts/check-desktop-capability-usage.sh`
3. `./scripts/check-profile-matrix.sh`
4. `./scripts/check-option-declaration-boundary.sh`
5. `./scripts/check-validation-source-of-truth.sh`
6. `./scripts/check-runtime-smoke.sh` (local desktop session only)

## Full Local Validation

1. `./scripts/run-validation-gates.sh all` (canonical stage runner)
2. `./scripts/run-full-validation.sh` (compat wrapper for `all`)
3. Runs structure checks, Predator mandatory gates, and `server-example` eval/build checks.

## Rollback

1. Prefer reverting the last slice rather than broad resets.
2. If migration/cleanup, ensure backup exists before deletion.
3. Keep a written move/remove ledger for recoverability.

## Destructive Change Rule

If ownership/reference is ambiguous, stop and ask user.
