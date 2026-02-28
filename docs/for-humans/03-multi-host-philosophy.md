# Multi-Host Philosophy

## Model
1. Hosts select behavior.
2. Modules define reusable behavior.
3. Profiles switch major desktop/compositor stacks.

## Practical Rules
1. A host file should be thin: imports + host choices.
2. Shared behavior must not live in host files.
3. Feature flags belong in options/modules, not ad-hoc host conditionals.
4. Profile differences should be expressed through `custom.desktop.profile`.

## Current Pattern
1. `hosts/predator/default.nix` chooses host identity and profile.
2. `modules/options.nix` defines profile/feature options.
3. `modules/profiles/desktop.nix` implements profile branches (`dms`, `niri-only`, `noctalia`, `dms-hyprland`, `caelestia-hyprland`).

## When Adding a New Host
1. Copy a minimal host skeleton under `hosts/<new-host>/`.
2. Import shared `modules` and `home` modules.
3. Set host-only values there (hostname, hardware, profile selection).
4. Do not fork shared logic into host files.
