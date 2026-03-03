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
2. Run `./scripts/check-flake-pattern.sh`.
3. Run `./scripts/run-full-validation.sh`.
4. Ensure CI workflow `.github/workflows/validate.yml` is green (`lint-structure`, `predator-eval-build`, `server-example-eval-build`).
5. If a change intentionally breaks a rule, add an exception entry (with reason and revisit date) in [919-flake-and-structure-pattern-execution.md](docs/for-agents/919-flake-and-structure-pattern-execution.md).

## Non-goals

1. This pattern does not force desktop/profile feature changes.
2. This pattern does not replace private override rules.
