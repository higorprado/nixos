# Validation and Maintainability Release

## Canonical Validation Model
1. Canonical runner: `./scripts/run-validation-gates.sh`.
2. Fast iteration:
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
3. Full pre-merge:
   - `./scripts/run-validation-gates.sh all`
   - `./scripts/check-repo-public-safety.sh`
4. Session/runtime checks when relevant:
   - `./scripts/check-runtime-smoke.sh --allow-non-graphical`
   - optional `./scripts/capture-runtime-warning-report.sh`

## CI Lanes
1. Fast default lane: `lint-structure`.
2. Docs-only lane: `docs-drift-only`.
3. Full eval/build lane: manual-dispatch + schedule.

## Workflow Entry
1. Use `workflows/104-validation-before-merge.md` for practical step-by-step checks.
2. Use `workflows/105-session-recovery.md` when runtime/session behavior regresses.
