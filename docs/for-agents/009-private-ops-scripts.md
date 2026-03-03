# Private Ops Scripts Location

## Purpose
Keep personal/host-specific operational scripts outside this public repo.

## Canonical Location
1. `~/ops/nixos-private-scripts/bin`
2. `~/ops/nixos-private-scripts/docs`

## Boundary Contract
1. `scripts/` in this repo is only for shared, reproducible validation/safety tooling.
2. Do not re-add private ops scripts into repo `scripts/`.
3. If a task needs private ops scripts, execute from the external location.
