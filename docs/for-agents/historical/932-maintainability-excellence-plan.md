# Maintainability Excellence Plan

## Objective
Raise maintainability to an "excellent" level while preserving current reliability and extensibility.

## Success Targets
1. Maintainability score target: `>= 9.2/10`.
2. Reliability non-regression target: keep current pass behavior for structure + predator + server-example + runtime smoke.
3. Change-cost target: common maintenance tasks require fewer touched files and lower script complexity.
4. Documentation target: one clear source of truth per maintainability-critical topic.

## Baseline (Starting Point)
1. Current audit baseline from `historical/931-definitive-excellence-audit.md`:
   - Maintainability: `8.5/10`
   - Script count: `35`
   - Script LOC: `3862`
2. Main maintainability drag:
   - script complexity and duplicated shell logic,
   - uneven test coverage at script-function level,
   - mixed canonical vs historical docs in root,
   - limited quantitative maintainability KPIs tracked over time.

## Non-Negotiable Constraints
1. No weakening of safety/public checks.
2. No private override files committed.
3. One reversible slice at a time; no broad rewrites.
4. Every slice must run validation proportional to risk.

## Execution Protocol (For Any Agent)
1. Before each slice, record scope and expected affected files in commit message body.
2. After each meaningful slice run:
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
3. If slice touches host/profile/options/flake wiring, also run:
   - `./scripts/run-validation-gates.sh predator`
   - `./scripts/run-validation-gates.sh server-example`
4. If slice touches runtime/session/log checks, also run:
   - `./scripts/check-runtime-smoke.sh --allow-non-graphical`
5. At phase end, run:
   - `./scripts/check-repo-public-safety.sh`
   - `./scripts/run-validation-gates.sh all`

## Phase 0: KPI Baseline And Instrumentation

### Tasks
1. Create `reports/nixos/artifacts/932-maintainability/00-baseline/`.
2. Capture baseline metrics:
   - script count + total LOC under `scripts/`,
   - top 10 largest scripts,
   - structure/predator/server-example gate runtimes,
   - docs root vs historical distribution.
3. Add a small script (`scripts/report-maintainability-kpis.sh`) that re-generates the same metrics.

### Exit Criteria
1. Baseline metrics can be reproduced with one command.
2. KPI report format is stable and diff-friendly.

### Required Validation
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/check-repo-public-safety.sh`

## Phase 1: Script Architecture Normalization

### Tasks
1. Define script layout contract in a canonical doc:
   - `scripts/lib/` (reusable primitives),
   - `scripts/check-*` (single-purpose gates),
   - `scripts/run-*` (orchestration only).
2. Ensure every non-trivial script sources common helpers for:
   - dependency checks,
   - failure formatting,
   - tempdir/log handling.
3. Remove duplicated helper logic from top 5 largest scripts.

### Exit Criteria
1. At least 25% duplicate helper reduction in top script hotspots.
2. No behavior drift in existing gates.

### Required Validation
1. `shellcheck` on all changed scripts.
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/run-validation-gates.sh predator`
4. `./scripts/run-validation-gates.sh server-example`

## Phase 2: Deterministic Script Tests

### Tasks
1. Add fixture-based tests for complex scripts in `tests/scripts/`.
2. Cover at least:
   - `check-extension-contracts.sh`,
   - `check-runtime-smoke.sh`,
   - `run-validation-gates.sh`.
3. Ensure tests run without requiring full desktop runtime where not needed.

### Exit Criteria
1. Critical scripts have deterministic pass/fail fixtures.
2. Script changes can be validated without always running full heavyweight gates.

### Required Validation
1. `./scripts/run-validation-gates.sh structure`
2. New script-test runner execution (documented in phase artifact)
3. `./scripts/check-repo-public-safety.sh`

## Phase 3: Contract Consolidation For Maintainers

### Tasks
1. Reduce overlap between contract docs by centralizing maintainability-critical rules:
   - validation policy,
   - script ownership boundaries,
   - option migration and schema touchpoints.
2. Add a concise "maintainer change map" doc with:
   - where to edit for common tasks,
   - minimum validation required per task type.
3. Update canonical doc index links for consistency.

### Exit Criteria
1. Maintainer can map common change types to files and checks quickly.
2. No conflicting instructions across canonical docs.

### Required Validation
1. `./scripts/check-docs-drift.sh`
2. `./scripts/run-validation-gates.sh structure`

## Phase 4: Complexity Reduction In Hotspots

### Tasks
1. For each hotspot script, split into smaller functions/files with narrow responsibility.
2. Introduce explicit script interfaces:
   - documented inputs,
   - documented outputs,
   - exit-code contract.
3. Keep orchestration scripts thin; move logic to reusable libs.

### Exit Criteria
1. No script above agreed complexity threshold (define threshold in phase output).
2. Top hotspot LOC reduced by at least 20% each without loss of checks.

### Required Validation
1. `shellcheck` for changed scripts
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/run-validation-gates.sh predator`
4. `./scripts/run-validation-gates.sh server-example`

## Phase 5: Reliability-Preserving Runtime Check Tuning

### Tasks
1. Separate runtime-smoke core checks from optional noisy diagnostics.
2. Improve warning categorization to make failures actionable.
3. Keep strict mode available for release/diagnostic workflows.

### Exit Criteria
1. Runtime-smoke output is shorter and more actionable.
2. No reduction in high-confidence regression detection.

### Required Validation
1. `./scripts/check-runtime-smoke.sh --allow-non-graphical`
2. `./scripts/run-validation-gates.sh predator`
3. `./scripts/check-repo-public-safety.sh`

## Phase 6: Maintenance Cost Controls In CI

### Tasks
1. Ensure lane policy stays aligned with maintainability goals:
   - fast lane for iteration,
   - full lane for high-impact changes.
2. Add/adjust path filters so docs-only changes avoid expensive CI lanes when safe.
3. Keep explicit override path to force full lane when needed.

### Exit Criteria
1. CI cost/time reduced for low-risk changes.
2. High-risk changes still force deep validation.

### Required Validation
1. `./scripts/run-validation-gates.sh structure`
2. one local dry-run proof of lane trigger assumptions (artifact note)

## Phase 7: Lifecycle Hygiene And Historical Moves

### Tasks
1. Move completed/superseded plan docs from root into `docs/for-agents/historical/`.
2. Keep exactly one active plan in root.
3. Update `018-doc-lifecycle-and-index.md` active-plan section and canonical references.

### Exit Criteria
1. Root docs contain canonical docs + one active plan only.
2. Historical context remains accessible but non-authoritative.

### Required Validation
1. `./scripts/check-docs-drift.sh`
2. `./scripts/run-validation-gates.sh structure`

## Phase 8: Final Maintainability Audit

### Tasks
1. Recompute KPIs using Phase 0 tooling.
2. Publish `historical/933-maintainability-excellence-audit.md` with:
   - before/after metrics,
   - score update,
   - residual backlog.
3. Update for-humans and for-agents docs if maintainers' workflow changed.

### Exit Criteria
1. Maintainability score reaches target or has explicit prioritized gap list.
2. Validation evidence proves no regression in reliability.

### Required Validation
1. `./scripts/run-validation-gates.sh all`
2. `./scripts/check-runtime-smoke.sh --allow-non-graphical`
3. `./scripts/check-repo-public-safety.sh`

## Priority Backlog (Highest Impact First)
1. Script hotspot decomposition + helper reuse.
2. Deterministic tests for high-risk scripts.
3. Docs lifecycle cleanup to reduce discovery friction.
4. KPI automation to track maintainability objectively.
5. CI trigger tuning for low-risk change efficiency.
