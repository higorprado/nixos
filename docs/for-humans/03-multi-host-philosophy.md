# Multi-Host Philosophy

## Model

1. Hosts select behavior.
2. Modules define reusable behavior.
3. Profiles switch major desktop/compositor stacks.

## Practical Rules

1. A host file should be thin: imports + host choices.
2. Shared behavior must not live in host files.
3. Feature flags belong in options/modules, not ad-hoc host conditionals.
4. Host class should be expressed with `custom.host.role` (`desktop` or `server`).
5. Desktop behavior differences should be expressed through `custom.desktop.profile`.
6. Keep ownership boundaries explicit (see `docs/for-agents/011-module-ownership-boundaries.md`).

## Current Pattern

1. `hosts/host-descriptors.nix` is the canonical host descriptor registry.
2. `hosts/predator/default.nix` chooses host identity, role, and desktop profile.
3. `hosts/server-example/default.nix` is a minimal server-role reference host.
4. `modules/options/` defines system option declarations.
5. `modules/profiles/desktop/` implements desktop behavior by concern and profile.

## When Adding a New Host

1. Create a skeleton with `scripts/new-host-skeleton.sh <host-name> [desktop|server] [desktop-profile]`.
2. Set `custom.host.role` first (`desktop` or `server`).
3. Add one descriptor entry in `hosts/host-descriptors.nix`.
4. Import shared `modules` and `home` modules only as needed for that role.
5. Set host-only values there (hostname, hardware, profile selection when desktop).
6. Do not fork shared logic into host files.
7. Run `./scripts/run-validation-gates.sh structure` and `./scripts/run-validation-gates.sh server-example`.

## Extension Touch Surface

1. Add host:
   - `hosts/<host>/default.nix`
   - `hosts/host-descriptors.nix`
2. Add desktop profile:
   - `modules/profiles/desktop/profile-<name>.nix`
   - `modules/profiles/desktop/profile-registry.nix`
   - `modules/profiles/desktop/profile-metadata.nix`
3. Add desktop pack:
   - `home/user/desktop/<pack>.nix`
   - `home/user/desktop/pack-registry.nix`
