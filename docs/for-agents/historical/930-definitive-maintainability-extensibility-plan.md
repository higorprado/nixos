# Definitive Maintainability + Extensibility Plan

## Objective
Push the repo from "very good" to "excellent" on maintainability and extensibility without reducing reliability.

## Definition Of "Excellent"
1. Maintainability score target: `>= 9.2/10`.
2. Extensibility score target: `>= 9.4/10`.
3. Reliability floor: no regression from current baseline gates/runtime-smoke behavior.
4. Change velocity target: common extension tasks remain low-touch and predictable.

## Baseline Diagnosis (Current State)
1. Strong strengths already in place:
   - Host/profile/pack registries and extension contracts.
   - Option migration safety framework.
   - Canonical validation runner (`scripts/run-validation-gates.sh`).
2. Primary maintainability bottlenecks:
   - Validation script surface is large (`35` scripts, `3431` shell LOC).
   - A few scripts are high-complexity hotspots (`check-extension-contracts.sh`, `check-runtime-smoke.sh`, `audit-system-up-to-date.sh`).
   - Multiple checks rely on text parsing (`rg`/`awk`), which is faster to write but brittle over long-term refactors.
3. Primary extensibility bottlenecks:
   - Some runtime/validation assumptions still center on `predator` as canonical host.
   - Host/user safety constraints are correct but can fail in CI if defaults are unresolved.
   - Full confidence checks are expensive and can drift into manual-only usage if not split by intent.

## Non-Negotiable Constraints
1. Do not commit private override files.
2. Do not weaken existing safety/public checks.
3. Do not do one-shot rewrites; each phase must be reversible.
4. Keep server role isolated from desktop wiring.

## Program Structure
This plan is executed in 9 phases. Each phase has explicit outputs, tests, and rollback.

---

## Phase 0: Baseline + Quality Budget

### Tasks
1. Create artifact folder `reports/nixos/artifacts/930-definitive-quality/`.
2. Capture current metrics:
   - top script complexity (line counts),
   - gate durations (structure/predator/server-example),
   - extension touch surfaces (host/profile/pack),
   - current warning inventory (known non-fatal warnings).
3. Write `00-baseline-metrics.md` with objective numbers and collection commands.

### Exit Criteria
1. Baseline metrics are reproducible from commands in artifacts.
2. Time/cost baseline is available for every later phase comparison.

### Required Validation
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/check-repo-public-safety.sh`

---

## Phase 1: Validation Platform Consolidation

### Tasks
1. Split monolithic checks into reusable library-style helpers under `scripts/lib/`.
2. Introduce a shared helper layer for:
   - command requirements,
   - structured fail reporting,
   - reusable set-comparison utilities,
   - common Nix-eval wrappers.
3. Refactor highest-risk checks first:
   - `check-extension-contracts.sh`
   - `check-option-migrations.sh`
   - `check-profile-matrix.sh`
4. Preserve behavior with fixture-backed "before vs after" outputs.

### Exit Criteria
1. At least 30% reduction in duplicated shell logic in top-5 checks.
2. Check outputs remain semantically equivalent (no silent broadening/narrowing).

### Required Validation
1. `shellcheck` for all changed scripts.
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/run-validation-gates.sh predator`
4. `./scripts/run-validation-gates.sh server-example`
5. `./scripts/check-repo-public-safety.sh`

---

## Phase 2: Identity + Host Contract Hardening

### Tasks
1. Define explicit policy for `custom.user.name` resolution across:
   - local/private overrides,
   - tracked fallback values,
   - CI contexts.
2. Encode this policy in one canonical contract doc and one canonical check.
3. Ensure every declared host has explicit safe user-resolution behavior.
4. Add regression test for "no private overrides present" CI evaluation.

### Exit Criteria
1. CI no longer depends on private override presence.
2. Local private override behavior remains unchanged.

### Required Validation
1. `./scripts/run-validation-gates.sh structure`
2. `./scripts/run-validation-gates.sh predator`
3. `./scripts/run-validation-gates.sh server-example`
4. `./scripts/check-runtime-smoke.sh --allow-non-graphical` (if desktop path touched)

---

## Phase 3: Descriptor-First Host Model

### Tasks
1. Introduce a host descriptor schema (minimal host identity + selections).
2. Create a host-descriptor registry separate from heavy module wiring.
3. Generate/compose `nixosConfigurations` from descriptors + shared assembly.
4. Add host creation skeleton command/template under tracked docs/scripts.

### Exit Criteria
1. Adding host requires only:
   - new `hosts/<name>/default.nix`,
   - one descriptor/registry entry.
2. Host role/user/profile invariants are validated centrally.

### Required Validation
1. `./scripts/run-validation-gates.sh all`
2. `./scripts/check-repo-public-safety.sh`

---

## Phase 4: Schema-Driven Profile + Pack Contracts

### Tasks
1. Define one explicit schema doc for profile metadata + pack-set contract.
2. Add machine-check for schema versioning and required fields.
3. Replace remaining implicit assumptions in profile/pack checks with schema-driven evaluation.
4. Add migration path policy for metadata key changes.

### Exit Criteria
1. New profile/pack integration requires no shared-core edits outside declared contract points.
2. Contract mismatches fail with actionable, field-level diagnostics.

### Required Validation
1. `./scripts/run-validation-gates.sh structure`
2. `./scripts/run-validation-gates.sh predator`
3. `./scripts/run-validation-gates.sh server-example`

---

## Phase 5: CI Two-Lane Quality Model

### Tasks
1. Keep fast default CI lane for push/PR (`lint-structure`).
2. Add explicit full-validation lane:
   - manual dispatch (already present),
   - optional schedule (daily/weekday) for unattended deep checks.
3. Publish CI policy:
   - when fast lane is sufficient,
   - when full lane is mandatory before merge/release.
4. Add concurrency + cancellation policies for full lane to control spend.

### Exit Criteria
1. Typical CI feedback time reduced and stable.
2. Full coverage remains accessible and policy-enforced.

### Required Validation
1. `.github/workflows/validate.yml` lint + structure checks
2. One manual full-lane run evidence artifact

---

## Phase 6: Test Pyramid For Configuration Regressions

### Tasks
1. Establish 3-layer config test pyramid:
   - Layer A: static structure/contract checks (fast),
   - Layer B: eval-based matrix checks (medium),
   - Layer C: targeted build/runtime smoke (slow/high confidence).
2. Add per-layer ownership and expected runtime budget.
3. Add synthetic fixtures for:
   - host addition,
   - profile addition,
   - pack addition,
   - option migration lifecycle.

### Exit Criteria
1. Every high-risk change category maps to at least one layer A/B/C check.
2. Regression detection latency decreases for extension mistakes.

### Required Validation
1. `./scripts/run-validation-gates.sh all`
2. `./scripts/check-runtime-smoke.sh --allow-non-graphical` (desktop-impacting slices)

---

## Phase 7: Documentation Architecture Cleanup

### Tasks
1. Define doc lifecycle states: `canonical`, `active-plan`, `historical`.
2. Add one index mapping each canonical topic to exactly one source-of-truth file.
3. Move stale plan execution details to historical area; keep canonical docs short.
4. Keep docs drift checks focused on canonical set only.

### Exit Criteria
1. Lower cognitive load for maintainers (fewer competing sources-of-truth).
2. Faster onboarding for agent execution with less doc-scanning overhead.

### Required Validation
1. `./scripts/run-validation-gates.sh structure`
2. `./scripts/check-docs-drift.sh`

---

## Phase 8: Reliability Budget + Warning Governance

### Tasks
1. Create warning budget policy for known recurring warnings (Nix + runtime).
2. Track warning counts in artifacts with thresholds and ownership.
3. Separate "known accepted warning" from "new warning regression" in checks/reports.
4. Add expiration dates for accepted warnings (must be revisited).

### Exit Criteria
1. Warning noise is controlled and auditable.
2. New warning classes are caught early instead of normalized.

### Required Validation
1. `./scripts/check-runtime-smoke.sh --allow-non-graphical`
2. `./scripts/run-validation-gates.sh predator`

---

## Phase 9: Final Excellence Audit

### Tasks
1. Recompute maintainability/extensibility scores from objective rubric.
2. Compare against Phase 0 baseline metrics.
3. Produce final audit artifact:
   - what improved,
   - what remains below target,
   - next-cycle backlog.
4. Update canonical docs (`for-agents` + `for-humans`) with final workflow.

### Exit Criteria
1. Targets met or explicit gap report with ranked residual work.
2. Full local validation + smoke evidence attached.

### Required Validation
1. `./scripts/run-validation-gates.sh all`
2. `./scripts/check-repo-public-safety.sh`
3. `./scripts/check-runtime-smoke.sh --allow-non-graphical`

---

## Global Execution Rules (Agent-Executable)
1. One commit per coherent slice.
2. Never include unrelated changes (example: incidental lock churn) unless required.
3. After each meaningful slice run:
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
   - plus stage-specific gates from phase requirements.
4. If a slice touches desktop/session/runtime, include smoke checks.
5. If any gate fails, fix before proceeding (no deferred red state).

## Success Metrics Dashboard
Track and update these in `reports/nixos/artifacts/930-definitive-quality/`:
1. Extension touch-surface:
   - add-host files touched,
   - add-profile files touched,
   - add-pack files touched.
2. Validation cost:
   - CI fast-lane duration,
   - full-lane duration,
   - local `all` duration.
3. Complexity:
   - top-10 script LOC,
   - duplicated helper patterns count.
4. Reliability:
   - warning budget trend,
   - gate pass rate by stage.

## Commit Message Convention
1. `feat(quality): <phase intent>`
2. `refactor(validation): <scope>`
3. `docs(quality): <doc scope>`

## Rollback Strategy
1. Revert last slice only.
2. Keep migration compatibility entries until replacement is proven.
3. Never revert unrelated user work.
