# System Up-To-Date Audit Plan (Excluding Emacs)

## Objective
Create an audit-only workflow to verify that the current system state and repo state are aligned, excluding Emacs customization work in progress.

This plan is for the next agent to execute.

## Scope
1. In scope:
   - All tracked scripts under `scripts/*.sh`.
   - Repo decisions/policies in `docs/for-agents/*` and `docs/for-humans/*`.
   - Runtime parity checks already represented by repo scripts.
   - Nix validation/public-safety gates.
2. Out of scope:
   - Any Emacs-specific drift/fixes (`emacs`, `doom`, `spacemacs`, etc.).
   - Refactoring or fixing production modules; only audit/report artifacts and audit scripts may be added.

## Constraints
1. Do not fix config inconsistencies in `hosts/`, `modules/`, `home/`, `pkgs/`, or `config/`.
2. Only produce:
   - Evidence artifacts,
   - A written inconsistency report,
   - A master audit script (plus helper audit scripts if needed).
3. Respect private boundary rules from `007-private-overrides-and-public-safety.md` and `009-private-ops-scripts.md`.

## Required Inputs
1. `AGENT.md`
2. `docs/for-agents/000-operating-rules.md`
3. `docs/for-agents/001-repo-map.md`
4. `docs/for-agents/006-validation-and-safety-gates.md`
5. `docs/for-agents/007-private-overrides-and-public-safety.md`
6. `docs/for-agents/009-private-ops-scripts.md`
7. `docs/for-agents/903-catppuccin-centralization-execution.md`
8. `docs/for-humans/01-repo-philosophy.md`
9. `docs/for-humans/02-decision-framework.md`
10. `docs/for-humans/05-nvim-setup.md` (reference only; skip Emacs checks)

## Current Script Inventory To Audit
1. `scripts/check-declarative-paths.sh`
2. `scripts/check-dev-dotfiles-parity.sh`
3. `scripts/check-dotfiles-parity.sh`
4. `scripts/check-flake-tracked.sh`
5. `scripts/check-logid-parity.sh`
6. `scripts/check-nix-deprecations.sh`
7. `scripts/check-nvim-contract.sh`
8. `scripts/check-repo-public-safety.sh`
9. `scripts/check-runtime-config-parity.sh`
10. `scripts/check-user-services-parity.sh`
11. `scripts/nixos-post-switch-smoke.sh`
12. `scripts/validate-host.sh`

## Deliverables
1. `scripts/audit-system-up-to-date.sh` (master audit orchestrator).
2. Optional helper scripts under `scripts/` (audit-only) when logic is too large for one file.
3. `reports/system-up-to-date-<timestamp>/summary.md`
4. `reports/system-up-to-date-<timestamp>/inconsistencies.md`
5. `reports/system-up-to-date-<timestamp>/scripts-matrix.csv`
6. `reports/system-up-to-date-<timestamp>/raw/` (command outputs).

## Execution Plan

### Phase 1: Build Decision Baseline
1. Extract auditable decisions into a machine-checkable table (`reports/.../raw/decision-baseline.tsv`) with columns:
   - `decision_id`
   - `source_doc`
   - `rule`
   - `expected_pattern`
   - `severity_if_broken`
2. Include at least:
   - shared-vs-private script boundary,
   - five mandatory Nix gates,
   - public-safety requirements,
   - mutable-copy parity caveat,
   - centralized Catppuccin decisions already logged.
3. Mark Emacs-related rules as `excluded`.

### Phase 2: Script Quality + Consistency Audit
1. For each script in `scripts/*.sh`, evaluate:
   - syntax (`bash -n`),
   - lint (`shellcheck`, if available),
   - dependency availability (`command -v` for used tools),
   - hardcoded host/user assumptions,
   - path ownership correctness (repo vs private ops),
   - alignment with current decisions/docs.
2. Produce one row per script in `scripts-matrix.csv`:
   - `script`
   - `status` (`ok|warn|fail`)
   - `classification` (`keep|repair|archive|move-private`)
   - `inconsistency_count`
   - `notes`
3. Flag as inconsistency when script behavior conflicts with documented policy (not merely style differences).

### Phase 3: Runtime/Repo Drift Audit (Non-Destructive)
1. Run safe existing checks through the master orchestrator:
   - `check-repo-public-safety.sh`
   - `check-declarative-paths.sh`
   - `check-nix-deprecations.sh`
   - `check-flake-tracked.sh`
   - `check-dotfiles-parity.sh`
   - `check-dev-dotfiles-parity.sh`
   - `check-runtime-config-parity.sh`
   - `check-user-services-parity.sh`
   - `check-logid-parity.sh`
   - `check-nvim-contract.sh`
   - `validate-host.sh`
   - `nixos-post-switch-smoke.sh` (only on NixOS host and only if non-destructive in current context).
2. Capture stdout/stderr for every check under `reports/.../raw/`.
3. Normalize each check into:
   - `pass`,
   - `warn`,
   - `fail`,
   - `skipped` (with explicit reason).

### Phase 4: Add Master Audit Script
1. Implement `scripts/audit-system-up-to-date.sh` to:
   - create timestamped report directory,
   - run phases in deterministic order,
   - call existing scripts first, then new helper checks,
   - always continue to collect full evidence (no early exit),
   - emit final aggregated status table.
2. Script requirements:
   - `set -euo pipefail` with controlled per-check error capture,
   - `--exclude-emacs` (default enabled),
   - `--strict` to make inconsistencies fail exit code,
   - no destructive operations.
3. New helper scripts (if needed) must be audit-only and documented at top of file.

### Phase 5: Produce Final Report
1. `summary.md` must include:
   - overall verdict (`PASS`, `PASS_WITH_WARNINGS`, `FAIL`),
   - counts by severity,
   - top blockers.
2. `inconsistencies.md` must list each finding with:
   - `id`,
   - `severity`,
   - `location` (file/script/doc),
   - `evidence` (artifact path),
   - `why_inconsistent` (decision conflict),
   - `recommended_action` (proposal only, no fix applied).
3. Separate sections:
   - `Policy mismatches`,
   - `Outdated assumptions`,
   - `Private-boundary violations`,
   - `Runtime parity drift`,
   - `Skipped checks`.

### Phase 6: Validate The Audit Tooling Itself
1. Run `bash -n scripts/audit-system-up-to-date.sh` (and helper scripts).
2. Run the master script once end-to-end.
3. Confirm report files are generated and internally consistent.
4. Do not modify operational config while validating.

## Acceptance Criteria
1. Every current repo script is audited and classified (`keep|repair|archive|move-private`).
2. Every inconsistency is backed by evidence artifact and linked decision source.
3. A reusable master audit script exists and runs the full workflow.
4. Emacs is explicitly excluded from findings and checks.
5. No config fixes are applied; output is report-only plus audit tooling.

## Suggested Command Skeleton
```bash
# 1) Create audit root
ts="$(date +%Y%m%d-%H%M%S)"
out="reports/system-up-to-date-$ts"
mkdir -p "$out/raw"

# 2) Baseline inventories
rg --files scripts | sort > "$out/raw/scripts-list.txt"
rg -n 'emacs|doom|spacemacs' home modules config scripts docs > "$out/raw/emacs-reference-scan.txt" || true

# 3) Run master audit
./scripts/audit-system-up-to-date.sh --exclude-emacs --output "$out"

# 4) Verify generated report set
test -f "$out/summary.md"
test -f "$out/inconsistencies.md"
test -f "$out/scripts-matrix.csv"
```
