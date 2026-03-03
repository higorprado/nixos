# Switch and Rollback

## Use This For
1. Applying configuration changes locally.
2. Recovering quickly if session/login behavior regresses.

## Safe Apply
1. Run fast checks first:
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
2. Run full checks before final switch:
   - `./scripts/run-validation-gates.sh all`
3. Apply using your normal switch command/workflow.

## Rollback Pattern
1. If regression appears, rollback to last known-good generation.
2. Re-run `./scripts/check-runtime-smoke.sh --allow-non-graphical` to confirm recovery.
3. Create a small fix slice instead of broad rewrites.
