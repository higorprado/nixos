# Flake and Structure Pattern (Agent Ops)

## Objective
Standardize repo structure and `flake.nix` wiring without changing runtime behavior.

## Default pattern (enforced)
1. `flake.nix` stays thin:
   - Inputs.
   - Shared `let` helpers (`system`, `customPkgs`, shared args).
   - `nixosConfigurations` host wiring.
2. No inline anonymous module blocks in `flake.nix` if they can live in tracked modules.
3. Input naming:
   - Flake inputs: kebab-case.
   - Non-flake sources: `*-src`.
4. One package system accessor style per concern (avoid mixed `pkgs.system` and `pkgs.stdenv.hostPlatform.system` patterns).
5. `pkgs/default.nix` sections:
   - local derivations (`callPackage`)
   - upstream flake packages.
6. `legacy/` is archive-only.

## Implementation plan
1. Phase 0: baseline + validation gates.
2. Phase 1: normalize input taxonomy and naming (rename-only slice).
3. Phase 2: move inline `flake.nix` module blocks into dedicated module files.
4. Phase 3: standardize `pkgs/default.nix` source sections + system accessor choice.
5. Phase 4: clean stale items and confirm `home/user/apps` role.
6. Phase 5: keep exceptions documented with explicit risk and revisit trigger.
7. Phase 6: run `scripts/check-flake-pattern.sh` as a pre-publish structural guard.

## Mandatory validation gates
1. `nix flake metadata`
2. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
3. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
4. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
5. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

## Phase 0 execution log (2026-03-01)
1. Baseline:
   - `git status --short --branch`: PASS (`chore/flake-pattern-plan`, clean except this doc slice).
   - `rg -n "inputs\\." -g '*.nix'`: PASS (usage map captured).
   - `./scripts/check-flake-tracked.sh`: PASS.
2. Validation gates:
   - All five gates: PASS.
3. Notes:
   - Builds/evals required unsandboxed Nix daemon access in this environment.
   - Warnings observed:
     - `'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'`
     - `xorg.libxcb` deprecation warning.

## Phase 1 execution log (2026-03-01)
1. Renamed non-flake inputs to `*-src`:
   - `catppuccinZenBrowserSource` -> `catppuccin-zen-browser-src`
   - `keyrsSource` -> `keyrs-src`
   - `dmsAwwwSource` -> `dms-awww-src`
2. Updated references in `pkgs/default.nix`.
3. Validation gates: PASS.

## Phase 2 execution log (2026-03-01)
1. Moved Nix cache settings from inline `flake.nix` module block to:
   - `modules/core/nix-cache.nix`
2. Wired new cache module through `modules/core/default.nix`.
3. Moved Home Manager shared settings from inline `flake.nix` block to:
   - `home/user/default.nix` (`extraSpecialArgs`, `sharedModules`)
4. Validation gates: PASS.

## Phase 3 execution log (2026-03-01)
1. Standardized package system accessor to `pkgs.stdenv.hostPlatform.system` for flake package selection.
2. Updated:
   - `pkgs/default.nix`
   - `modules/profiles/desktop.nix`
   - `home/user/desktop/apps.nix`
   - `home/user/programs/editors/zed.nix`
3. Split `pkgs/default.nix` into explicit local-derivation and upstream-flake sections.
4. Validation gates: PASS.

## Phase 4 execution log (2026-03-01)
1. Removed stale `danksearch` input from `flake.nix`.
2. Refreshed lock file to remove stale lock nodes.
3. Clarified active `home/user/apps` ownership wording (removed legacy phrasing).
4. Validation gates: PASS.

## Phase 6 execution log (2026-03-01)
1. Added `scripts/check-flake-pattern.sh`.
2. Guard checks:
   - input naming policy
   - source input `-src` suffix
   - no inline anonymous `flake.nix` module blocks
   - no `pkgs.system` accessor usage
3. Script run result: PASS.

## Exception ledger (required for deviations)
When a rule above is intentionally violated, add one entry here.

### Entry template
1. Date:
2. File/path:
3. Rule violated:
4. Reason:
5. Risk accepted:
6. Revisit trigger/date:

### Entries
1. None yet.
