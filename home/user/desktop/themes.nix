{ config, lib, pkgs, ... }:

{
  # Theme packages
  home.packages = with pkgs; [
    # GTK theming (adwaita with custom styling)
    adw-gtk3
    # Cursor theme package
    phinger-cursors
    # Color generator (matugen)
    matugen
  ];

  # =============================================================================
  # Theme Files - Symlinked (read-only, edit in repo then rebuild)
  # =============================================================================

  # Kitty non-color tab styling extras
  xdg.configFile."kitty/dank-tabs.conf".source = ../../../config/themes/terminals/kitty/dank-tabs.conf;

  # GTK 3.0 theme customizations
  xdg.configFile."gtk-3.0/dank-colors.css".source = ../../../config/themes/gtk/gtk-3.0/dank-colors.css;
  xdg.configFile."gtk-3.0/gtk.css".source = ../../../config/themes/gtk/gtk-3.0/gtk.css;

  # GTK 4.0 theme customizations
  xdg.configFile."gtk-4.0/dank-colors.css".source = ../../../config/themes/gtk/gtk-4.0/dank-colors.css;
  xdg.configFile."gtk-4.0/gtk.css".source = ../../../config/themes/gtk/gtk-4.0/gtk.css;

  # Qt theming
  xdg.configFile."qt5ct/colors/caelestia.colors".source = ../../../config/themes/qt/qt5ct/colors/caelestia.colors;
  xdg.configFile."qt6ct/colors/caelestia.colors".source = ../../../config/themes/qt/qt6ct/colors/caelestia.colors;

  # =============================================================================
  # App Launcher & Audio Visualizer - Symlinked
  # =============================================================================

  # =============================================================================
  # Discord Themes - Copied on first deploy (mutable, user-editable)
  # These clients can overwrite theme files, so we copy once and let user edit.
  # =============================================================================

  home.activation.provisionDiscordThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Vencord
    if [ ! -f "$HOME/.config/Vencord/themes/caelestia.theme.css" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/Vencord/themes"
      $DRY_RUN_CMD cp ${../../../config/themes/discord/caelestia.theme.css} "$HOME/.config/Vencord/themes/caelestia.theme.css"
    fi

    # Vesktop
    if [ ! -f "$HOME/.config/vesktop/themes/caelestia.theme.css" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/vesktop/themes"
      $DRY_RUN_CMD cp ${../../../config/themes/discord/caelestia.theme.css} "$HOME/.config/vesktop/themes/caelestia.theme.css"
    fi

    # BetterDiscord
    if [ ! -f "$HOME/.config/BetterDiscord/themes/caelestia.theme.css" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/BetterDiscord/themes"
      $DRY_RUN_CMD cp ${../../../config/themes/discord/caelestia.theme.css} "$HOME/.config/BetterDiscord/themes/caelestia.theme.css"
    fi
  '';
}
