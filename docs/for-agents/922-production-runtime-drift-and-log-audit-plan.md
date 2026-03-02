# Production Runtime Drift and Log Audit Plan (Emacs Excluded)

## Objective
Produce a comprehensive, evidence-backed report of:
1. Runtime errors/warnings in production logs.
2. Drift between production state and this repo's declarative state.
3. Items present in production but not represented in repo-managed configuration.

This plan is execution-only for the next agent. Do not apply fixes during audit.

## Scope
1. In scope:
   - Host `predator` and its Home Manager user from this repo.
   - System and user logs (current boot and previous boot when available).
   - Runtime-vs-repo drift for system build, home build, services, managed files, and package surfaces.
   - Existing shared audit scripts under `scripts/`.
2. Out of scope:
   - Any Emacs/Doom/Spacemacs setup drift or errors.
   - Refactors or remediation changes in `hosts/`, `modules/`, `home/`, `pkgs/`, `config/`.

## Hard Constraints
1. Follow `AGENTS.md` first reads and safety rules.
2. Respect private boundary rules from:
   - `docs/for-agents/007-private-overrides-and-public-safety.md`
   - `docs/for-agents/009-private-ops-scripts.md`
3. No destructive operations.
4. Audit is report-only: collect evidence, classify findings, recommend actions; do not change runtime state.

## Emacs Exclusion Policy
1. Exclude findings whose primary subject is Emacs stack setup, including keywords:
   - `emacs`, `doom`, `spacemacs`, `elisp`, `org-mode`.
2. Keep raw evidence unfiltered in artifacts, but tag these as `excluded-emacs` in normalized findings.
3. Never count excluded Emacs findings in severity totals.

## Deliverables
1. `reports/production-audit-<timestamp>/summary.md`
2. `reports/production-audit-<timestamp>/findings.md`
3. `reports/production-audit-<timestamp>/drift-matrix.csv`
4. `reports/production-audit-<timestamp>/inventory/`
5. `reports/production-audit-<timestamp>/logs/`
6. `reports/production-audit-<timestamp>/raw/`

## Report Schema Requirements
1. Every finding must include:
   - `id`
   - `severity` (`critical|high|medium|low|info|excluded-emacs`)
   - `category`
   - `location`
   - `evidence_path`
   - `impact`
   - `why_it_matters`
   - `suggested_follow_up` (proposal only)
2. Findings categories:
   - `boot-or-service-errors`
   - `user-session-errors`
   - `deployment-drift`
   - `home-drift`
   - `runtime-config-drift`
   - `unmanaged-services`
   - `unmanaged-packages`
   - `repo-integrity`
   - `private-boundary`
   - `skipped-check`

## Execution Plan

### Phase 1: Initialize Audit Workspace
1. Create timestamped output root:
   - `out="reports/production-audit-$(date +%Y%m%d-%H%M%S)"`
2. Create subdirs:
   - `logs`, `inventory`, `raw`.
3. Write `raw/context.txt` with:
   - hostname
   - user
   - date/time
   - kernel
   - nix version
   - git branch and commit

### Phase 2: Baseline Repo and Policy Health
1. Run and capture existing script checks first:
   - `scripts/audit-system-up-to-date.sh --exclude-emacs --output "$out/raw/system-up-to-date"`
2. Run and capture public safety:
   - `scripts/check-repo-public-safety.sh`
3. Run mandatory Nix gates and capture output:
   - `nix flake metadata`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.user.home.stateVersion`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.user.home.path`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
4. Record git drift:
   - `git status --porcelain=v1`
   - `git ls-files --others --exclude-standard`
   - Classify critical untracked via same rules as `check-flake-tracked.sh`.

### Phase 3: Capture Production Runtime State
1. Systemd baseline:
   - `systemctl --failed`
   - `systemctl --user --failed`
   - `systemctl list-unit-files --state=enabled`
   - `systemctl --user list-unit-files --state=enabled`
2. Unit provenance inventory:
   - For each enabled unit, capture `FragmentPath`.
   - Mark unit as unmanaged when fragment is outside `/nix/store`, `/etc/systemd`, `/run/current-system`.
3. Runtime profiles:
   - `readlink -f /run/current-system`
   - `nixos-rebuild list-generations`
   - `readlink -f /nix/var/nix/profiles/per-user/$USER/home-manager` (if exists)
   - `home-manager generations` (if available)
4. Package surfaces not guaranteed by repo:
   - `nix profile list`
   - `nix-env -q` (if command exists)
   - Capture as potential unmanaged package surfaces.

### Phase 4: Deep Log/Error Analysis
1. Collect system journal (priority 0..4):
   - `journalctl -b -p 0..4 --no-pager`
   - `journalctl -b -1 -p 0..4 --no-pager` (if available)
2. Collect user journal (priority 0..4):
   - `journalctl --user -b -p 0..4 --no-pager`
   - `journalctl --user -b -1 -p 0..4 --no-pager` (if available)
3. Collect kernel log signal:
   - `dmesg --level=err,warn` (if permitted)
4. Normalize log findings:
   - Extract unique failing units, repeated error patterns, crash loops, permission failures, missing binary errors.
   - Tag each entry with boot scope (`current`, `previous`, `user-current`, `user-previous`, `kernel`).
5. Apply Emacs exclusion tagging during normalization, not during raw capture.

### Phase 5: Production vs Repo Drift Analysis
1. Deployment drift (system):
   - Build expected toplevel path:
     - `expected_system=$(nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.system.build.toplevel)`
   - Capture actual:
     - `actual_system=$(readlink -f /run/current-system)`
   - Compare:
     - if different: `nix store diff-closures "$actual_system" "$expected_system"` (if available)
2. Home drift (user):
   - Build expected home path:
     - `expected_home=$(nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.user.home.path)`
   - Compare with active Home Manager profile symlink.
   - Use closure diff when supported.
3. Managed file parity:
   - Run existing:
     - `scripts/check-dotfiles-parity.sh`
     - `scripts/check-dev-dotfiles-parity.sh`
     - `scripts/check-runtime-config-parity.sh`
     - `scripts/check-user-services-parity.sh`
     - `scripts/check-logid-parity.sh`
   - Distinguish mutable copy-once drifts as `warn` unless script marks hard failure.
4. Unmanaged runtime artifacts:
   - Enumerate user enabled unit symlinks in:
     - `~/.config/systemd/user/*.wants/`
   - Flag links resolving to user-local unit files not represented in repo declarations.
   - Enumerate executables in `$HOME/.local/bin` and classify as unmanaged unless referenced by private-boundary policy.

### Phase 6: Normalize, De-duplicate, and Score Findings
1. Build normalized table (`raw/findings.tsv`) from all checks.
2. De-duplicate repeated log lines into one finding with count and sample evidence.
3. Severity rubric:
   - `critical`: boot/login blockers, repeated service crash loops for core desktop/network.
   - `high`: deployment/profile drift, failed essential services, hard parity failures.
   - `medium`: non-critical service failures, unmanaged enabled services, recurring warnings.
   - `low`: one-off warnings, optional tool missing, context limitations.
   - `info`: clean checks and non-actionable context.
4. Add `excluded-emacs` tag and remove from totals.

### Phase 7: Build Comprehensive Report
1. `summary.md` must include:
   - overall verdict (`PASS`, `PASS_WITH_WARNINGS`, `FAIL`)
   - totals by severity (excluding Emacs)
   - top 10 actionable findings
   - explicit skipped checks and reason
2. `findings.md` sections:
   - Executive context
   - Boot/service failures
   - User session failures
   - Production-vs-repo drift
   - Unmanaged artifacts present in production
   - Private boundary observations
   - Excluded Emacs findings (separate appendix)
3. `drift-matrix.csv` minimum columns:
   - `surface`
   - `actual`
   - `expected`
   - `status` (`match|drift|unknown|skipped`)
   - `severity`
   - `evidence_path`
   - `notes`

### Phase 8: Quality Gate for the Audit Output
1. Verify all expected deliverables exist.
2. Verify every non-info finding has evidence file path.
3. Verify Emacs exclusions are listed but not counted in totals.
4. Verify report explicitly states what was not assessed due to privilege/tool limits.

## Command Discipline
1. Prefer non-destructive read-only commands.
2. If a command requires elevated permissions and cannot run, mark as `skipped-check` with reason.
3. Continue gathering evidence even when a check fails.

## Acceptance Criteria
1. Report includes both log-error analysis and production-vs-repo drift analysis.
2. Findings are evidence-backed and severity-scored.
3. Unmanaged production artifacts are explicitly listed.
4. Emacs findings are excluded from totals and clearly documented.
5. No runtime/config remediation is performed during audit.

