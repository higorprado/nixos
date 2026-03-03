# CI Lane Policy

## Objective
Keep default CI feedback fast while preserving deep confidence checks through explicit full-lane runs.

## Lanes
1. Fast lane (`lint-structure`):
   - Triggers on `push` and `pull_request`.
   - Runs changed-file quality + structure gates.
   - Expected use: every PR and routine commits.
2. Full lane (`predator-eval-build` + `server-example-eval-build`):
   - Triggers on:
     - manual dispatch with `run_full = true`,
     - weekday scheduled run.
   - Runs full eval/build validation gates.
   - Expected use: high-impact changes and periodic confidence checks.

## When Full Lane Is Mandatory Before Merge
1. `flake.nix` host wiring changes.
2. Host/module/profile/desktop contract changes.
3. Option migrations or compatibility framework updates.
4. CI/validation script refactors that can change gate semantics.

## Spend/Time Controls
1. Full-lane jobs have dedicated concurrency groups with cancellation enabled.
2. Fast lane remains the default required signal for normal PR iteration.
3. Full lane is opt-in for PR iteration and always available for release-level confidence.
