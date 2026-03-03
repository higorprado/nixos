{ pkgs, lib, ... }:
let
  mutableCopy = import ../lib/mutable-copy.nix { inherit lib; };
  packRegistry = import ./pack-registry.nix;
in
{
  imports =
    [
      ./wayland.nix # Wayland tools (waybar, swww, wl-clipboard, etc.)
      ./catppuccin.nix # Catppuccin flavor/accent/icon control plane
      ./catppuccin-targets.nix # Centralized Catppuccin per-app enablement
      ./catppuccin-zen-browser.nix # Official Zen Browser Catppuccin CSS integration
      ./themes.nix # Theme runtime helpers (for example matugen tooling)
      ./shells.nix # niri/custom.kdl, caelestia, noctalia configs
      ./profile-integrations.nix # Profile-specific shell integrations
    ]
    ++ packRegistry.packModules;

  xdg.enable = true;

  # Niri compositor config — edit config/apps/niri/config.kdl for layout/input tweaks.
  # This is a symlink to the nix store; rebuild after changing the source file.
  xdg.configFile."niri/config.kdl".source = ../../../config/apps/niri/config.kdl;

  # Hyprland compositor configs are copied as regular files so they stay editable.
  # Only copy if a target file doesn't exist, so user edits persist across rebuilds.
  # - hyprland.conf: legacy/default Hyprland profile config (DMS-oriented)
  # - hyprland-caelestia.conf: dedicated config for the caelestia-hyprland profile
  home.activation.copyHyprlandConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${mutableCopy.mkCopyOnce {
      source = ../../../config/apps/hyprland/hyprland.conf;
      target = "$HOME/.config/hypr/hyprland.conf";
    }}

    ${mutableCopy.mkCopyOnce {
      source = ../../../config/apps/hyprland/hyprland-caelestia.conf;
      target = "$HOME/.config/hypr/hyprland-caelestia.conf";
    }}

    # Keep both configs user-editable even when they already exist.
    $DRY_RUN_CMD chmod u+w "$HOME/.config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland-caelestia.conf" 2>/dev/null || true
  '';

  home.pointerCursor = {
    name = "phinger-cursors";
    package = pkgs.phinger-cursors;
    size = 24;
    gtk.enable = true;
  };

  xdg.mimeApps =
    let
      nonFirefoxWebHandlers = [
        "brave-browser.desktop"
        "com.brave.Browser.desktop"
        "chromium-browser.desktop"
        "com.google.Chrome.desktop"
        "google-chrome.desktop"
        "zen.desktop"
        "dms-open.desktop"
      ];
    in
    {
      enable = true;
      defaultApplications = {
        "text/html" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/unknown" = [ "firefox.desktop" ];
        "application/json" = [ "code.desktop" ];
        # File manager — makes nemo appear in launchers and handle directory opens.
        "inode/directory" = [ "nemo.desktop" ];
        "application/x-gnome-saved-search" = [ "nemo.desktop" ];
      };

      associations = {
        added = {
          "text/html" = [ "firefox.desktop" ];
          "application/xhtml+xml" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
        };
        removed = {
          "text/html" = nonFirefoxWebHandlers;
          "application/xhtml+xml" = nonFirefoxWebHandlers;
          "x-scheme-handler/http" = nonFirefoxWebHandlers;
          "x-scheme-handler/https" = nonFirefoxWebHandlers;
        };
      };
    };

  xdg.userDirs = {
    enable = true;
    desktop = "$HOME/Desktop";
    download = "$HOME/Downloads";
    templates = "$HOME/Templates";
    publicShare = "$HOME/Public";
    documents = "$HOME/Documents";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
  };

}
