# Private Overrides Setup

## Use This For
1. Personal secrets/paths/network values.
2. Machine-local values that should not be committed.

## Setup
1. Copy tracked examples to untracked private files.
2. Fill local values in:
   - `hosts/*/private*.nix`
   - `home/*/private*.nix`
3. Keep private entrypoints import-only; place values in split private modules.

## Safety Check
1. Run `./scripts/check-repo-public-safety.sh` before publish.
