# Desktop Decomposition, Option Decoupling, and CI Plan

## Objective
Execute the next high-impact improvements in this exact order:
1. Finish decomposition of desktop profile implementation (`item 3`).
2. Separate option declarations from implementation modules (`item 4`).
3. Add CI validation pipeline (`item 1`).
4. Update docs for humans and for agents.

All phases must be regression-safe and validated after each slice.

## Scope
1. NixOS profile architecture and module boundaries.
2. Option declaration ownership and implementation isolation.
3. Automated validation in CI for desktop/server paths.
4. Documentation parity with final architecture.

## Non-Goals
1. No compositor/profile behavior redesign.
2. No feature removals.
3. No private override changes.

## Branch and Commit Strategy
1. Create a new branch from `main` for this plan.
2. Use small commits per slice (`phase + scope + risk` in message).
3. Do not batch unrelated changes in one commit.
4. If a slice fails validation, revert only that slice and continue.

## Global Safety Rules
1. Keep `custom.desktop.profile` enum unchanged unless explicitly requested.
2. Keep `custom.host.role` contract stable (`desktop|server`).
3. Never commit private overrides (`hosts/*/private*.nix`, `home/*/private*.nix`).
4. Preserve current runtime behavior for Predator.

## Required Validation After Every Meaningful Slice
1. `./scripts/check-desktop-capability-usage.sh`
2. `./scripts/check-profile-matrix.sh`
3. `nix flake metadata`
4. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
5. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
6. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
7. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
8. `nix eval path:$PWD#nixosConfigurations.server-example.config.custom.host.role`
9. `nix eval --json path:$PWD#nixosConfigurations.server-example.config.custom.desktop.capabilities`
10. `nix build --no-link path:$PWD#nixosConfigurations.server-example.config.system.build.toplevel`

## Phase A: Finish Desktop Module Decomposition (Item 3)

### A1. Create Desktop Aggregator Directory Layout
1. Introduce `modules/profiles/desktop/` with:
   - `default.nix` (aggregator)
   - `base.nix`
   - `capability-shared.nix`
   - `profile-dms.nix`
   - `profile-niri-only.nix`
   - `profile-noctalia.nix`
   - `profile-dms-hyprland.nix`
   - `profile-caelestia-hyprland.nix`
2. Move logic incrementally from existing files; no behavior changes.
3. Keep old files as shims only during migration (short-lived).

### A2. Migrate in Safe Slices
1. Slice 1: move base desktop settings.
2. Slice 2: move shared capability settings.
3. Slice 3: move one profile per commit (`dms`, `niri-only`, `noctalia`, `dms-hyprland`, `caelestia-hyprland`).
4. Slice 4: remove old monolith/shims only after full parity checks.

### A3. Phase Exit Criteria
1. `modules/profiles/desktop.nix` no longer carries profile logic (or is removed).
2. Aggregator imports focused modules only.
3. All required validation gates pass.

## Phase B: Separate Option Declarations from Implementations (Item 4)

### B1. Split Option Ownership
1. Add dedicated option-declaration modules under `modules/options/`:
   - `core-options.nix` (`custom.user.name`, `custom.host.role`)
   - `desktop-options.nix` (`custom.desktop.profile`, `custom.desktop.keyrs.enable`)
   - `desktop-capabilities-options.nix` (readonly capability attrs only)
2. Keep implementation modules free of option declarations.

### B2. Reduce Hidden Cross-Module Coupling
1. For integrations depending on optional providers (DMS, Niri, Hyprland, dsearch), keep explicit option-existence guards.
2. Prefer provider-aware checks in implementation modules rather than implicit flake import assumptions.
3. Ensure server host evaluates/builds with minimal module imports.

### B3. Add Structure Guard
1. Add script `scripts/check-option-declaration-boundary.sh`.
2. Rule: implementation paths (`modules/profiles/**`, `home/**`) must not declare `options.*`.
3. Allowlist only `modules/options/**`.

### B4. Phase Exit Criteria
1. Option declarations are centralized by ownership.
2. Implementation files define `config` only.
3. New option-boundary script passes.
4. All required validation gates pass.

## Phase C: CI Automation (Item 1)

### C1. Add CI Workflow
1. Add `.github/workflows/validate.yml` with jobs:
   - `lint-structure` (capability usage + option-boundary checks)
   - `predator-eval-build`
   - `server-example-eval-build`
2. Ensure each job uses deterministic Nix setup and cache.
3. Fail fast on first gate failure.

### C2. CI Commands
1. Structure checks:
   - `./scripts/check-desktop-capability-usage.sh`
   - `./scripts/check-option-declaration-boundary.sh`
2. Predator gates:
   - mandatory five
   - `./scripts/check-profile-matrix.sh`
3. Server gates:
   - role/capability eval
   - system toplevel build

### C3. Local Repro Script
1. Add `scripts/run-full-validation.sh` mirroring CI sequence.
2. Ensure agent/humans can run one command locally before push.

### C4. Phase Exit Criteria
1. CI workflow passes on branch.
2. Local full-validation script passes.
3. Docs reference CI and local equivalent commands.

## Phase D: Documentation Updates (Humans + Agents)

### D1. For-Agents Docs
1. Update `001-repo-map.md` with final desktop module layout.
2. Update `006-validation-and-safety-gates.md` with new option-boundary check and full-validation script.
3. Update `999-lessons-learned.md` with final architectural lessons from this rollout.
4. Add/refresh execution log with outcomes and known warnings.

### D2. For-Humans Docs
1. Update top-level README (or equivalent human-facing docs) with:
   - host role model (`desktop` vs `server`)
   - how to add a new host
   - how to run validation locally
   - what CI enforces
2. Add short troubleshooting section for known warnings (for example Firefox Catppuccin warning conditions).

### D3. Documentation Exit Criteria
1. Human docs match actual commands and file layout.
2. Agent docs match enforced gates and scripts.
3. No stale references to removed modules/files.

## Rollout and Regression Policy
1. Never merge a slice that fails any required gate.
2. If regression appears, revert last slice and re-validate before proceeding.
3. Keep runtime checks for session/portal when touching desktop launch/portal logic:
   - `bash scripts/nixos-post-switch-smoke.sh`
   - `systemctl --user --no-pager --full status xdg-desktop-portal.service`
   - `journalctl --user -b --no-pager | rg -n "portal|greetd|niri|hyprland"`

## Final Acceptance Criteria
1. Desktop implementation decomposed into focused modules.
2. Option declarations separated from implementations.
3. CI enforces full validation matrix for Predator + server-example.
4. For-human and for-agent docs are up to date.
5. Zero new runtime regressions compared to baseline behavior.

## Execution Status
1. 2026-03-02: Phase A Slice 1 completed.
2. Introduced `modules/profiles/desktop/` with aggregator + focused modules:
   - `default.nix`
   - `base.nix`
   - `capability-shared.nix`
   - `profile-dms.nix`
   - `profile-niri-only.nix`
   - `profile-noctalia.nix`
   - `profile-dms-hyprland.nix`
   - `profile-caelestia-hyprland.nix`
3. Rewired `modules/profiles/default.nix` to import `./desktop/default.nix`.
4. Kept compatibility shims:
   - `modules/profiles/desktop-base.nix`
   - `modules/profiles/desktop-capability-shared.nix`
   - `modules/profiles/desktop.nix`
5. Updated `scripts/check-desktop-capability-usage.sh` allowlist for new `modules/profiles/desktop/*` layout.
6. Validation results: all required gates pass (capability script, profile matrix, mandatory Predator gates, server-example eval/build).
