# Maintainability Improvement Plan

## Goal
Increase repo maintainability from ~7.5/10 to >=9/10 without changing intended runtime behavior.

## Scope
1. Reduce profile-condition duplication.
2. Reduce `desktop.nix` complexity and blast radius.
3. Make mutable copy-once config management more predictable.
4. Improve multi-host/server readiness.
5. Add validation coverage for profile matrix regressions.

## Non-Goals
1. No desktop profile feature redesign.
2. No compositor migration.
3. No behavior changes unless explicitly requested.

## Guardrails
1. Keep changes in small, reversible slices.
2. Run mandatory five Nix gates after each meaningful slice.
3. Run post-switch smoke checks when session/login behavior is touched.
4. Do not commit real private override files.

## Baseline Problems
1. Desktop profile predicates are duplicated across many files.
2. `modules/profiles/desktop.nix` is a high-coupling module.
3. Mutable config copy-once logic is spread across many activation snippets.
4. Multi-host/server patterns are documented but not fully enforced by structure.

## Target End State
1. Single source of truth for profile capabilities.
2. `desktop` profile logic split into focused modules.
3. Shared helper pattern for mutable copy-once assets with explicit registry.
4. Host role model supports desktop and server paths cleanly.
5. Automated checks catch profile-gating regressions early.

---

## Phase 0: Baseline and Safety Net

### Tasks
1. Create baseline report under `reports/nixos/artifacts/925-maintainability/`:
   - Count duplicated profile predicates (`rg` snapshot).
   - Capture current file sizes for high-coupling files.
   - Capture current gate results.
2. Record known runtime warnings (portal, session) to compare post-refactor.

### Exit Criteria
1. Baseline artifacts exist and are committed (or staged with plan branch work).
2. Mandatory gates pass.

---

## Phase 1: Introduce Profile Capability Matrix

### Design
Add derived booleans from `custom.desktop.profile` so modules stop repeating string comparisons.

### Proposed Additions
1. New module: `modules/profiles/profile-capabilities.nix`.
2. New derived attrs:
   - `config.custom.desktop.capabilities.desktopFiles`
   - `config.custom.desktop.capabilities.niri`
   - `config.custom.desktop.capabilities.hyprland`
   - `config.custom.desktop.capabilities.dms`
   - `config.custom.desktop.capabilities.desktopUserApps`
3. Keep `custom.desktop.profile` enum unchanged.

### Migration Steps
1. Add capability module without changing consumers.
2. Migrate consumers incrementally:
   - `modules/profiles/desktop-files.nix`
   - `home/user/desktop/*` modules with repeated predicates
   - `home/user/services/*` modules with repeated predicates
3. Remove old duplicated predicate expressions only after each module is migrated.

### Exit Criteria
1. No repeated literal profile lists in desktop/home modules except capability source module.
2. All gates pass.
3. Runtime parity: session starts and key user services are healthy.

### Rollback
1. Revert capability consumers slice-by-slice (module-level rollback only).

---

## Phase 2: Split `modules/profiles/desktop.nix`

### Design
Decompose by concern and keep a thin aggregator.

### Proposed Layout
1. `modules/profiles/desktop/default.nix` (aggregator)
2. `modules/profiles/desktop/base.nix` (shared desktop settings)
3. `modules/profiles/desktop/portal.nix` (all portal policy)
4. `modules/profiles/desktop/keyrs.nix` (uinput and related)
5. `modules/profiles/desktop/profile-dms.nix`
6. `modules/profiles/desktop/profile-niri-only.nix`
7. `modules/profiles/desktop/profile-noctalia.nix`
8. `modules/profiles/desktop/profile-dms-hyprland.nix`
9. `modules/profiles/desktop/profile-caelestia-hyprland.nix`

### Migration Steps
1. Move shared/base block first.
2. Move portal block second.
3. Move one profile module at a time.
4. Keep comments and rationale with moved logic.
5. Remove old monolith only after parity checks pass.

### Exit Criteria
1. Aggregator file is small and import-only.
2. Profile-specific logic is isolated by file.
3. All gates pass.
4. Post-switch smoke checks pass.

### Rollback
1. Revert one moved module at a time and return logic to old file if needed.

---

## Phase 3: Mutable Copy-Once Standardization

### Design
Unify copy-once activation snippets under a reusable helper and explicit registry.

### Proposed Additions
1. Helper module, for example:
   - `home/user/lib/mutable-copy.nix`
   - Function pattern: `mkCopyOnce { source; target; mode ? "0644"; }`
2. Registry document:
   - `docs/for-agents/926-mutable-config-registry.md`
   - Columns: target path, source path, owner module, rationale, overwrite policy.

### Migration Targets (first wave)
1. `home/user/desktop/default.nix` (Hyprland copy-once block)
2. `home/user/desktop/shells.nix`
3. `home/user/services/keyrs.nix`
4. `home/user/services/wallpaper.nix`

### Exit Criteria
1. First-wave modules use shared helper.
2. Registry covers all mutable copy-once targets.
3. Gates pass.
4. Runtime files keep expected mutability semantics.

### Rollback
1. Revert module-by-module to old inline activation script.

---

## Phase 4: Multi-Host and Server Readiness

### Design
Make desktop stack opt-in by host role.

### Proposed Additions
1. New option:
   - `custom.host.role = "desktop" | "server"` (default `"desktop"` for current host).
2. Gate desktop imports with role:
   - `modules/profiles/*` desktop-centric modules only when role is desktop.
   - `home/<user>/desktop` imported only for desktop role.
3. Add server host skeleton:
   - `hosts/<server-example>/default.nix` minimal, no desktop profile.

### Exit Criteria
1. Existing host behavior unchanged.
2. Server role can evaluate/build without desktop-only dependencies.
3. Gates pass for desktop host and server skeleton eval/build.

### Rollback
1. Remove role-gating and keep current default desktop-only behavior.

---

## Phase 5: Validation Automation for Profile Matrix

### Design
Add scripted checks so profile regressions are caught before switch/reboot.

### Proposed Additions
1. `scripts/check-profile-matrix.sh`:
   - Evaluate/build for each `custom.desktop.profile` value in isolation.
   - Assert no missing references for profile-gated modules.
2. `scripts/check-desktop-capability-usage.sh`:
   - Fail if duplicated literal profile lists appear outside capability source.
3. Integrate into existing validation flow:
   - Optional in local quick path.
   - Required in full remediation gate script.

### Exit Criteria
1. New scripts run successfully on current host config.
2. Scripts are documented in `006-validation-and-safety-gates.md`.
3. Gates pass.

### Rollback
1. Keep scripts out of required path if flakey; iterate as optional checks first.

---

## Execution Order
1. Phase 0
2. Phase 1
3. Phase 2
4. Phase 3
5. Phase 5
6. Phase 4 (can run earlier if multi-host/server work is urgent)

Reason: reduce predicate drift first, then split modules safely, then standardize mutable handling, then automate regression coverage.

## Validation Checklist Per Slice
1. `nix flake metadata`
2. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
3. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
4. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
5. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
6. If session/login/portal touched:
   - `bash scripts/nixos-post-switch-smoke.sh`
   - `systemctl --user --no-pager --full status xdg-desktop-portal.service`
   - `journalctl --user -b --no-pager | rg -n "portal|greetd|niri|hyprland"`

## Success Metrics
1. Repeated literal profile predicates reduced to near-zero outside capability source.
2. `modules/profiles/desktop.nix` replaced by focused modules.
3. Mutable target registry is complete and referenced by owners.
4. New profile regression scripts pass.
5. Zero increase in session/login regressions during rollout.

## Agent Handoff Notes
1. Work in one phase per branch when possible.
2. Commit each slice with `phase + scope + risk` in message.
3. If unexpected runtime behavior appears, stop and recover access first.
4. Keep this file updated with phase status and deviations.

## Phase Status
1. Phase 0 completed on 2026-03-02.
2. Baseline artifacts generated at `reports/nixos/artifacts/925-maintainability/`:
   - `00-baseline-meta.txt`
   - `01-profile-predicate-raw.txt`
   - `01-profile-predicate-summary.txt`
   - `02-high-coupling-file-sizes.txt`
   - `03-mandatory-gates.txt`
   - `04-runtime-warning-snapshot.txt`
   - `04-runtime-warning-summary.txt`
   - `05-portal-unit-status.txt`
3. Mandatory five gates passed for the current working tree snapshot.
4. Note: `reports/` is gitignored in this repo, so artifacts are local runtime evidence by design.
5. Phase 1 started on 2026-03-02:
   - Added `modules/profiles/profile-capabilities.nix`.
   - Imported capability module in `modules/profiles/default.nix`.
   - Migrated repeated desktop profile-list guards in `home/user/desktop/*`, `home/user/services/{music-client,wallpaper}.nix`, and `modules/profiles/desktop-files.nix` to `custom.desktop.capabilities.*`.
   - Mandatory five gates passed after migration.
6. Phase 1 continuation on 2026-03-02:
   - Updated `modules/profiles/desktop.nix` to consume capabilities for shared niri/dms/hyprland logic.
   - Removed duplicated dsearch and hyprland portal wiring from per-profile blocks by moving them to capability-scoped shared blocks.
   - Mandatory five gates passed after refactor.
   - Capability eval check for current `dms` profile:
     - `desktopFiles=true`
     - `desktopUserApps=true`
     - `niri=true`
     - `hyprland=false`
     - `dms=true`
7. Phase 1 cleanup on 2026-03-02:
   - Added `noctalia` and `caelestiaHyprland` capability booleans.
   - Migrated `home/user/desktop/profile-integrations.nix` to capability checks.
   - Added `scripts/check-desktop-capability-usage.sh` and validated it passes.
   - Updated `006-validation-and-safety-gates.md` optional pattern gates.
   - Mandatory five gates passed after this slice.
8. Phase 2 started on 2026-03-02 (low-risk first split):
   - Moved shared desktop base settings from `modules/profiles/desktop.nix` into `modules/profiles/desktop-base.nix`.
   - Wired new base module through `modules/profiles/default.nix`.
   - Kept behavior unchanged while reducing `desktop.nix` coupling.
   - Mandatory five gates passed after split.
   - Post-checks:
     - portal services active (`xdg-desktop-portal`, `-gtk`, `-gnome`)
     - capability eval remains consistent for current `dms` profile.
9. Phase 2 continuation on 2026-03-02:
   - Extracted shared capability blocks (`niri/hyprland portal policy`, `dsearch`, `keyrs uinput`) into `modules/profiles/desktop-capability-shared.nix`.
   - Reduced `modules/profiles/desktop.nix` to profile-specific behavior only.
   - Mandatory five gates passed after split.
   - Post-checks:
     - `./scripts/check-desktop-capability-usage.sh` passes.
     - portal services remain active.
10. Phase 3 started on 2026-03-02 (helper introduction):
   - Added `home/user/lib/mutable-copy.nix` with `mkCopyOnce`.
   - Migrated copy-once activation blocks to helper in:
     - `home/user/services/keyrs.nix`
     - `home/user/services/wallpaper.nix` (`provisionDmsSettings`)
     - `home/user/desktop/shells.nix` (`provisionNiriCustom`, `provisionCaelestiaSettings`)
   - Mandatory five gates passed after migration.
11. Phase 3 continuation on 2026-03-02:
    - Migrated remaining copy-once blocks to helper in:
      - `home/user/desktop/default.nix` (`copyHyprlandConfigs`)
      - `home/user/desktop/shells.nix` (`provisionNoctaliaSettings`)
      - `home/user/apps/misc.nix` (`provisionFcitx5`)
    - Added `docs/for-agents/926-mutable-config-registry.md` with mutable target inventory and policy.
    - Mandatory five gates passed after migration.
    - Post-checks:
      - `./scripts/check-desktop-capability-usage.sh` passes.
      - portal services remain active.
12. Phase 5 started on 2026-03-02:
    - Added `scripts/check-profile-matrix.sh` to evaluate all desktop profiles (`dms`, `niri-only`, `noctalia`, `dms-hyprland`, `caelestia-hyprland`) using `extendModules`.
    - Script assertions:
      - capability booleans match expected profile behavior
      - system/home drv paths resolve under `/nix/store`
13. Phase 5 continuation on 2026-03-02:
    - Fixed matrix override conflict by applying `lib.mkForce` to `custom.desktop.profile` in the test module.
    - Switched flake loading to `builtins.getFlake "path:${repo_root}"` so the script validates live working-tree content (important when index and unstaged edits diverge).
    - Validation results:
      - `./scripts/check-profile-matrix.sh` passes for all five profiles.
      - `./scripts/check-desktop-capability-usage.sh` passes.
      - Mandatory five gates pass after this slice.
    - Current warnings snapshot:
      - recurring deprecation warning: `xorg.libxcb` renamed to `libxcb`
      - profile-specific warning in matrix run (`niri-only`): `catppuccin.firefox` profile declared while `programs.firefox` is disabled.
14. Phase 4 started on 2026-03-02 (role-model bootstrap):
    - Added new option `custom.host.role = "desktop" | "server"` in `modules/options.nix` (default `desktop`).
    - Set `custom.host.role = "desktop"` explicitly in `hosts/predator/default.nix`.
    - Replaced stale package gate `custom.desktop.profile != "server"` with role-based check `custom.host.role == "desktop"` in `hosts/predator/packages.nix`.
    - Validation results:
      - `./scripts/check-profile-matrix.sh` passes for all five desktop profiles.
      - `./scripts/check-desktop-capability-usage.sh` passes.
      - Mandatory five gates pass after this slice.
15. Phase 4 continuation on 2026-03-02 (desktop-role gating):
    - Gated profile-derived desktop capabilities by host role in `modules/profiles/profile-capabilities.nix`:
      - when `custom.host.role = "server"`, all desktop capability booleans resolve to `false`.
    - Gated desktop system profile modules behind desktop role:
      - `modules/profiles/desktop-base.nix`
      - `modules/profiles/desktop-capability-shared.nix`
      - `modules/profiles/desktop.nix`
    - Gated Home Manager desktop import behind desktop role in `home/user/default.nix`.
    - Updated `scripts/check-profile-matrix.sh` to force `custom.host.role = "desktop"` while testing desktop profiles, keeping matrix checks deterministic across host roles.
    - Targeted verification:
      - desktop host capability eval: desktop flags `true` for `dms` baseline as expected.
      - forced server role capability eval: all desktop capability flags `false`.
    - Validation results:
      - `./scripts/check-profile-matrix.sh` passes for all five desktop profiles.
      - `./scripts/check-desktop-capability-usage.sh` passes.
      - Mandatory five gates pass after this slice.
16. Phase 4 continuation on 2026-03-02 (server skeleton host):
    - Added `hosts/server-example/default.nix` as a minimal server-role host skeleton:
      - `custom.host.role = "server"`
      - `custom.user.name = "ops"`
      - `boot.isContainer = true`
      - `networking.useHostResolvConf = lib.mkForce false`
      - `nixpkgs.config.allowUnfree = true` (to align with repo package set)
    - Added `nixosConfigurations.server-example` to `flake.nix`.
    - Added repo map note for `hosts/server-example/` in `docs/for-agents/001-repo-map.md`.
    - Validation results:
      - `nix eval path:$PWD#nixosConfigurations.server-example.config.custom.host.role` -> `"server"`
      - `nix eval --json path:$PWD#nixosConfigurations.server-example.config.custom.desktop.capabilities` -> all `false`
      - `nix build --no-link path:$PWD#nixosConfigurations.server-example.config.system.build.toplevel` passes
      - `./scripts/check-profile-matrix.sh` passes
      - `./scripts/check-desktop-capability-usage.sh` passes
      - Mandatory five predator gates pass after this slice.
17. Phase 4 continuation on 2026-03-02 (desktop-module decoupling for server host):
    - Refactored `modules/profiles/desktop.nix` to guard backend-specific options (`programs.niri`, `programs.hyprland`, `programs.dank-material-shell`, `programs.regreet`) behind option-existence checks using `lib.hasAttrByPath`.
    - Refactored `modules/profiles/desktop-capability-shared.nix` to guard `programs.dsearch` on option existence.
    - Kept `mkIf` for config-dependent conditions to avoid fixed-point recursion.
    - Removed Niri/Hyprland/DMS/Home Manager module imports from `nixosConfigurations.server-example` in `flake.nix`; server host now only imports `./hosts/server-example/default.nix`.
    - Validation results:
      - `nix eval path:$PWD#nixosConfigurations.server-example.config.custom.host.role` -> `"server"`
      - `nix eval --json path:$PWD#nixosConfigurations.server-example.config.custom.desktop.capabilities` -> all `false`
      - `nix build --no-link path:$PWD#nixosConfigurations.server-example.config.system.build.toplevel` passes
      - `./scripts/check-profile-matrix.sh` passes
      - `./scripts/check-desktop-capability-usage.sh` passes
      - Mandatory five predator gates pass after this slice.
