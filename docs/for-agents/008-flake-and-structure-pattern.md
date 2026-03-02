# Flake and Structure Pattern

## Goal
Keep `flake.nix` and repo wiring predictable, minimal, and easy to review.

## Core Rules
1. Keep `flake.nix` thin:
   - inputs
   - shared `let` values
   - host entries in `nixosConfigurations`
2. Move behavior to owned modules (`modules/`, `hosts/`, `home/`).
3. Do not keep inline anonymous module blocks in `flake.nix`.
4. Input naming:
   - flake inputs: kebab-case
   - source-only inputs (`flake = false`): `*-src`
5. Use one system accessor style for flake package lookups:
   - `pkgs.stdenv.hostPlatform.system`
6. Keep `pkgs/default.nix` split by intent:
   - local derivations
   - upstream flake packages
7. `legacy/` is archive-only (no active imports).

## Required Checks
1. `./scripts/check-flake-pattern.sh`
2. `nix flake metadata`
3. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
4. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
5. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
6. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

## Exception Rule
1. If a rule is intentionally violated, record one exception entry in [919-flake-and-structure-pattern-execution.md](docs/for-agents/919-flake-and-structure-pattern-execution.md).

## Execution History
1. Detailed implementation and phase logs live in [919-flake-and-structure-pattern-execution.md](docs/for-agents/919-flake-and-structure-pattern-execution.md).
