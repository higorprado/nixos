# Private Ops Scripts Location

## Purpose
Keep personal/host-specific operational scripts outside the public repo.

## Canonical Location
1. `~/ops/nixos-private-scripts/bin`
2. Supporting notes: `~/ops/nixos-private-scripts/docs`

## Rule
1. Do not re-add private ops scripts under repo `scripts/`.
2. Repo `scripts/` should contain only shared, reproducible validation/safety tooling.

## Moved Script Set
1. `audit-packages.sh`
2. `backup-critical.sh`
3. `backup-system.sh`
4. `check-desktop-profile.sh`
5. `check-nvim-embed-orphans.sh`
6. `cleanup-nvim-embed-orphans.sh`
7. `health-check.sh`
8. `restore-critical.sh`
9. `switch-profile.sh`

## Agent Note
If a task requires one of these scripts, run it from `~/ops/nixos-private-scripts/bin/` instead of this repo.
