{ pkgs, lib, ... }:
{
  imports = [
    ./wayland.nix # Wayland tools (waybar, swww, wl-clipboard, etc.)
    ./apps.nix # Desktop GUI applications (firefox, chrome, teams, meld)
    ./files.nix # File management (nemo, thumbnails, archive tools)
    ./catppuccin.nix # Catppuccin flavor/accent/icon control plane
    ./catppuccin-targets.nix # Centralized Catppuccin per-app enablement
    ./catppuccin-zen-browser.nix # Official Zen Browser Catppuccin CSS integration
    ./themes.nix # Theme runtime helpers (for example matugen tooling)
    ./media.nix # Generic media applications (vlc, yt-dlp, cava, pavucontrol)
    ./music-client.nix # Music client stack (mpd, rmpc, configs)
    ./monitors.nix # btop, bottom, htop configs
    ./shells.nix # niri/custom.kdl, caelestia, noctalia configs
    ./profile-integrations.nix # Profile-specific shell integrations
  ];

  xdg.enable = true;

  # Niri compositor config — edit config/apps/niri/config.kdl for layout/input tweaks.
  # This is a symlink to the nix store; rebuild after changing the source file.
  xdg.configFile."niri/config.kdl".source = ../../../config/apps/niri/config.kdl;

  # Hyprland compositor configs are copied as regular files so they stay editable.
  # Only copy if a target file doesn't exist, so user edits persist across rebuilds.
  # - hyprland.conf: legacy/default Hyprland profile config (DMS-oriented)
  # - hyprland-caelestia.conf: dedicated config for the caelestia-hyprland profile
  home.activation.copyHyprlandConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/hypr
    # Preserve edits by copying only on first provision.
    if [ ! -f ~/.config/hypr/hyprland.conf ]; then
      cp ${../../../config/apps/hyprland/hyprland.conf} ~/.config/hypr/hyprland.conf
    fi
    if [ ! -f ~/.config/hypr/hyprland-caelestia.conf ]; then
      cp ${../../../config/apps/hyprland/hyprland-caelestia.conf} ~/.config/hypr/hyprland-caelestia.conf
    fi
    chmod +w ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland-caelestia.conf
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
