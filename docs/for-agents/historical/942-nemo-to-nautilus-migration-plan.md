# Nemo to Nautilus Migration Plan

## Objective
Replace Nemo with Nautilus as the default file manager while keeping profile/pack structure clean and validated.

## Scope
1. Desktop file-manager package and related config.
2. Default directory MIME handlers.
3. Documentation notes about placement and migration gaps.

## Tasks
1. Update `home/user/desktop/files.nix` from Nemo-specific setup to Nautilus.
2. Update `home/user/desktop/default.nix` MIME defaults to Nautilus desktop ID.
3. Validate with required gates and full `all` runner.
4. Record docs-gap findings from execution and patch docs if needed.

## Validation
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`
3. `./scripts/run-validation-gates.sh all`
4. `./scripts/check-repo-public-safety.sh`

## Exit Criteria
1. Nemo no longer installed/configured by desktop files pack.
2. Nautilus is default for `inode/directory` and `application/x-gnome-saved-search`.
3. All required validations pass.
4. Current-work log contains docs-gap analysis and outcomes.

## Status
1. Completed.
