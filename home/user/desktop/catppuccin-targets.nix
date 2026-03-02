{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  desktopProfileEnabled = osConfig.custom.desktop.capabilities.desktopUserApps;
  # Single local toggle for GTK Catppuccin integration.
  # Set to false to disable GTK theme wiring while keeping other Catppuccin targets.
  gtkThemeEnabled = true;

  gtkAccent = config.catppuccin.accent;
  gtkSize = "standard";
  gtkVariant = config.catppuccin.flavor;
  gtkThemePackage = pkgs.catppuccin-gtk.override {
    accents = [ gtkAccent ];
    variant = gtkVariant;
    size = gtkSize;
  };
  gtkThemeName = "catppuccin-${gtkVariant}-${gtkAccent}-${gtkSize}";
in
{
  options.custom.theme.zen.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable official Catppuccin Zen Browser CSS theme sync.";
  };

  config = lib.mkMerge [
    {
      # Centralized Catppuccin target registry.
      catppuccin.gtk.icon.enable = gtkThemeEnabled;

      catppuccin.fcitx5 = {
        enable = true;
        apply = false;
      };

      catppuccin.fzf.enable = true;
      catppuccin.btop.enable = true;
      catppuccin.bottom.enable = true;
      catppuccin.bat.enable = true;
      catppuccin.eza.enable = true;
      catppuccin.lazygit.enable = true;
      catppuccin.yazi.enable = true;
      catppuccin.zellij.enable = true;
      catppuccin.fish.enable = true;
      catppuccin.starship.enable = true;
      catppuccin.alacritty.enable = true;
      catppuccin.foot.enable = true;
      catppuccin.ghostty.enable = true;
      catppuccin.kitty.enable = true;
      catppuccin.wezterm.enable = true;
      catppuccin.chromium.enable = true;
      catppuccin.brave.enable = true;
      catppuccin.firefox.profiles.default = {
        enable = true;
        force = true;
      };

      catppuccin.tmux = {
        enable = true;
        extraConfig = ''
          set -g @catppuccin_window_status_style "rounded"
        '';
      };

      catppuccin.vscode.profiles.default = {
        enable = true;
        icons.enable = true;
      };

    }
    (lib.mkIf gtkThemeEnabled {
      gtk = {
        enable = true;
        gtk4.enable = true;
        theme = {
          name = gtkThemeName;
          package = gtkThemePackage;
        };
        font = {
          name = "Sans";
          size = 12;
        };
      };
    })
    (lib.mkIf desktopProfileEnabled {
      catppuccin.cava.enable = true;
    })
  ];
}
