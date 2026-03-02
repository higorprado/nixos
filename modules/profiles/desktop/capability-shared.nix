{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;
  caps = cfg.capabilities;
  desktopHost = config.custom.host.role == "desktop";
  userName = config.custom.user.name;
  hasDsearchOption = lib.hasAttrByPath [ "programs" "dsearch" "enable" ] options;

  # Ensure portal-launched desktop entries (Exec=firefox, etc.) can resolve binaries.
  # xdg-desktop-portal runs with a sanitized PATH by default on NixOS.
  portalExecPath =
    "%h/.nix-profile/bin:"
    + "%h/.local/state/nix/profile/bin:"
    + "/etc/profiles/per-user/%u/bin:"
    + "/nix/profile/bin:"
    + "/nix/var/nix/profiles/default/bin:"
    + "/run/current-system/sw/bin";

  niriPortalConfig = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };
in
{
  config = lib.mkIf desktopHost (lib.mkMerge [

    # Niri-profile portal policy (dms / niri-only / noctalia)
    (lib.mkIf caps.niri {
      # Use GNOME backend for screencast/remote-desktop/secret on niri.
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
      xdg.portal.config.niri = niriPortalConfig;

      # Keep GNOME portal backend in the same session scope and executable path.
      systemd.user.services.xdg-desktop-portal-gnome = {
        unitConfig.ConditionUser = userName;
        serviceConfig = {
          Environment = [ "PATH=${portalExecPath}" ];
        };
      };
    })

    # Uinput for keyrs (conditional on feature flag)
    (lib.mkIf cfg.keyrs.enable {
      # Uinput kernel module + udev rules for the uinput group.
      # Required by keyrs to create virtual keyboard devices via /dev/uinput.
      hardware.uinput.enable = true;

      # Override uinput group to "input" — the user is already in the input group
      services.udev.extraRules = ''
        SUBSYSTEM=="misc", KERNEL=="uinput", GROUP="input", MODE="0660"
      '';
    })

    # DMS capability shared settings (dms + dms-hyprland)
    (lib.mkIf caps.dms (
      lib.mkMerge [
        (lib.optionalAttrs hasDsearchOption {
          programs.dsearch.enable = true;
          systemd.user.services.dsearch.unitConfig.ConditionUser = userName;
        })
      ]
    ))

    # Hyprland capability shared portal policy
    (lib.mkIf caps.hyprland {
      xdg.portal.config.hyprland.default = [ "gtk" ];

      systemd.user.services.xdg-desktop-portal-gtk = {
        after = [
          "hyprland.service"
          "graphical-session.target"
        ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      systemd.user.services.xdg-desktop-portal-hyprland = {
        after = [
          "hyprland.service"
          "graphical-session.target"
        ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 3;
        };
      };
    })
  ]);
}
