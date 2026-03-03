# Extensibility Maximization Plan

## Objective
Maximize extensibility (add new hosts/profiles/services with minimal edits) while preserving current reliability, regression prevention, and maintainability.

## Scope
1. Nix module composition and extension points.
2. Host/profile/service registration flow.
3. Validation and contract coverage for extension paths.
4. Agent/human docs for extension workflows.

## Non-Goals
1. No desktop redesign.
2. No relaxation of current validation/safety gates.
3. No large one-shot refactor without phase-level rollback.

## Quality Guardrails
1. Every slice must reduce extension touch surface or reduce coupling.
2. Every slice must add or preserve automated protection.
3. No slice may merge if `run-validation-gates.sh all` fails.
4. Any desktop/session-impacting slice must run runtime smoke.

## Extensibility Definition (for this plan)
1. New host: only host-scoped file additions + one registry update.
2. New desktop profile: profile module + profile registry update; no shared-core edits.
3. New optional service pack: service pack module + pack registry update; no host-wide rewiring.

## Success Metrics
1. `add-host` workflow edits <= 3 files.
2. `add-profile` workflow edits <= 3 files.
3. `add-pack` workflow edits <= 3 files.
4. Full validation remains green throughout.
5. Runtime smoke remains green for desktop-impacting phases.

## Mandatory Validation Per Meaningful Slice
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/run-validation-gates.sh predator`
4. `./scripts/run-validation-gates.sh server-example`
5. `./scripts/check-repo-public-safety.sh`

When desktop/session behavior is touched, also run:
1. `./scripts/check-runtime-smoke.sh --allow-non-graphical`

## Phase 0: Baseline and Measurement

### Tasks
1. Capture baseline extension cost for:
   - adding a host,
   - adding a desktop profile,
   - adding an optional service pack.
2. Record current file touch lists and command sequence.
3. Create baseline artifacts under `reports/nixos/artifacts/929-extensibility/`.

### Exit Criteria
1. Baseline artifacts are present.
2. Current workflow friction points are explicitly listed.

## Phase 1: Extension Contract Formalization

### Tasks
1. Add extension contract doc defining allowed edit zones per extension type.
2. Add/update machine check to fail on forbidden cross-layer edits:
   - host logic leaking into shared modules without parameterization,
   - profile-specific logic leaking into unrelated modules,
   - hardcoded user identity in CI/docs/scripts.
3. Integrate contract checks in `structure` stage.

### Exit Criteria
1. Contract is both documented and machine-checked.
2. Violations fail fast in local + CI structure gates.

## Phase 2: Registry-Driven Extension Points

### Tasks
1. Introduce explicit registries:
   - host registry,
   - desktop profile registry,
   - optional pack registry.
2. Refactor scattered hardcoded mappings to consume registries.
3. Keep flow explicit and review-friendly (no hidden auto-discovery).

### Exit Criteria
1. New extension requires module creation + one registry update.
2. Existing configurations evaluate/build with no behavior regression.

## Phase 3: Profile Interface Normalization

### Tasks
1. Standardize profile contract fields:
   - capabilities,
   - required integrations,
   - optional integrations.
2. Remove ad-hoc branching in shared profile code.
3. Add invariant checks for profile metadata completeness.

### Exit Criteria
1. All active profiles conform to one interface shape.
2. Profile mismatch fails contract checks deterministically.

## Phase 4: Service Pack Composition

### Tasks
1. Define service/app packs as composable units.
2. Move optional desktop tooling decisions into pack selection.
3. Ensure server role remains isolated from desktop packs by contract.

### Exit Criteria
1. Switching optional toolsets does not require shared core edits.
2. Pack changes remain profile/host local.

## Phase 5: Host Scalability Hardening

### Tasks
1. Keep host files thin and declarative.
2. Introduce host descriptor pattern (minimal host identity + selections).
3. Add example skeleton and validation for new host onboarding.

### Exit Criteria
1. New host creation path is deterministic and low-touch.
2. Host drift against descriptor contract fails structure checks.

## Phase 6: Extension-Focused Validation Matrix

### Tasks
1. Generate profile/host matrix checks from registries.
2. Add synthetic extension checks:
   - temporary host descriptor eval,
   - temporary profile registration eval.
3. Keep checks non-flaky and fast for PR use.

### Exit Criteria
1. Matrix coverage auto-updates when registries change.
2. Extension regressions are caught before merge.

## Phase 7: Deprecation + Migration Safety

### Tasks
1. Add a deprecation pattern for options/paths:
   - alias,
   - warning,
   - removal target.
2. Add migration guard to prevent silent hard removals.
3. Document required migration playbook.

### Exit Criteria
1. Breaking extension changes must carry migration path.
2. Removal without migration fails checks.

## Phase 8: Final Validation and Handoff

### Tasks
1. Re-run full validation and runtime smoke.
2. Compare baseline vs final extension touch metrics.
3. Update docs:
   - `docs/for-agents/001-repo-map.md`
   - `docs/for-agents/006-validation-and-safety-gates.md`
   - `docs/for-agents/999-lessons-learned.md`
   - relevant `docs/for-humans/*` extension guidance.
4. Record final evidence and deviations in this plan.

### Exit Criteria
1. Extensibility metrics improved against Phase 0 baseline.
2. Reliability/regression-prevention checks remain green.
3. Documentation matches actual workflows and commands.

## Commit Strategy
1. One logical commit per phase or tightly coupled sub-phase.
2. Commit message pattern: `feat(extensibility): <phase intent>`.
3. Include short evidence summary in commit body.

## Rollback Strategy
1. Revert only last failing slice.
2. Do not revert unrelated user changes.
3. Keep migration shims when unsure; remove only with proof + green gates.

## Execution Checklist (Per Slice)
1. State intended change and risk.
2. Implement smallest coherent diff.
3. Run mandatory validation set.
4. Capture evidence in `reports/nixos/artifacts/929-extensibility/`.
5. Commit only when all required gates pass.

## Phase Status
1. 2026-03-03: Phase 0 completed.
2. Baseline artifacts captured in `reports/nixos/artifacts/929-extensibility/`:
   - `00-baseline-meta.txt`
   - `01-add-host-touch-surface.txt`
   - `02-add-profile-touch-surface.txt`
   - `03-add-pack-touch-surface.txt`
   - `04-baseline-friction-summary.txt`
3. Baseline findings:
   - Host extension currently requires at least `flake.nix` + `hosts/<host>/default.nix`.
   - Desktop profile extension currently requires at least 4 tracked edits (profile module, desktop import list, profile enum, capability map).
   - Optional pack extension is lower friction (2-3 edits depending on capability needs).
4. 2026-03-03: Phase 1 completed.
5. Phase 1 changes:
   - Added extension contract doc: `docs/for-agents/012-extensibility-contracts.md`.
   - Added machine checker: `scripts/check-extension-contracts.sh`.
   - Integrated into structure gates via `scripts/run-validation-gates.sh`.
   - Linked contract doc from `000-operating-rules.md`, `001-repo-map.md`, and enforcement docs.
6. Phase 1 validation evidence:
   - `shellcheck scripts/check-extension-contracts.sh`: PASS
   - `./scripts/check-changed-files-quality.sh origin/main`: PASS
   - `./scripts/run-validation-gates.sh structure`: PASS
   - `./scripts/run-validation-gates.sh predator`: PASS
   - `./scripts/run-validation-gates.sh server-example`: PASS
   - `./scripts/check-repo-public-safety.sh`: PASS
7. 2026-03-03: Phase 2 slice 1 completed (host/profile registries).
8. Phase 2 slice 1 changes:
   - Added desktop profile registry: `modules/profiles/desktop/profile-registry.nix`.
   - Refactored desktop profile aggregator to consume profile registry.
   - Refactored desktop profile option enum to derive from profile registry names.
   - Refactored `flake.nix` host wiring into explicit `hostRegistry` + `mapAttrs` composition.
   - Updated extension contract checks for registry-based model.
9. Phase 2 slice 1 validation evidence:
   - `shellcheck scripts/check-extension-contracts.sh`: PASS
   - `./scripts/check-changed-files-quality.sh origin/main`: PASS
   - `./scripts/run-validation-gates.sh structure`: PASS
   - `./scripts/run-validation-gates.sh predator`: PASS
   - `./scripts/run-validation-gates.sh server-example`: PASS
   - `./scripts/check-repo-public-safety.sh`: PASS
10. 2026-03-03: Phase 2 slice 2 completed (optional pack registry).
11. Phase 2 slice 2 changes:
    - Added optional desktop pack registry: `home/user/desktop/pack-registry.nix`.
    - Refactored `home/user/desktop/default.nix` imports to compose through pack-registry-managed packs.
    - Extended `scripts/check-extension-contracts.sh` to enforce pack registry wiring/integrity.
12. Phase 2 slice 2 validation evidence:
    - `shellcheck scripts/check-extension-contracts.sh`: PASS
    - `./scripts/check-changed-files-quality.sh origin/main`: PASS
    - `./scripts/run-validation-gates.sh structure`: PASS
    - `./scripts/run-validation-gates.sh predator`: PASS
    - `./scripts/run-validation-gates.sh server-example`: PASS
    - `./scripts/check-repo-public-safety.sh`: PASS
13. Phase 2 status: COMPLETE (host/profile/pack registries established).
14. 2026-03-03: Phase 3 slice 1 completed (profile metadata normalization).
15. Phase 3 slice 1 changes:
    - Added profile metadata contract file: `modules/profiles/desktop/profile-metadata.nix`.
    - Refactored `modules/profiles/profile-capabilities.nix` to derive capabilities from metadata.
    - Refactored `scripts/check-profile-matrix.sh` to derive profiles and expected capabilities from metadata.
    - Extended `scripts/check-extension-contracts.sh` to enforce profile metadata completeness and wiring.
16. Phase 3 slice 1 validation evidence:
    - `shellcheck scripts/check-extension-contracts.sh scripts/check-profile-matrix.sh`: PASS
    - `./scripts/check-changed-files-quality.sh origin/main`: PASS
    - `./scripts/run-validation-gates.sh structure`: PASS
    - `./scripts/run-validation-gates.sh predator`: PASS
    - `./scripts/run-validation-gates.sh server-example`: PASS
    - `./scripts/check-repo-public-safety.sh`: PASS
17. 2026-03-03: Phase 5 slice 1 completed (host registry consistency guard).
18. Phase 5 slice 1 changes:
    - Extended `scripts/check-extension-contracts.sh` to enforce host directory <-> `flake.nix` `hostRegistry` consistency.
    - Added checks for required `hosts/<host>/default.nix` and corresponding registry path reference.
19. Phase 5 slice 1 validation evidence:
    - `shellcheck scripts/check-extension-contracts.sh`: PASS
    - `./scripts/check-changed-files-quality.sh origin/main`: PASS
    - `./scripts/run-validation-gates.sh structure`: PASS
    - `./scripts/run-validation-gates.sh predator`: PASS
    - `./scripts/run-validation-gates.sh server-example`: PASS
    - `./scripts/check-repo-public-safety.sh`: PASS
20. 2026-03-03: Phase 4 slice 1 completed (pack-set composition).
21. Phase 4 slice 1 changes:
    - Extended `home/user/desktop/pack-registry.nix` with named pack sets.
    - Added profile `packSets` metadata in `modules/profiles/desktop/profile-metadata.nix`.
    - Refactored `home/user/desktop/default.nix` to select/import pack modules by profile metadata pack sets.
    - Extended `scripts/check-extension-contracts.sh` to enforce pack/pack-set/metadata consistency.
22. Phase 4 slice 1 validation evidence:
    - `shellcheck scripts/check-extension-contracts.sh scripts/check-profile-matrix.sh`: PASS
    - `./scripts/check-changed-files-quality.sh origin/main`: PASS
    - `./scripts/run-validation-gates.sh structure`: PASS
    - `./scripts/run-validation-gates.sh predator`: PASS
    - `./scripts/run-validation-gates.sh server-example`: PASS
    - `./scripts/check-repo-public-safety.sh`: PASS
23. 2026-03-03: Phase 6 slice 1 completed (synthetic extension simulation gates).
24. Phase 6 slice 1 changes:
    - Added `scripts/check-extension-simulations.sh` to verify synthetic host/profile extension invariants.
    - Integrated simulation checks into predator validation stage in `scripts/run-validation-gates.sh`.
    - Updated extension and validation docs to include the new gate.
25. Phase 6 slice 1 validation evidence:
    - `shellcheck scripts/check-extension-simulations.sh scripts/run-validation-gates.sh scripts/check-docs-drift.sh scripts/check-extension-contracts.sh`: PASS
    - `./scripts/check-changed-files-quality.sh origin/main`: PASS
    - `./scripts/run-validation-gates.sh structure`: PASS
    - `./scripts/run-validation-gates.sh predator`: PASS
    - `./scripts/run-validation-gates.sh server-example`: PASS
    - `./scripts/check-repo-public-safety.sh`: PASS
