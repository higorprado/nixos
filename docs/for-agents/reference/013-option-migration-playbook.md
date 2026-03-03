# Option Migration Playbook

## Goal
Prevent silent option-breaking changes by requiring explicit migration metadata and automated checks.

## Canonical Files
1. `modules/options/migration-registry.nix`
2. `modules/options/option-migrations.nix`
3. `scripts/check-option-migrations.sh`

## Registry Contract
`modules/options/migration-registry.nix` must expose three lists:
1. `renamed`
2. `aliases`
3. `removed`

Every entry must define:
1. Source option path (`from` for `renamed`/`aliases`, `path` for `removed`).
2. `removeAfter` in `YYYY-MM`.
3. Human explanation (`note` or `message`).

## Patterns
1. Rename:
   - add `renamed` entry (`from` -> `to`)
   - keep compatibility until `removeAfter`
2. Temporary alias:
   - add `aliases` entry (`from` -> `to`)
   - remove alias by `removeAfter`
3. Hard removal:
   - add `removed` entry with clear replacement message
   - never remove without an entry

## Guardrail
`scripts/check-option-migrations.sh` enforces:
1. Registry shape and metadata completeness.
2. Migration module wiring in `modules/options/default.nix`.
3. Any removed option declaration in `modules/options/` or `home/user/options/` must have a registry entry.

## Procedure
1. Add or update entries in `modules/options/migration-registry.nix` first.
2. Apply option rename/removal in option declaration modules.
3. Run:
   - `./scripts/check-option-migrations.sh`
   - `./scripts/run-validation-gates.sh structure`
   - full mandatory five-gate set before commit.

## Removal Policy
1. Do not delete migration entries early.
2. If entry is past `removeAfter`, remove shim and registry entry in the same slice with full gates.
