# Runtime Warning Budget

## Objective
Keep runtime warning noise controlled while preventing normalization of new regressions.

## Source of Truth
1. `config/validation/runtime-warning-budget.json`
2. `scripts/check-runtime-smoke.sh`
3. `scripts/capture-runtime-warning-report.sh`

## Policy
1. New/unaccepted warning classes are listed in `failPatterns` and must remain zero.
2. Known noisy warnings are listed in `warningThresholds` with:
   - `defaultMax`
   - `owner`
   - `expiresOn`
   - optional environment override
3. Expired warning budgets must be reviewed; with `--strict-logs` they fail immediately.
4. Threshold overruns are warnings by default and become failures with `--strict-logs`.
5. For core-runtime-only diagnostics (without warning-budget scan), use:
   - `./scripts/check-runtime-smoke.sh --skip-log-budget`

## Governance
1. Every accepted warning entry must have an owner and expiration date.
2. Expiration dates force periodic re-evaluation of accepted noise.
3. Additive warning entries should include clear rationale in commit message and PR notes.

## Artifact Tracking
1. Capture a warning report artifact with:
   - `./scripts/capture-runtime-warning-report.sh`
2. Reports are stored under:
   - `reports/nixos/artifacts/runtime-warning-budget/`
