# Low-Risk Mitigation Plan (Post `PASS_WITH_WARNINGS`)

## Baseline
From `reports/system-up-to-date-20260228-104400/`:
1. `R-check-runtime-config-parity-WARN`
2. `R-check-user-services-parity-WARN`
3. `R-nixos-post-switch-smoke-SKIP`
4. `R-validate-host-SKIP`

Current verdict is `PASS_WITH_WARNINGS` with only low-severity findings.

## Objective
Reduce remaining low-risk findings to either:
1. `PASS` (no warnings/skips), or
2. `PASS_WITH_WARNINGS` with explicit, intentional, documented exceptions.

## Guardrails
1. Keep changes minimal and reversible.
2. No broad behavior changes in system/home modules.
3. Run regression checks after each slice:
   - `bash -n scripts/*.sh`
   - `shellcheck scripts/*.sh`
   - `scripts/audit-system-up-to-date.sh --exclude-emacs`

## Plan

### Phase 1: Mutable Runtime Drift (`check-runtime-config-parity`)
1. Confirm current mutable drift in DMS config:
   - compare tracked `config/apps/dms/settings.json` vs live `~/.config/DankMaterialShell/settings.json`.
2. Decide policy for mutable targets (`dms`, `keyrs`):
   - `accept-live-as-current` (update tracked template to current practical baseline), or
   - `keep-template-authoritative` (keep drift warning as intentional).
3. Implement one of:
   - Add `MUTABLE_RUNTIME_WARN_ALLOWLIST` support (path list) so known mutable drift is explicitly documented, or
   - Add report note when drift is expected for mutable targets.
4. Acceptance:
   - warning is either removed or converted into explicit documented exception.

### Phase 2: User Services Parity Drift (`check-user-services-parity`)
1. Verify actual managed unit source with `systemctl --user cat` / `show FragmentPath` for:
   - `awww-daemon.service`
   - `dms-awww.service`
2. If local unmanaged files under `~/.config/systemd/user` are causing noise:
   - prefer declarative fragment checks first (`/nix/store`, `/etc/systemd/user`, `/run/current-system`),
   - only run strict content checks when local files are the active fragment source.
3. If current assertions are outdated:
   - update expected directives in script to match current declarative unit model.
4. Acceptance:
   - `check-user-services-parity.sh` returns `ok` on expected host state,
   - no false-positive warnings for intentionally unmanaged inactive files.

### Phase 3: Skipped Checks (Sudo Context)
1. Add explicit mode to audit/master workflow:
   - default non-interactive (`sudo -n`) keeps safe CI behavior,
   - optional interactive mode for local operator run (e.g. `AUDIT_ALLOW_INTERACTIVE_SUDO=1`).
2. In interactive mode, run:
   - `scripts/nixos-post-switch-smoke.sh`
   - `scripts/validate-host.sh`
3. If interactive mode is not desired, keep skips but document as intentional in report summary.
4. Acceptance:
   - either checks run successfully on target host, or skips are explicitly classified as intentional/non-blocking.

### Phase 4: Documentation Tightening
1. Add a short section to remediation log describing:
   - which low findings were closed,
   - which remained as accepted operational exceptions and why.
2. Record exact env vars for local/private strict checks:
   - `DEV_DOTFILES_EXTRA_REQUIRED`
   - `USER_SERVICES_PARITY_EXTRA_UNITS`
   - `SMOKE_EXTRA_USER_TIMERS`
   - `SMOKE_EXTRA_DOTFILES`
   - `VALIDATE_HOST_TARGET`
   - `STRICT_RUNTIME_MUTABLE_PARITY`

## Suggested Execution Order
1. Phase 1 (runtime mutable drift model).
2. Phase 2 (user service parity false-positive reduction).
3. Phase 3 (interactive sudo mode or intentional skip policy).
4. Full audit re-run and compare against `20260228-104400`.

## Completion Criteria
1. No medium/high findings introduced.
2. Remaining low findings are either fixed or explicitly accepted with rationale.
3. Final report is reproducible with one command:
   - `scripts/audit-system-up-to-date.sh --exclude-emacs`
