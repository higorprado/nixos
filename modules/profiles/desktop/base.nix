{
  config,
  lib,
  pkgs,
  ...
}:
let
  userName = config.custom.user.name;
  # Ensure portal-launched desktop entries (Exec=firefox, etc.) can resolve binaries.
  # xdg-desktop-portal runs with a sanitized PATH by default on NixOS.
  portalExecPath =
    "%h/.nix-profile/bin:"
    + "%h/.local/state/nix/profile/bin:"
    + "/etc/profiles/per-user/%u/bin:"
    + "/nix/profile/bin:"
    + "/nix/var/nix/profiles/default/bin:"
    + "/run/current-system/sw/bin";
in
lib.mkIf (config.custom.host.role == "desktop") {
  # Display manager
  services.greetd.enable = true;

  # Xwayland support for running X11 apps in Wayland
  programs.xwayland.enable = true;

  # Disable niri-flake-polkit (we handle polkit differently)
  systemd.user.services.niri-flake-polkit.enable = false;

  # XDG portals
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
  ];

  # Portal services configuration
  systemd.user.services.xdg-desktop-portal = {
    # Keep portal services in the real desktop user session and out of the greeter.
    unitConfig.ConditionUser = userName;
    serviceConfig = {
      Environment = [ "PATH=${portalExecPath}" ];
    };
  };

  # Keep gtk portal backend with the same executable resolution path.
  systemd.user.services.xdg-desktop-portal-gtk = {
    unitConfig.ConditionUser = userName;
    serviceConfig = {
      Environment = [ "PATH=${portalExecPath}" ];
    };
  };

  # Power management for laptops
  services.upower.enable = true;

  # GNOME keyring — desktop-only (for credential storage)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  services.dbus.packages = [ pkgs.gcr ];
  programs.seahorse.enable = true;

  # fcitx5 input method — needed for typing c-cedilla on Wayland
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      qt6Packages.fcitx5-qt
    ];
  };
}
