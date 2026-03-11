# Predator Impermanence Tmpfs Progress

## Status

Planned

## Related Plan

- [022-predator-impermanence-tmpfs-plan.md](/home/higorprado/nixos/docs/for-agents/plans/022-predator-impermanence-tmpfs-plan.md)

## Baseline

- `predator` already has:
  - `/nix` on `@nix`
  - `/var/log` on `@log`
  - `/persist` on `@persist`
  - `/home` on a separate persistent disk
  - zram plus disk swapfile fallback
- measured current `/` usage after cleanup is about `155 MiB`
- estimated `tmpfs /` working range is about `200–350 MiB`

## Slices

### Slice 1

- wrote the impermanence plan for `predator`
- captured the persistence inventory
- captured the hibernation/resume risk explicitly
- defined the staged rollout:
  - persistence map first
  - `tmpfs /` second
  - reboot verification
  - hibernation decision last

## Final State

- execution not started yet
