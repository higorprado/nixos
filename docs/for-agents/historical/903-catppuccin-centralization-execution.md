# Catppuccin Centralization Execution Log

## Scope Executed
1. Implemented centralized Catppuccin target registry.
2. Migrated existing per-module Catppuccin toggles into the registry.
3. Kept non-theme app behavior in original modules.
4. Ran Home Manager and system build gates.
5. Moved GTK Catppuccin theme wiring into centralized registry.
6. Enabled Catppuccin for Chromium and Brave.
7. Added Zen Browser via dedicated flake input.
8. Migrated Firefox from package-only to `programs.firefox` with profile management.
9. Added local GTK theme toggle in centralized Catppuccin registry (`gtkThemeEnabled`).

## Upstream Evidence Sources Used
1. `$NIX_CAT_REPO/docs/data/main-home-options.json`
2. `$NIX_CAT_REPO/docs/data/main-nixos-options.json`
3. `$NIX_CAT_REPO/modules/home-manager/chrome.nix`
4. `$NIX_CAT_REPO/modules/home-manager/firefox.nix`
5. `$NIX_CAT_REPO/modules/home-manager/neovim.nix`

## Changes Applied
1. Added centralized registry:
   - `home/user/desktop/catppuccin-targets.nix`
2. Wired registry into desktop imports:
   - `home/user/desktop/default.nix`
3. Kept global base only in:
   - `home/user/desktop/catppuccin.nix` (`flavor`, `accent`)
4. Removed migrated Catppuccin declarations from:
   - `home/user/apps/misc.nix`
   - `home/user/core/packages.nix`
   - `home/user/core/monitoring.nix`
   - `home/user/dev/dev.nix`
   - `home/user/dev/tui-tools.nix`
   - `home/user/shell/fish.nix`
   - `home/user/shell/starship.nix`
   - `home/user/programs/shells/tmux.nix`
   - `home/user/programs/terminals/alacritty.nix`
   - `home/user/programs/terminals/foot.nix`
   - `home/user/programs/terminals/ghostty.nix`
   - `home/user/programs/terminals/kitty.nix`
   - `home/user/programs/terminals/wezterm.nix`
   - `home/user/programs/editors/vscode.nix`
   - `home/user/desktop/media.nix`
5. Added browsers/config:
   - `flake.nix`: added `zen-browser` input (`github:youwen5/zen-browser-flake`)
   - `home/user/desktop/apps.nix`: enabled `programs.chromium`, `programs.brave`, added Zen package
   - `home/user/desktop/catppuccin-targets.nix`: enabled `catppuccin.chromium` and `catppuccin.brave`
6. Moved GTK theme package/name assignment from `home/user/desktop/default.nix` to `home/user/desktop/catppuccin-targets.nix`
7. Firefox migration:
   - `home/user/desktop/apps.nix`: added `programs.firefox.enable = true`
   - `home/user/desktop/apps.nix`: added managed profile `profiles.default` (`id`, `path`, `isDefault`)
   - `home/user/desktop/apps.nix`: added `profiles.default.extensions.force = true` (required by HM assertion with catppuccin firefox extension settings)
   - `home/user/desktop/apps.nix`: removed package-only Firefox install
8. GTK toggle:
   - `home/user/desktop/catppuccin-targets.nix`: GTK block and catppuccin gtk icon enable driven by local `gtkThemeEnabled`

## Follow-up Corrections
1. Removed `custom.theme.gtk.enable` from global options/host config.
2. Kept GTK toggle local to centralized Catppuccin registry file only:
   - `home/user/desktop/catppuccin-targets.nix`: `gtkThemeEnabled = true` (single local switch)
3. Firefox data-preserving fix:
   - `home/user/desktop/apps.nix`: `programs.firefox.profiles.default.path = "y4loqr0b.default"`
   - `home/user/desktop/catppuccin-targets.nix`: `catppuccin.firefox.profiles.default = { enable = true; force = true; }`
   - Runtime profile remains standard (`~/.mozilla/firefox`) while preserving legacy profile name.
4. Zen theme migration to official upstream:
   - Added source input: `flake.nix` `catppuccinZenBrowserSource = github:catppuccin/zen-browser (flake = false)`
   - Added package wrapper: `pkgs/catppuccin-zen-browser.nix` and registered in `pkgs/default.nix`
   - Added module: `home/user/desktop/catppuccin-zen-browser.nix`
   - Module copies official `userChrome.css`, `userContent.css`, and `zen-logo.svg` to active Zen profile `chrome/`
   - Module enforces `toolkit.legacyUserProfileCustomizations.stylesheets = true` in Zen `user.js`
   - Removed old helper hook from `home/user/desktop/apps.nix` (`syncZenFirefoxColorTheme`)
5. Centralized Zen toggle:
   - `home/user/desktop/catppuccin-targets.nix`: `custom.theme.zen.enable` controls Zen CSS sync module
6. One-time live recovery run (outside module logic):
   - Restored legacy Firefox data from `~/.config/mozilla/firefox/y4loqr0b.default` to `~/.mozilla/firefox/y4loqr0b.default`.
   - Set `~/.mozilla/firefox/profiles.ini` default profile to `y4loqr0b.default`.

## Current Centralized Targets
1. `catppuccin.gtk.icon.enable`
2. `catppuccin.fcitx5` (`enable`, `apply = false`)
3. `catppuccin.fzf.enable`
4. `catppuccin.btop.enable`
5. `catppuccin.bottom.enable`
6. `catppuccin.bat.enable`
7. `catppuccin.eza.enable`
8. `catppuccin.lazygit.enable`
9. `catppuccin.yazi.enable`
10. `catppuccin.zellij.enable`
11. `catppuccin.fish.enable`
12. `catppuccin.starship.enable`
13. `catppuccin.alacritty.enable`
14. `catppuccin.foot.enable`
15. `catppuccin.ghostty.enable`
16. `catppuccin.kitty.enable`
17. `catppuccin.wezterm.enable`
18. `catppuccin.tmux` (`enable`, `extraConfig`)
19. `catppuccin.vscode.profiles.default` (`enable`, `icons.enable`)
20. `catppuccin.cava.enable` (profile-gated to desktop profiles)
21. `catppuccin.chromium.enable`
22. `catppuccin.brave.enable`
23. `catppuccin.firefox.profiles.default` (`enable`, `force`)
24. `custom.theme.zen.enable`

## Validation Results
1. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.activationPackage`: PASS
2. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`: PASS
3. Remaining warnings were pre-existing evaluation warnings unrelated to this migration.

## Coverage Status And Deferred Decisions
1. `google-chrome`: EXCEPTION
   - Upstream `chrome.nix` explicitly supports only `brave`, `chromium`, `vivaldi`.
   - `google-chrome` is documented upstream as unsupported for this extension-based port.
2. `firefox`: IMPLEMENTED
   - Managed via `programs.firefox.profiles.default`.
   - Catppuccin applied via `catppuccin.firefox.profiles.default` with `force = true`.
3. `nvim`: MANUAL-REVIEW
   - Upstream `catppuccin.nvim` injects plugin config and forces `colorscheme catppuccin`.
   - Repo already manages Neovim theme/plugins in `config/apps/nvim` with Lazy config.
   - Enabling upstream module without design decision risks duplicate plugin/theme authority.
4. `zen-browser`: IMPLEMENTED (official upstream CSS repo path)
   - Installed via dedicated flake package.
   - Theming sourced from `catppuccin/zen-browser` official repo and applied declaratively in HM activation.

## Suggested Next Decisions
1. Approve or reject adopting `catppuccin.nvim` module versus keeping Neovim theme under local Lazy config as the single source of truth.
