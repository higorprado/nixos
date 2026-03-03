# Production Runtime Drift Remediation Plan (Test-Gated, Emacs Excluded)

## Objective
Fix every actionable issue from `reports/production-audit-20260302-104415/` with strict test gates.

No fix is considered done until:
1. The issue-specific new test passes.
2. Targeted runtime verification passes.
3. Regression gates pass.

## Source Findings
Primary findings source:
1. `reports/production-audit-20260302-104415/raw/findings.tsv`
2. `reports/production-audit-20260302-104415/summary.md`
3. `reports/production-audit-20260302-104415/raw/log-signal-counts.tsv`
4. `reports/production-audit-20260302-104415/drift-matrix.csv`

Findings in scope:
1. `PLOG-001`..`PLOG-008`
2. `DRFT-002`, `DRFT-004`
3. `REPO-001`, `REPO-002`
4. `SKIP-001`, `SKIP-002`

Emacs exclusions:
1. Keep `EXCL-*` out of severity/pass-fail decisions.

## Constraints
1. Follow `AGENTS.md` safety and private-boundary rules.
2. Do not edit private overrides without explicit user approval.
3. Use small reversible slices, one issue-group at a time.
4. Capture evidence for every test under `reports/production-remediation-<timestamp>/`.
5. If an issue is proven to be external/transitive and not fixable in repo, record it as `accepted-with-evidence` plus a watchdog test.

## Required New Tests (Create First)
Create these test scripts before remediation slices:
1. `scripts/check-session-log-health.sh`
2. `scripts/check-home-profile-drift.sh`
3. `scripts/check-user-units-coverage.sh`
4. `scripts/check-runtime-observability.sh`

### Test 1: `check-session-log-health.sh`
Purpose:
1. Fail on recurring high-signal session/runtime errors.

Required checks:
1. `dsearch.service: Failed with result 'exit-code'` count must be `0`.
2. `Configuration file /etc/systemd/user/dsearch.service is marked executable` count must be `0`.
3. `Theme parsing error:` count must be `0`.
4. `wp-state: failed to create directory /var/empty/.local/state/wireplumber` count must be `0`.
5. `Realtime error: Could not get pidns` must be below an explicit threshold (start with `<= 5` per boot; tighten to `0` once root cause fixed).
6. `A backend call failed: Inhibiting other than idle not supported` must be below explicit threshold (same policy as above).
7. `Detected another IPv4 mDNS stack` count must be `0`.
8. `Unknown group "netdev"` count must be `0`.
9. `gkr-pam: unable to locate daemon control file` count must be `0`.
10. `error setting IPv4 forwarding to '1'` count must be `0` or documented known-benign threshold.

Execution contract:
1. Support `--boot current|previous`.
2. Emit machine-readable TSV counts and non-zero exit on violation.

### Test 2: `check-home-profile-drift.sh`
Purpose:
1. Fail if active Home Manager `home-path` differs from repo-evaluated `home.path`.

Required checks:
1. Resolve active HM generation symlink.
2. Resolve active `home-path` symlink from generation.
3. Build expected `home.path` from flake using detected HM username.
4. Fail when paths differ.
5. On mismatch, write `nix store diff-closures` artifact.

### Test 3: `check-user-units-coverage.sh`
Purpose:
1. Detect enabled user units that are unmanaged or unexplained.

Required checks:
1. Enumerate enabled user units via `systemctl --user list-unit-files --state=enabled`.
2. Build declared units inventory from evaluated Nix/Home Manager config outputs (not simple text grep only).
3. Compare enabled units to declared units.
4. Maintain explicit allowlist for implicit/system-provided user units.
5. Fail on undeclared non-allowlisted custom units.

### Test 4: `check-runtime-observability.sh`
Purpose:
1. Ensure audit observability checks can run in the chosen execution context.

Required checks:
1. Validate kernel log access path: prefer `journalctl -k -p 0..4`; fall back to `dmesg` when allowed.
2. Mark fail only when neither path is available.
3. This closes `SKIP-001`.

## Global Test Gates (Run After Every Slice)
After each remediation slice, run:
1. `bash -n` and `shellcheck` for changed scripts.
2. Relevant new test script(s) for that slice.
3. `scripts/check-repo-public-safety.sh`.
4. Mandatory Nix gates when Nix files changed:
   - `nix flake metadata`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<detected-user>.home.stateVersion`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<detected-user>.home.path`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
5. `scripts/check-session-log-health.sh --boot current`.

## Slice Plan (Ordered)

### Slice 0: Harness and Baseline
Goal:
1. Add the four new tests and capture a baseline fail/pass matrix.

Steps:
1. Implement all four scripts with clear exit codes and artifact outputs.
2. Add a runner script `scripts/run-production-remediation-gates.sh` to execute them consistently.
3. Run baseline and save outputs under `reports/production-remediation-<ts>/baseline/`.

Done criteria:
1. All new tests run successfully (even if some fail findings).
2. Baseline status is recorded and reproducible.

### Slice 1: Fix `PLOG-001` (`dsearch` failures + executable-bit warning)
Goal:
1. Stop repeated `dsearch.service` failures and executable permission warning.

Steps:
1. Identify authoritative source of `dsearch.service` (`systemctl --user cat dsearch.service`).
2. If generated by tracked Nix config, fix service command/ordering and enforce file mode `0644`.
3. If generated by private/runtime layer, move correction to the right owner (private script/override) and document boundary.
4. Reload and restart user daemon/services.

Issue-specific tests:
1. `systemctl --user is-active dsearch.service` must be active.
2. `journalctl --user -b -u dsearch.service --no-pager` must show zero new failures after restart.
3. `check-session-log-health.sh --boot current` must return zero for both dsearch patterns.

Done criteria:
1. No dsearch failure/warning counts in current boot.

### Slice 2: Fix `PLOG-002` (portal log storm)
Goal:
1. Remove sustained `xdg-desktop-portal` error storm.

Steps:
1. Confirm active portal stack and backend ordering for current profile (`dms`/Niri).
2. Adjust portal backend config and service ordering/restart policy to avoid PID namespace and inhibit spam.
3. Restart portal services and user session components safely.

Issue-specific tests:
1. `systemctl --user is-active xdg-desktop-portal.service`.
2. `systemctl --user is-active xdg-desktop-portal-gtk.service`.
3. `check-session-log-health.sh --boot current` portal counters below threshold.
4. Smoke open portal-dependent app action (file chooser/screenshot or `xdg-open`) with no new portal errors.

Done criteria:
1. Portal error counters meet defined threshold (target `0`, temporary threshold allowed only with explicit rationale).

### Slice 3: Fix `PLOG-003` (theme parse errors)
Goal:
1. Eliminate recurring theme parse errors caused by stale local theme assets/imports.

Steps:
1. Keep Catppuccin/module options as source of truth.
2. Remove stale local theme assets and references under `config/themes`.
3. Rebuild/switch relevant home config.

Issue-specific tests:
1. Verify there are no tracked references to deleted local theme assets.
2. Launch representative themed app and check journal for zero new theme parse errors.
3. `check-session-log-health.sh --boot current` reports zero `Theme parsing error:` findings.

Done criteria:
1. No recurring theme parse error in current boot.

### Slice 4: Fix `PLOG-004` (WirePlumber state path + coredump)
Goal:
1. Ensure WirePlumber runs with valid runtime/state paths and no fresh crash signal.

Steps:
1. Determine whether system or user WirePlumber instance is producing `/var/empty` path.
2. Correct service ownership/env/path configuration so HOME/state are user-writable and expected.
3. Ensure only intended WirePlumber instance is enabled.

Issue-specific tests:
1. `systemctl --user show wireplumber.service -p Environment` and/or service env inspection validates HOME/state location.
2. Restart wireplumber and verify active.
3. `journalctl --user -b -u wireplumber --no-pager` shows zero new `/var/empty` state errors.
4. `coredumpctl list --since <slice-start>` shows no new wireplumber coredump entries.

Done criteria:
1. No new wireplumber state-dir errors/coredumps after fix.

### Slice 5: Fix `PLOG-005` (duplicate mDNS stack + hostname conflict)
Goal:
1. Remove mDNS stack duplication and hostname conflict churn.

Steps:
1. Identify all responders bound to mDNS (`:5353`).
2. Keep one authoritative responder path (Avahi or resolved) and disable duplicate advertising behavior.
3. Stabilize host naming behavior.

Issue-specific tests:
1. Service/socket inspection confirms a single intended responder.
2. `check-session-log-health.sh --boot current` shows zero duplicate mDNS and hostname-conflict events.
3. `avahi-browse`/local service discovery still works (if Avahi retained).

Done criteria:
1. No duplicate mDNS warning in current boot logs.

### Slice 6: Fix `PLOG-006` (`netdev` unknown group in D-Bus config)
Goal:
1. Eliminate D-Bus policy warning about missing `netdev` group.

Steps:
1. Locate policy file introducing `netdev` group reference.
2. Decide preferred fix:
   - define `netdev` group in NixOS users/groups, or
   - remove/patch policy source if unnecessary.
3. Rebuild and restart affected services.

Issue-specific tests:
1. `journalctl -b -u dbus --no-pager` contains zero new `Unknown group "netdev"` warnings.
2. Any feature depending on the policy still works.

Done criteria:
1. Zero `netdev` D-Bus warnings in current boot.

### Slice 7: Fix `PLOG-007` (greetd + gnome-keyring PAM mismatch)
Goal:
1. Resolve greetd keyring control-file warning.

Steps:
1. Validate whether keyring integration is required for current desktop profile.
2. Align PAM/greetd/keyring configuration accordingly (enable fully or disable cleanly).
3. Verify login flow remains functional.

Issue-specific tests:
1. Fresh login cycle completes successfully.
2. `journalctl -b -u greetd --no-pager` has zero new `gkr-pam` control-file warnings.
3. Credential store behavior works as intended (if keyring kept enabled).

Done criteria:
1. No `gkr-pam` warning after fresh login.

### Slice 8: Fix `PLOG-008` (NetworkManager P2P forwarding warning)
Goal:
1. Eliminate or bound IPv4 forwarding warning.

Steps:
1. Determine whether warning is tied to Wi-Fi P2P feature and if feature is needed.
2. Tune NetworkManager/system forwarding settings to prevent contention.
3. If technically benign and unavoidable, add explicit monitored threshold with rationale.

Issue-specific tests:
1. `check-session-log-health.sh --boot current` forwarding warning count is zero or below approved threshold.
2. Normal Wi-Fi operation remains healthy.

Done criteria:
1. Warning is eliminated, or controlled under documented threshold with explicit approval.

### Slice 9: Fix `DRFT-002` (Home Manager home-path drift)
Goal:
1. Align active HM profile with evaluated repo home.path (excluding accepted Emacs deltas).

Steps:
1. Compare active `home-path` and expected built path using `check-home-profile-drift.sh`.
2. Apply/switch to intended HM generation.
3. Re-check closure diff and isolate remaining differences.
4. If remaining deltas are only Emacs-related, keep as excluded.

Issue-specific tests:
1. `check-home-profile-drift.sh` passes.
2. `nix store diff-closures <active-home-path> <expected-home-path>` is empty or only excluded Emacs items.

Done criteria:
1. Home profile drift resolved or limited to documented Emacs exclusions.

### Slice 10: Fix `DRFT-004` (prod-enabled user units not clearly declared)
Goal:
1. Ensure enabled custom user units are declaratively owned or explicitly accepted.

Steps:
1. Use `check-user-units-coverage.sh` to classify enabled units.
2. For each non-allowlisted unit:
   - map to tracked declaration, or
   - move to private boundary with explicit policy, or
   - disable if obsolete.
3. Keep an allowlist only for genuine implicit/system units.

Issue-specific tests:
1. `check-user-units-coverage.sh` passes with zero undeclared custom units.
2. `systemctl --user --failed` remains clean after adjustments.

Done criteria:
1. Unit ownership coverage test passes.

### Slice 11: Fix `REPO-001` and `SKIP-002` (audit process quality)
Goal:
1. Enforce reproducible audit execution context.

Steps:
1. Add preflight gate in audit runner:
   - print dirty-tree summary and require explicit `--allow-dirty` to continue.
2. Add explicit host/privilege checks so blocked commands are escalated/marked upfront.
3. Update docs for required execution context and artifact capture.

Issue-specific tests:
1. New preflight test fails on dirty tree without `--allow-dirty`.
2. Runtime checks no longer fail first due avoidable sandbox context.

Done criteria:
1. Process-level skips are eliminated or explicitly pre-declared.

### Slice 12: Fix `REPO-002` (xorg/libxcb deprecation warning)
Goal:
1. Remove deprecation warning or track it as accepted transitive upstream issue.

Steps:
1. Locate warning origin with dependency tracing.
2. If in tracked code, migrate to `libxcb`.
3. If transitive external package, document as temporary accepted issue with watch item.
4. Keep or update warning allowlist only with explicit evidence + issue link.

Issue-specific tests:
1. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` emits zero unmanaged deprecation warnings.
2. `scripts/check-nix-deprecations.sh` passes.

Done criteria:
1. Warning removed from build output, or formally accepted with watchdog test and rationale.

### Slice 13: Fix `SKIP-001` (kernel signal visibility)
Goal:
1. Ensure kernel error signal is always auditable.

Steps:
1. Prefer `journalctl -k -p 0..4` in tests/reports.
2. Use `dmesg` only as optional secondary source.
3. Update audit scripts to avoid permission-based blind spot.

Issue-specific tests:
1. `check-runtime-observability.sh` passes.
2. Production audit can always collect kernel-level signal artifacts.

Done criteria:
1. No skipped kernel-observability check in final rerun.

## Final Verification (Mandatory)
After all slices:
1. Run all new tests:
   - `scripts/check-session-log-health.sh`
   - `scripts/check-home-profile-drift.sh`
   - `scripts/check-user-units-coverage.sh`
   - `scripts/check-runtime-observability.sh`
2. Run existing regression checks:
   - `scripts/check-repo-public-safety.sh`
   - `scripts/audit-system-up-to-date.sh --exclude-emacs`
3. Run mandatory Nix gates (all five).
4. Re-run full production audit and generate:
   - `reports/production-audit-<new-timestamp>/`
5. Compare old vs new findings and confirm:
   - all in-scope non-Emacs findings are closed or explicitly accepted with evidence,
   - no new high-severity regressions introduced.

## Completion Criteria
1. Every issue from `PLOG-*`, `DRFT-*`, `REPO-*`, `SKIP-*` has:
   - implemented change or accepted-with-evidence decision,
   - passing issue-specific new test,
   - passing relevant regression gates.
2. Final production audit verdict is `PASS` or `PASS_WITH_WARNINGS` with no `high`/`critical` non-Emacs findings.
3. Report includes exact evidence paths for each closure.
