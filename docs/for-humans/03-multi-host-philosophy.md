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

## Current Pattern

1. `hosts/predator/default.nix` chooses host identity, role, and desktop profile.
2. `hosts/server-example/default.nix` is a minimal server-role reference host.
3. `modules/options/` defines system option declarations.
4. `modules/profiles/desktop/` implements desktop behavior by concern and profile.

## When Adding a New Host

1. Copy a minimal host skeleton under `hosts/<new-host>/`.
2. Set `custom.host.role` first (`desktop` or `server`).
3. Import shared `modules` and `home` modules only as needed for that role.
4. Set host-only values there (hostname, hardware, profile selection when desktop).
5. Do not fork shared logic into host files.
