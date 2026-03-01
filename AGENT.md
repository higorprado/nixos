# Agent Quick Guide

## First Reads
1. `docs/for-agents/000-operating-rules.md`
2. `docs/for-agents/001-repo-map.md`
3. `docs/for-agents/007-private-overrides-and-public-safety.md`
4. `docs/for-agents/009-private-ops-scripts.md`
5. `docs/for-agents/999-lessons-learned.md`

## Docs Naming Rule
1. Agent docs use `NNN-name.md` (three digits), for example `000-...`, `009-...`, `903-...`.
2. Keep numbering consistent when adding new files.

## Safety Rules
1. Never commit real private override files (`hosts/*/private*.nix`, `home/*/private*.nix`); only `*.example` should be tracked.
2. Run public safety gate before publish:
   - `./scripts/check-repo-public-safety.sh`
3. Run mandatory Nix validation gates after meaningful changes:
   - `nix flake metadata`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

## Script Boundary
1. Repo `scripts/` is for shared validation/safety tooling.
2. Private/host-specific ops scripts live outside the repo at:
   - `~/ops/nixos-private-scripts/bin`

## Mutable Config Note
1. Some files are provisioned as mutable copy-once configs (for example `keyrs`, `dms`).
2. Parity checks can fail when local runtime files intentionally diverge from templates.
