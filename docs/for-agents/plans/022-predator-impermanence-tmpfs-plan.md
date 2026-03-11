# Predator Impermanence Tmpfs Plan

## Goal

Migrate `predator` to an impermanence-style layout using `tmpfs` for `/`,
keeping only the required state persisted across boots.

This plan assumes:
- `predator` only
- `@persist` already exists and is mounted at `/persist`
- `/nix` already lives on `@nix`
- `/var/log` already lives on `@log`
- `/home` already lives on a separate persistent Btrfs disk

## Scope

In scope:
- add the `impermanence` input/module
- declare the persistence inventory for `predator`
- migrate `/` to `tmpfs`
- preserve system-critical state explicitly
- keep `/nix`, `/var/log`, `/home`, `/persist`, `/boot`, and `/swap` intact
- define rollback/fallback steps

Out of scope:
- `aurelius`
- converting rootful Podman into a supported workflow if it is not used
- redesigning the DMS stack
- migrating every optional cache to persistence
- long-term archival/retention strategy for logs or coredumps

## Current State

Current measured root usage after cleanup:
- `/` total on `@root`: about `155 MiB`
- `/tmp`: `0`
- `/var`: about `69 MiB`
- `/usr`: about `85 MiB`
- `/etc`: negligible

Current swap layout:
- zram enabled at ~`31 GiB`
- disk swapfile at `/swap/swapfile` ~`48 GiB`
- total swap available ~`79 GiB`

Current split layout:
- `/` -> `@root`
- `/nix` -> `@nix`
- `/var/log` -> `@log`
- `/persist` -> `@persist`
- `/home` -> separate persistent Btrfs disk
- `/swap/swapfile` -> existing persistent swapfile path

## Persistence Diagnosis

### Already Persisted Adequately

- `/nix`
- `/var/log`
- `/home`
- `/boot`
- `/swap/swapfile`

### Must Persist for Correctness

These should be explicitly persisted through `environment.persistence."/persist"`:

- `/etc/machine-id`
  - stable machine identity
- `/etc/ssh`
  - host keys must survive reboot
- `/etc/NetworkManager/system-connections`
  - saved Wi-Fi and network profiles
- `/var/lib/bluetooth`
  - paired devices and trust state
- `/var/lib/tailscale`
  - node identity/state
- `/var/lib/docker`
  - now intentionally relocated to `/persist/var/lib/docker`

### Persist Only If Actually Needed

- `/var/lib/containers/storage`
  - only if rootful Podman use matters
  - rootless Podman already persists under `/home`
- `/var/lib/systemd/coredump`
  - only if you want persistent coredumps
  - if kept, prefer storing under `@log`, not `@persist`

### Can Stay Ephemeral

- `/tmp`
- most of `/var/cache`
- `/var/lib/AccountsService`
- `/var/lib/NetworkManager`
- `/var/lib/upower`
- `/var/lib/fwupd`
- `/var/lib/nixos`
- `/var/lib/dms-greeter`
- `/var/lib/regreet`

## Important Risks To Handle Explicitly

### Risk 1: Boot failure if `/persist` is missing

Already seen in practice:
- `persist.mount` failed
- `local-fs.target` failed
- system went to emergency mode

Mitigation:
- never activate a `/persist` mount unless `@persist` exists live
- manual mount test remains a mandatory gate before first activation

### Risk 2: Hibernation/resume interaction

`predator` currently has:
- `/swap/swapfile`
- `boot.resumeDevice`
- `resume_offset`

Switching `/` to `tmpfs` changes boot semantics. Hibernation must be treated as
a separate compatibility check.

Recommendation:
- Phase 1 rollout should target normal boot/reboot only
- hibernation/resume should be revalidated in a later slice
- if uncertain, temporarily document hibernation as unsupported during the
  transition instead of assuming it still works

### Risk 3: Missing state inventory

The real danger of impermanence is not `tmpfs`; it is forgetting a path that
must survive reboot.

Mitigation:
- keep the first persisted set conservative
- add more paths only when justified by real behavior

## Target Architecture

### Root

- `/` becomes `tmpfs`
- it starts empty on every boot

### Persistent mounts

- `/nix` from `@nix`
- `/var/log` from `@log`
- `/persist` from `@persist`
- `/home` from existing home disk
- `/boot` unchanged
- `/swap` / resume path unchanged

### Declarative persistence

Use `environment.persistence."/persist"` for:
- directories under `/var/lib`
- critical `/etc` state
- any additional files discovered during rollout

## Rollout Strategy

Do not jump directly to “switch root to tmpfs on main and reboot”.

Use four stages:

1. add `impermanence` input and persistence declarations only
2. verify persistence layout without changing `/`
3. switch `/` to `tmpfs`
4. reboot verification and only then test hibernation

## Phases

### Phase 0: Snapshot the current safe state

Goal:
- ensure the currently working `main` is committed and pushed

Validation:
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Status:
- already satisfied before this plan was written

### Phase 1: Add `impermanence` without changing `/`

Targets:
- `flake.nix`
- `flake.lock`
- `modules/hosts/predator.nix` or a new predator-scoped persistence module

Changes:
- add `impermanence` input
- import `impermanence.nixosModules.impermanence` for `predator`
- declare:
  - `/etc/machine-id`
  - `/etc/ssh`
  - `/etc/NetworkManager/system-connections`
  - `/var/lib/bluetooth`
  - `/var/lib/tailscale`
  - `/var/lib/docker`
- decide explicitly whether to include rootful Podman storage

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.environment.persistence`
- `nix store diff-closures` against previous system

Expected diff:
- only new persistence wiring and mount references

Commit target:
- `refactor: add predator persistence inventory`

### Phase 2: Live verify the persistence map before tmpfs root

Goal:
- confirm `/persist` has every needed target path and permissions

Checks:
- `findmnt /persist`
- `ls -ld /persist/etc /persist/var/lib`
- `test -d /persist/var/lib/docker`
- verify service state is still healthy after `nh os test`

Expected result:
- no behavioral changes yet

Commit target:
- progress log only

### Phase 3: Introduce `tmpfs` root

Targets:
- `hardware/predator/disko.nix` or a predator-specific mount module

Changes:
- move `/` from `@root` to `tmpfs`
- keep the persistent mounts layered back in:
  - `/nix`
  - `/var/log`
  - `/persist`
  - `/home`
  - `/boot`
- keep the existing swap path

Design rule:
- do not delete `@root` immediately
- keep it available as recovery material until reboot verification is complete

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- manual review of generated mount units
- `nix store diff-closures` against pre-tmpfs system

Expected diff:
- mount/activation changes only

Commit target:
- `refactor: move predator root to tmpfs`

### Phase 4: Safe first activation

Goal:
- test activation without immediately relying on reboot recovery

Process:
1. verify `/persist` manually mountable
2. `nh os test path:$PWD`
3. verify:
   - `findmnt /`
   - `findmnt /persist`
   - `findmnt /nix`
   - `findmnt /var/log`
   - `docker info | grep -F "Docker Root Dir"`
   - `systemctl --failed --no-pager`
   - `systemctl --user --failed --no-pager`

Expected result:
- system stays healthy under the live test activation

Commit target:
- progress log only

### Phase 5: Reboot verification

Goal:
- confirm the machine comes back healthy from a real boot

Checks after reboot:
- `findmnt /`
- `findmnt /persist`
- `findmnt /nix`
- `findmnt /var/log`
- `docker info | grep -F "Docker Root Dir"`
- `systemctl --failed --no-pager`
- `systemctl --user --failed --no-pager`
- verify network, Bluetooth, SSH host identity, and Tailscale state

Commit target:
- `docs: record predator impermanence reboot verification`

### Phase 6: Hibernation decision

Goal:
- explicitly decide whether hibernation still works and is supported

Options:
- verify resume and keep it supported
- or explicitly drop hibernation support for the tmpfs-root design

Do not assume success without a real suspend/resume test.

## Fallback / Recovery Plan

### If `nh os test` fails before reboot

- the test generation is not yet the boot default
- inspect:
  - `systemctl --failed --no-pager`
  - `journalctl -b --no-pager`
- revert the declarative `tmpfs /` slice

### If reboot fails but initrd/shell is reachable

Manual recovery path:

1. unlock `cryptroot`
2. mount the Btrfs top-level (`subvolid=5`)
3. mount `@root` manually if needed
4. boot into a previous generation or roll back the tmpfs-root change

### Recovery assets to keep until the rollout is proven

- existing `@root`
- current swap configuration
- existing `@persist`
- remote access capability if available

## Definition of Done

- `predator` boots with `/` on `tmpfs`
- critical state survives reboot via `/persist`
- `/nix`, `/var/log`, `/home`, `/persist`, `/boot`, and swap remain healthy
- Docker still works from `/persist`
- no failed units after reboot
- hibernation support is either revalidated or explicitly demoted from support
