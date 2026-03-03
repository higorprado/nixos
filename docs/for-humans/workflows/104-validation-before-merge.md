# Validation Before Merge

## Minimum Required
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/run-validation-gates.sh all`
4. `./scripts/check-repo-public-safety.sh`

## When Desktop/Session Behavior Changed
1. `./scripts/check-runtime-smoke.sh --allow-non-graphical`
2. Optional: `./scripts/capture-runtime-warning-report.sh`

## Result Policy
1. Merge only when required gates are green.
2. Warnings must be understood and documented if intentionally accepted.
