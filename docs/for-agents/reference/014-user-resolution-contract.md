# User Resolution Contract

## Objective
Define one stable policy for resolving `custom.user.name` across local, CI, and multi-host contexts.

## Contract
1. `modules/options/core-options.nix` keeps a placeholder default (`"user"`) only as an unresolved sentinel.
2. Every tracked host must set a safe tracked fallback user (for example `lib.mkDefault "ops"` or explicit `"ops"`).
3. Runtime assertions must reject unsafe resolved values:
   - empty string
   - `"user"`
   - `"root"`
4. Local private overrides may set the real machine username with higher priority and must remain untracked.
5. CI and shared scripts must never hardcode `home-manager.users.<realname>`.
   - Always resolve the active username from config first.

## Validation Source of Truth
1. `scripts/check-config-contracts.sh` enforces host-role/capability invariants.
2. `scripts/check-config-contracts.sh` enforces safe `custom.user.name` resolution for all declared hosts.
3. `scripts/check-config-contracts.sh` enforces username indirection in tracked CI/script/docs paths.

## Operational Rule
1. Prefer `path:` flake references for local switches when private overrides are needed.
2. Avoid git-style refs for local switch commands that must include untracked private overrides.
