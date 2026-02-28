# Validation and Safety Gates

## Mandatory Gates
1. `nix flake metadata`
2. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
3. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
4. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
5. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

## Rollback
1. Prefer reverting the last slice rather than broad resets.
2. If migration/cleanup, ensure backup exists before deletion.
3. Keep a written move/remove ledger for recoverability.

## Destructive Change Rule
If ownership/reference is ambiguous, stop and ask user.
