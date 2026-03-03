# Flake and Structure Pattern

## Purpose

Define the default repo pattern so changes stay consistent and easy to reason about.

## Must-follow rules

1. Keep `flake.nix` thin:
   - Inputs, shared helpers, and host entries only.
   - Behavioral logic belongs in `modules/`, `hosts/`, or `home/`.
2. Use consistent input naming:
   - Flake inputs in kebab-case.
   - Non-flake sources (`flake = false`) use `*-src`.
3. Keep output wiring predictable:
   - `nixosConfigurations` is the primary output.
   - Add other outputs (`packages`, `checks`, `apps`) only when intentionally consumed.
4. Keep system key usage consistent:
   - Use one style across the repo (`pkgs.system` or `pkgs.stdenv.hostPlatform.system`).
5. Keep package source pattern explicit in `pkgs/default.nix`:
   - Group local derivations separately from upstream flake packages.
6. Treat `legacy/` as archive:
   - No active imports from `legacy/` paths.

## Change workflow

1. Make the smallest coherent slice.
2. Run `./scripts/check-changed-files-quality.sh [origin/main]`.
3. Run `./scripts/run-validation-gates.sh structure`.
4. Run `./scripts/check-flake-pattern.sh`.
5. Before merge, run `./scripts/run-validation-gates.sh all` (or `./scripts/run-full-validation.sh`).
6. Ensure CI workflow `.github/workflows/validate.yml` is green (`lint-structure` by default; heavy eval/build jobs are manual-dispatch).
7. If a change intentionally breaks a rule, add an exception entry (with reason and revisit date) in [919-flake-and-structure-pattern-execution.md](docs/for-agents/919-flake-and-structure-pattern-execution.md).

## Extension Registries

1. Hosts are declared only in `flake.nix` `hostRegistry`.
2. Desktop profiles are declared only in `modules/profiles/desktop/profile-registry.nix`.
3. Profile metadata (capabilities/integrations/pack sets) is declared only in `modules/profiles/desktop/profile-metadata.nix`.
4. Desktop packs and pack sets are declared only in `home/user/desktop/pack-registry.nix`.
5. Option rename/removal compatibility is declared only in `modules/options/migration-registry.nix`.

## Runtime Regression Checks

1. For desktop/session-related changes, run `./scripts/check-runtime-smoke.sh --allow-non-graphical`.
2. Treat repeated portal/session warnings as smoke-signal indicators even when builds pass.
3. Keep warning thresholds in the smoke script explicit and versioned.

## Non-goals

1. This pattern does not force desktop/profile feature changes.
2. This pattern does not replace private override rules.
