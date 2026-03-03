# Validation and Safety Gates

## Fast Feedback (Every Slice)
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`

## Full Validation (Before Merge)
1. `./scripts/run-validation-gates.sh all`
2. `./scripts/check-repo-public-safety.sh`

## Runtime Validation (When Session/Desktop Is Touched)
1. `./scripts/check-runtime-smoke.sh --allow-non-graphical`
2. Optional artifact capture: `./scripts/capture-runtime-warning-report.sh`

## Canonical Runner
1. Use `./scripts/run-validation-gates.sh` as source of truth.
2. Stage options: `structure`, `predator`, `server-example`, `runtime-smoke`, `all`.

## Username-Resolution Safe Pattern
1. Resolve Home Manager username through config instead of hardcoding:
```bash
hm_user="$(nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name)"
nix eval "path:$PWD#nixosConfigurations.predator.config.home-manager.users.${hm_user}.home.stateVersion"
```
