# Mutable Config Registry

## Goal
Track mutable copy-once runtime config targets in one place so refactors preserve intent.

## Policy
1. Mutable targets are allowed only when the app modifies the file or user edits must persist.
2. Use `home/user/lib/mutable-copy.nix` helper for copy-once semantics whenever possible.
3. Keep owner module and rationale explicit.

## Registry
| Target Path | Source Path | Owner Module | Overwrite Policy | Rationale |
| --- | --- | --- | --- | --- |
| `~/.config/keyrs/config.toml` | `config/apps/keyrs/config.toml` | `home/user/services/keyrs.nix` | Copy once (never overwrite) | User edits and runtime tuning must persist. |
| `~/.config/DankMaterialShell/settings.json` | `config/apps/dms/settings.json` | `home/user/services/wallpaper.nix` | Copy once (never overwrite) | DMS UI writes this file. |
| `~/.config/fcitx5/profile` | `config/apps/fcitx5/profile` | `home/user/apps/misc.nix` | Copy once (never overwrite) | Input method profile is user-managed. |
| `~/.config/niri/custom.kdl` | `config/shells/niri-custom.kdl` | `home/user/desktop/shells.nix` | Copy once (never overwrite) | User override layer for compositor config. |
| `~/.config/caelestia/shell.json` | `config/shells/caelestia/shell.json` | `home/user/desktop/shells.nix` | Copy once (never overwrite) | Shell settings are user-editable. |
| `~/.config/noctalia/settings.json` | `config/shells/noctalia/settings.json` | `home/user/desktop/shells.nix` | Copy once (never overwrite) | Shell settings are user-editable. |
| `~/.config/noctalia/colors.json` | `config/shells/noctalia/colors.json` | `home/user/desktop/shells.nix` | Copy once (never overwrite) | Shell theme/colors are user-editable. |
| `~/.config/noctalia/plugins.json` | `config/shells/noctalia/plugins.json` | `home/user/desktop/shells.nix` | Copy once (never overwrite) | Plugin selections are user-editable. |
| `~/.config/hypr/hyprland.conf` | `config/apps/hyprland/hyprland.conf` | `home/user/desktop/default.nix` | Copy once (never overwrite) | User profile-local Hyprland edits must persist. |
| `~/.config/hypr/hyprland-caelestia.conf` | `config/apps/hyprland/hyprland-caelestia.conf` | `home/user/desktop/default.nix` | Copy once (never overwrite) | Profile-specific Hyprland edits must persist. |
| `~/.config/dms-awww/config.toml` | Generated at activation | `home/user/services/wallpaper.nix` | Regenerated each activation | Contains dynamic `shell_dir` derived from active DMS path. |

## Maintenance Rules
1. When adding a new mutable target, add a row in this file in the same change.
2. If overwrite policy changes, update this file and mention migration/rollback.
3. Keep this file aligned with canonical contracts in `017-config-test-pyramid.md` and `018-doc-lifecycle-and-index.md`.
