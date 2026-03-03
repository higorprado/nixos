# Validation and Maintainability Release

## What Changed

1. Validation now has a canonical stage runner: `./scripts/run-validation-gates.sh`.
2. Core invariants are enforced by `./scripts/check-config-contracts.sh`.
3. Docs drift is checked by `./scripts/check-docs-drift.sh`.
4. A fast branch gate exists: `./scripts/check-changed-files-quality.sh [origin/main]`.
5. Option deprecation/removal safety is enforced by `./scripts/check-option-migrations.sh`.
6. Synthetic extension checks are enforced by `./scripts/check-extension-simulations.sh`.
7. Test-pyramid layer/category coverage is enforced by `./scripts/check-test-pyramid-contracts.sh`.
8. Runtime warning budgets are governed by `config/validation/runtime-warning-budget.json`.
9. Runtime session checks are automated by `./scripts/check-runtime-smoke.sh`.
10. Legacy desktop shim modules were removed in favor of canonical desktop profile paths.

## What Is Enforced Now

1. `predator` and `server-example` role/capability contracts are machine-checked.
2. Critical docs references in living docs cannot silently break.
3. CI and local validation share one execution path through the stage runner.
4. Contributor fast feedback and full pre-merge checks are clearly separated.
5. Option removals without migration entries fail structure checks.
6. Synthetic host/profile extension regressions fail predator checks.

## Full vs Fast Checks

1. Fast local feedback (during development):
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
2. Fast CI lane (default on push/PR):
   - `.github/workflows/validate.yml` job: `lint-structure`
3. Docs-only CI lane:
   - `.github/workflows/validate.yml` job: `docs-drift-only`
   - Runs when changed paths are only under `docs/**`.
   - Skips `lint-structure` for docs-only changes.
4. Full pre-merge validation:
   - `./scripts/run-validation-gates.sh all`
   - `./scripts/check-repo-public-safety.sh`
   - CI full lane via manual dispatch (`run_full = true`) or weekday schedule.
5. Desktop runtime regression checks (when relevant):
   - `./scripts/check-runtime-smoke.sh --allow-non-graphical`
6. Runtime warning artifact capture (when relevant):
   - `./scripts/capture-runtime-warning-report.sh`
