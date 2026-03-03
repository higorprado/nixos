# Theme Asset Policy

## Decision
Local theme asset files under `config/themes` are removed.

Theme behavior is managed via Home Manager/NixOS modules (Catppuccin options and app modules), not ad-hoc CSS/color files in this repo.

The only user-maintained theme-like config in `config/` that remains intentional is tmux config at:
1. `config/tmux/tmux.conf`

## Scope Removed
1. `config/themes/gtk/**`
2. `config/themes/qt/**`
3. `config/themes/discord/**`
4. `config/themes/terminals/kitty/dank-tabs.conf`

## Rationale
1. Local unmanaged theme files created runtime drift and stale references.
2. Centralized module-driven theming is easier to validate in Nix builds.
3. Removing one-off assets prevents parse/log issues from missing local includes.

## Agent Rules
1. Do not reintroduce local theme assets under `config/themes` unless explicitly requested by the user.
2. If visual theme changes are needed, implement them in module options first.
3. Keep tmux-specific settings in `config/tmux/tmux.conf` when needed.
