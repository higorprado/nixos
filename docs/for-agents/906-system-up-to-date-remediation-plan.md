# System Up-To-Date Remediation Plan (Post-Audit)

## Source Baseline
This plan is based on:
1. `reports/system-up-to-date-20260228-100558/summary.md`
2. `reports/system-up-to-date-20260228-100558/inconsistencies.md`
3. `reports/system-up-to-date-20260228-100558/scripts-matrix.csv`

Audit scope excluded Emacs; this remediation plan keeps the same exclusion.

## Objective
Fix script/policy inconsistencies found by the audit while preserving current system behavior and private-boundary rules.

## Execution Policy
1. One script family per slice.
2. After each slice, run:
   - `bash -n` + `shellcheck` on changed scripts.
   - `scripts/audit-system-up-to-date.sh --exclude-emacs`.
3. Do not make broad refactors; prefer minimal, reversible fixes.

## Priority Order
1. High severity policy issues (`P001`, `P002`).
2. Medium severity correctness/model issues (`P004`, `P005`, `P003`).
3. Low severity portability/quality issues (`P006`, shellcheck finding in smoke script).
4. Runtime drifts (`R-*`) after script logic is corrected.

## Work Plan

### Phase 1: Remove Private-Boundary Violations (High)
1. `scripts/check-dev-dotfiles-parity.sh` (`P001`)
   - Remove hardcoded personal host check (`cerebelo`) from shared script.
   - Convert personal file expectations (`~/.ssh/config`, `~/.gitconfig`) into optional checks or externalized list via env var.
   - Keep generic dev checks only.
2. `scripts/check-user-services-parity.sh` (`P002`)
   - Remove private endpoint-specific units from default unit list (`backup-*-cerebelo`).
   - Support opt-in extra units via env var (for local/private overlays).
3. Acceptance criteria:
   - No personal host/endpoint naming in default shared path.
   - Audit no longer reports `P001`/`P002`.

### Phase 2: Fix Detection Model Gaps (Medium)
1. `scripts/check-dotfiles-parity.sh` (`P004`)
   - Change discovery from top-level `home/<user>/*.nix` to recursive scan under `home/<user>/`.
   - Preserve current output format.
2. `scripts/check-runtime-config-parity.sh` (`P005`)
   - Introduce mutable-target handling:
     - immutable targets stay `fail` on mismatch;
     - mutable copy-once targets report `warn` drift.
   - Define mutable targets inline or from a small data table in script.
3. Acceptance criteria:
   - Audit no longer reports `P004`/`P005`.
   - Runtime parity output clearly distinguishes `fail` vs `warn` by ownership model.

### Phase 3: Separate Shared vs Personal Smoke Coverage (Medium)
1. `scripts/nixos-post-switch-smoke.sh` (`P003`)
   - Keep shared system checks in this script.
   - Move personal app checks (`claude`, `crush`, endpoint-specific backup timers) behind optional flags/env vars, default off.
2. Acceptance criteria:
   - Shared script runs without personal assumptions.
   - Audit no longer reports `P003`.

### Phase 4: Portability and Quality Cleanup (Low)
1. `scripts/validate-host.sh` (`P006`)
   - Add configurable host target, e.g. `--host <name>` or `VALIDATE_HOST_TARGET`.
   - Keep current default for backward compatibility.
2. `scripts/nixos-post-switch-smoke.sh` shellcheck (`S-SHC-*`)
   - Replace `A && B || C` pattern with explicit `if/then/else`.
3. Acceptance criteria:
   - Audit no longer reports `P006`.
   - Shellcheck clean for modified scripts.

### Phase 5: Resolve Runtime Drift Findings
1. `R-check-flake-tracked-FAIL`
   - Track intended new scripts/docs or adjust audit process so planned-untracked artifacts do not invalidate expected checks.
2. `R-check-runtime-config-parity-FAIL`
   - After Phase 2 ownership-model fix, reevaluate whether this becomes `warn` (mutable drift) or remains real `fail`.
3. `R-*-WARN` findings
   - Review each warning and decide: promote to fail, keep warning, or mark documented exception.
4. `R-*-SKIP`
   - Execute skipped checks in a context with needed privileges (`sudo -n` or interactive run).

## Validation Gates (Per Phase)
1. `bash -n scripts/*.sh` (or changed subset)
2. `shellcheck <changed scripts>`
3. `scripts/check-repo-public-safety.sh`
4. `scripts/audit-system-up-to-date.sh --exclude-emacs`
5. Nix gates from `docs/for-agents/006-validation-and-safety-gates.md` when meaningful Nix-impacting files are changed.

## Completion Criteria
1. Audit summary verdict becomes `PASS_WITH_WARNINGS` or `PASS` with no high-severity findings.
2. `P001` and `P002` are fully closed.
3. Script matrix classifications remain explicit and justified.
4. Remaining warnings/skips are documented with owner decision and rationale.

## Suggested Slice Order (Exact)
1. Fix `check-dev-dotfiles-parity.sh`.
2. Fix `check-user-services-parity.sh`.
3. Fix `check-dotfiles-parity.sh`.
4. Fix `check-runtime-config-parity.sh`.
5. Fix `nixos-post-switch-smoke.sh`.
6. Fix `validate-host.sh`.
7. Re-run full audit and publish `reports/system-up-to-date-<new-timestamp>/`.
