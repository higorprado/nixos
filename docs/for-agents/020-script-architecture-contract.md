# Script Architecture Contract

## Objective
Keep repo scripts easy to evolve by enforcing clear responsibilities and shared conventions.

## Layout Contract
1. `scripts/lib/`
   - Reusable helpers only.
   - No direct policy/gate decisions.
2. `scripts/check-*.sh`
   - One gate per script.
   - Validate one policy area with explicit pass/fail output.
3. `scripts/run-*.sh`
   - Orchestration entrypoints only.
   - Call `check-*` scripts and top-level Nix gates; avoid duplicating gate logic.
4. Other scripts (for example `scripts/new-host-skeleton.sh`, `scripts/validate-host.sh`)
   - Must document intended scope in usage/help output.

## Required Conventions
1. Use `#!/usr/bin/env bash` and `set -euo pipefail`.
2. Source `scripts/lib/common.sh` for repo-root and shared helpers:
   - `enter_repo_root`
   - `require_cmd` / `require_cmds`
   - `log_fail`
   - `log_warn` / `log_ok`
   - `mktemp_dir_scoped` / `mktemp_file_scoped`
3. Emit stable machine-readable prefixes on errors and major statuses:
   - `[$scope] fail: ...`
   - `[$scope] ok: ...`
4. Keep script interfaces explicit:
   - accepted args/options,
   - expected outputs/artifacts,
   - exit code semantics.

## Responsibility Boundaries
1. `scripts/lib/*` should not call heavyweight validation stages directly.
2. `check-*` scripts should not mutate system state.
3. `run-*` scripts may sequence checks/builds but should avoid embedding complex parsing or policy logic.
4. Shared parsing/formatting behavior belongs in `scripts/lib/`, not duplicated in multiple `check-*` scripts.

## Change Rules
1. New script creation:
   - prefer extending existing `check-*` or `lib/*` first,
   - add a new script only when scope is distinct and reusable.
2. Refactors:
   - preserve output contract unless intentionally versioned,
   - include before/after validation evidence.
3. Naming:
   - `check-<domain>.sh` for policy checks,
   - `run-<workflow>.sh` for orchestrators,
   - `<verb>-<domain>.sh` for utility scripts.

## Required Validation For Script Changes
1. `./scripts/check-changed-files-quality.sh [origin/main]`
2. `./scripts/run-validation-gates.sh structure`
3. If script semantics affect host/profile/options/CI wiring:
   - `./scripts/run-validation-gates.sh predator`
   - `./scripts/run-validation-gates.sh server-example`
