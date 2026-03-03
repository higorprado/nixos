# Host and Profile Changes

## Use This For
1. Adding or modifying host-level settings.
2. Changing `custom.host.role` or `custom.desktop.profile`.
3. Adding/changing host descriptor entries.

## Steps
1. Update host descriptor in `hosts/host-descriptors.nix`.
2. Update `hosts/<host>/default.nix` for host-specific selections.
3. If profile logic changes, update profile registry/metadata under `modules/profiles/desktop/`.
4. Run:
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
   - `./scripts/run-validation-gates.sh predator`
   - `./scripts/run-validation-gates.sh server-example`

## Done When
1. Structure and role/profile gates pass.
2. No host/profile contract violations remain.
