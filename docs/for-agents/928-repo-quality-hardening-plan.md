# Repo Quality Hardening Plan

## Objective
Raise maintainability/extensibility with measurable structural improvements and zero accepted regressions.

Execution order is mandatory:
1. Item 3: single validation source of truth.
2. Item 4: script refactor with shared library.
3. Item 1: automated runtime smoke tests.
4. Remaining high-impact improvements.
5. Docs sync for agents and humans.

## Real-Improvement Rule
Each slice must satisfy all of the following:
1. Removes duplication, ambiguity, or hidden coupling.
2. Adds or strengthens an automated guard.
3. Keeps behavior equal or safer than before.
4. Leaves evidence (test output and short changelog notes).

Reject slices that only rename/reformat without reducing risk or improving validation.

## Scope
1. Validation architecture and execution flow (local + CI).
2. Script maintainability and reuse.
3. Runtime/session regression prevention.
4. Structural cleanup and ownership clarity.
5. Documentation fidelity.

## Non-Goals
1. No desktop/profile redesign.
2. No private override changes.
3. No broad feature churn unrelated to maintainability risk.

## Branch and Commit Strategy
1. One focused branch per phase (or per two tightly coupled subphases).
2. One logical commit per slice (`phase + intent + risk`).
3. Run required gates before each commit.
4. If a slice fails, revert only that slice.

## Global Guardrails
1. Keep `custom.desktop.profile` and `custom.host.role` contracts stable.
2. Do not commit `hosts/*/private*.nix` or `home/*/private*.nix`.
3. Keep server-example eval/build green in every phase.
4. Do not remove transition files until import graph proves unused.

## Required Validation Per Meaningful Slice
1. `./scripts/check-desktop-capability-usage.sh`
2. `./scripts/check-option-declaration-boundary.sh`
3. `./scripts/check-profile-matrix.sh`
4. `nix flake metadata`
5. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
6. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name).home.stateVersion`
7. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name).home.path`
8. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
9. `nix eval path:$PWD#nixosConfigurations.server-example.config.custom.host.role`
10. `nix eval --json path:$PWD#nixosConfigurations.server-example.config.custom.desktop.capabilities`
11. `nix build --no-link path:$PWD#nixosConfigurations.server-example.config.system.build.toplevel`
12. `./scripts/check-repo-public-safety.sh`

When desktop/session code is touched, also run:
1. `bash "$PWD/scripts/nixos-post-switch-smoke.sh"`
2. `systemctl --user status xdg-desktop-portal.service --no-pager`
3. `journalctl --user -b --no-pager | rg -n "portal|greetd|niri|hyprland|wayland"`

## Phase 0: Baseline and Success Metrics

### Tasks
1. Create baseline artifact directory: `reports/nixos/artifacts/928-repo-quality/`.
2. Capture:
   - current gate outputs,
   - script count/size map,
   - duplicate logic hotspots,
   - runtime warning snapshot (portal/session).
3. Define measurable targets:
   - duplicated validation command definitions reduced to one source,
   - shell script duplication reduced (shared helpers),
   - runtime smoke checks executable in one command.

### Exit Criteria
1. Baseline artifacts recorded.
2. All required gates pass.

## Phase 1: Item 3 - Single Validation Source of Truth

### Tasks
1. Add a machine-readable validation manifest (example: `config/validation/gates.nix` or `config/validation/gates.json`).
2. Refactor:
   - `scripts/run-full-validation.sh`,
   - `.github/workflows/validate.yml`,
   - docs command lists,
   to consume/generated from the same manifest.
3. Add a guard script that fails if CI/docs/scripts drift from manifest.

### Exit Criteria
1. Validation gates defined once.
2. CI and local runner execute the same gate set.
3. Drift check exists and passes.

### Rollback
1. Revert generator/manifest slice only; keep previous explicit commands.

## Phase 2: Item 4 - Script Refactor with Shared Library

### Tasks
1. Create `scripts/lib/common.sh` for shared primitives:
   - strict shell mode bootstrap,
   - repo-root resolution,
   - structured logging,
   - command runner with clear failure messages.
2. Migrate highest-churn scripts first:
   - `run-full-validation.sh`,
   - `check-profile-matrix.sh`,
   - `check-repo-public-safety.sh`,
   - `check-flake-pattern.sh`.
3. Ensure each migrated script remains standalone executable.
4. Add shell static checks for changed scripts in CI (for example `shellcheck` in dev shell/CI if available).

### Exit Criteria
1. Shared patterns extracted into library.
2. Target scripts use shared helpers and keep behavior parity.
3. Script-level tests/gates pass.

### Rollback
1. Revert script-by-script migration; keep library if harmless.

## Phase 3: Item 1 - Automated Runtime Smoke Tests

### Tasks
1. Add a runtime smoke entrypoint (example: `scripts/check-runtime-smoke.sh`) that verifies:
   - greeter/session reached,
   - compositor user services healthy for active profile,
   - portal stack activated on demand,
   - key user services active (wallpaper/keyrs when enabled).
2. Support profile-aware assertions via `custom.desktop.capabilities`.
3. Add non-flaky log scan rules:
   - treat known benign warnings as allowlisted,
   - fail only on high-confidence regressions.
4. Integrate into post-switch workflow and optional CI stage where feasible.

### Exit Criteria
1. One command reproduces runtime smoke checks.
2. No greeter/session/portal regression slips through local smoke run.
3. Warning allowlist is explicit and reviewed.

### Rollback
1. Keep smoke script optional if flakiness is discovered; iterate and promote again.

## Phase 4: Strengthen Contract Tests (Options/Invariants)

### Tasks
1. Add explicit invariant checks for:
   - host role gating behavior,
   - capability matrix correctness per profile,
   - option declaration boundaries,
   - username indirection (no hardcoded HM username in tracked scripts/CI/docs commands).
2. Add dedicated script: `scripts/check-config-contracts.sh`.
3. Integrate contracts into full validation and CI.

### Exit Criteria
1. Critical invariants are machine-checked.
2. Refactors fail fast when contracts break.

## Phase 5: Remove Legacy Transition Shims

### Tasks
1. Prove no active imports of:
   - `modules/profiles/desktop.nix`
   - `modules/profiles/desktop-base.nix`
   - `modules/profiles/desktop-capability-shared.nix`
2. Remove shim files in one slice.
3. Update references in docs and checks.

### Exit Criteria
1. Single canonical desktop profile path remains.
2. No stale references to removed shims.
3. Full validation passes.

### Rollback
1. Restore shim files if any external/imported path still depends on them.

## Phase 6: Faster Changed-File Quality Gates

### Tasks
1. Add a lightweight changed-files gate script (example: `scripts/check-changed-files-quality.sh`) for PR flow:
   - shell scripts: static checks,
   - Nix files: format/lint checks available in project toolchain.
2. Keep full validation for merges; use changed-files gate for fast feedback.
3. Document local command and CI usage.

### Exit Criteria
1. Fast gate exists and is reliable.
2. Does not replace full validation; complements it.

## Phase 7: Docs Drift Guard + Ownership Boundaries

### Tasks
1. Add docs drift checker:
   - verify referenced scripts/files exist,
   - verify critical command snippets still valid.
2. Add ownership boundary doc:
   - where options can be declared,
   - where profile behavior can live,
   - where host-specific logic can live.
3. Link this boundary doc from `000`, `001`, `006`, and relevant for-humans pages.

### Exit Criteria
1. Docs cannot silently drift on critical operational commands.
2. Ownership boundaries are explicit and enforceable.

## Phase 8: Final Documentation and Handoff

### Tasks
1. Update agent docs:
   - `001-repo-map.md`
   - `006-validation-and-safety-gates.md`
   - `999-lessons-learned.md`
   - this execution plan with outcomes/deviations.
2. Update human docs:
   - `README.md`
   - relevant `docs/for-humans/*` pages for validation/runtime checks.
3. Add a concise release note summarizing:
   - what changed,
   - what is now enforced,
   - how to run full vs fast checks.

### Exit Criteria
1. Docs reflect real commands and real structure.
2. No stale paths/commands in key docs.

## Acceptance Criteria (Project Complete)
1. Validation logic has one source of truth with drift guard.
2. Core scripts share a maintained common library.
3. Runtime smoke checks are automated and trustworthy.
4. Contract checks cover invariants that caused past regressions.
5. Legacy shims removed safely.
6. Fast changed-file checks improve contributor feedback time.
7. Agent and human docs are updated and validated.
8. Full validation and runtime smoke evidence are attached to final change.

## Agent Execution Checklist Per Slice
1. State intended risk and expected behavior change (usually none).
2. Implement minimal code change.
3. Run required validation set.
4. Record concise evidence in commit message/body or execution log.
5. If regression appears, revert slice and add note in this plan.

## Phase Status
1. 2026-03-03: Phase 0 completed.
2. Baseline artifacts created at `reports/nixos/artifacts/928-repo-quality/`:
   - `00-baseline-meta.txt`
   - `01-script-size-map.txt`
   - `02-duplication-hotspots.txt`
   - `03-runtime-warning-snapshot.txt`
   - `04-full-validation.txt`
   - `05-public-safety.txt`
   - `06-metrics-targets.txt`
3. Validation status:
   - `./scripts/run-full-validation.sh`: PASS
   - `./scripts/check-repo-public-safety.sh`: PASS
4. Baseline warnings captured for future comparison:
   - `xdg-desktop-portal` realtime `pidns` warnings (`Could not get pidns ...`).
   - `xorg.libxcb` deprecation warning during evaluation.
   - Firefox Catppuccin warning in `niri-only` profile matrix evaluation.
5. Note: `reports/` artifacts are local runtime evidence (gitignored) by design.
6. 2026-03-03: Phase 1 completed (single validation source of truth).
7. Validation source-of-truth changes:
   - Added canonical stage runner: `scripts/run-validation-gates.sh`.
   - Updated `scripts/run-full-validation.sh` to delegate to canonical runner (`all`).
   - Updated CI workflow `.github/workflows/validate.yml` jobs to call stage runner (`structure`, `predator`, `server-example`).
   - Added drift guard: `scripts/check-validation-source-of-truth.sh`.
8. Validation status after Phase 1:
   - `./scripts/check-validation-source-of-truth.sh`: PASS
   - `./scripts/run-validation-gates.sh structure`: PASS
   - `./scripts/run-full-validation.sh`: PASS
   - `./scripts/check-repo-public-safety.sh`: PASS
9. 2026-03-03: Phase 2 slice 1 completed (shared script library).
10. Phase 2 changes:
    - Added shared helper library: `scripts/lib/common.sh`.
    - Migrated high-churn scripts to shared helpers:
      - `scripts/run-validation-gates.sh`
      - `scripts/check-validation-source-of-truth.sh`
      - `scripts/check-profile-matrix.sh`
      - `scripts/check-repo-public-safety.sh`
      - `scripts/check-flake-pattern.sh`
      - `scripts/run-full-validation.sh`
    - Preserved behavior while reducing duplicated bootstrap and failure logging patterns.
11. Phase 2 validation evidence:
    - `shellcheck` on migrated scripts: PASS
    - `./scripts/check-validation-source-of-truth.sh`: PASS
    - `./scripts/check-flake-pattern.sh`: PASS
    - `./scripts/run-validation-gates.sh structure`: PASS
    - `./scripts/run-full-validation.sh`: PASS
    - `./scripts/check-repo-public-safety.sh`: PASS
