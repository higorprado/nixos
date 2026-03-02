{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
# Desktop shell profile abstraction.
#
# Profiles:
#   "dms"           (default) — Dank Material Shell with full greeter integration.
#   "niri-only"                — Bare Niri compositor, no DMS.
#   "noctalia"                  — Noctalia shell (quickshell-based) with niri compositor.
#   "dms-hyprland"              — Dank Material Shell with Hyprland compositor.
#   "caelestia-hyprland"        — Caelestia shell with Hyprland compositor.
#
# NOTE: The option definition for custom.desktop.profile is in modules/options.nix
# The niri, dms, and greeter NixOS modules are imported at the flake level.

let
  cfg = config.custom.desktop;
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.custom.user.name;
  homeDir = lib.attrByPath [ "users" "users" userName "home" ] "/home/${userName}" config;
  # Ensure portal-launched desktop entries (Exec=firefox, etc.) can resolve binaries.
  # xdg-desktop-portal runs with a sanitized PATH by default on NixOS.
  portalExecPath =
    "%h/.nix-profile/bin:"
    + "%h/.local/state/nix/profile/bin:"
    + "/etc/profiles/per-user/%u/bin:"
    + "/nix/profile/bin:"
    + "/nix/var/nix/profiles/default/bin:"
    + "/run/current-system/sw/bin";

  # DMS common settings (shared between dms and dms-hyprland)
  dmsCommonSettings = {
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;
  };
in
{
  config = lib.mkMerge [

    # ── Shared config (all desktop profiles) ─────────────────────────────────────

    {
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
        after = [
          "dbus.service"
          "graphical-session.target"
        ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig.Environment = [ "PATH=${portalExecPath}" ];
      };

      # Keep gtk portal backend with the same executable resolution path.
      systemd.user.services.xdg-desktop-portal-gtk = {
        serviceConfig.Environment = [ "PATH=${portalExecPath}" ];
      };

      # Power management for laptops
      services.upower.enable = true;

      # GNOME keyring — desktop-only (for credential storage)
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;
      services.dbus.packages = [ pkgs.gcr ];
      programs.seahorse.enable = true;

      # fcitx5 input method — needed for typing ç on Wayland
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5.addons = with pkgs; [
          fcitx5-gtk
          qt6Packages.fcitx5-qt
        ];
      };
    }

    # ── uinput for keyrs (conditional on feature flag) ─────────────────────────
    (lib.mkIf cfg.keyrs.enable {
      # Uinput kernel module + udev rules for the uinput group.
      # Required by keyrs to create virtual keyboard devices via /dev/uinput.
      hardware.uinput.enable = true;

      # Override uinput group to "input" — the user is already in the input group
      services.udev.extraRules = ''
        SUBSYSTEM=="misc", KERNEL=="uinput", GROUP="input", MODE="0660"
      '';
    })

    # ── DMS profile (Niri compositor) ─────────────────────────────────────────────
    (lib.mkIf (cfg.profile == "dms") {
      programs.niri = {
        enable = true;
        package = inputs.niri.packages.${system}.niri-unstable;
      };

      programs.dank-material-shell = {
        enable = true;
        greeter = {
          enable = true;
          compositor.name = "niri";
          configHome = homeDir;
          configFiles = [ "${homeDir}/.config/DankMaterialShell/settings.json" ];
        };
      }
      // dmsCommonSettings;

      programs.dsearch.enable = true;

      xdg.portal.config.niri.default = [ "gtk" ];

      systemd.user.services.xdg-desktop-portal-gtk = {
        after = [
          "niri.service"
          "graphical-session.target"
        ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    })

    # ── niri-only profile (minimal) ────────────────────────────────────────────────
    (lib.mkIf (cfg.profile == "niri-only") {
      programs.niri = {
        enable = true;
        package = inputs.niri.packages.${system}.niri-unstable;
      };

      # Launch niri directly via greetd without any shell/greeter wrapper
      services.greetd.settings.default_session = {
        command = "${inputs.niri.packages.${system}.niri-unstable}/bin/niri --session";
        user = userName;
      };

      # Use GTK portal for all interfaces in plain niri session
      xdg.portal.config.niri.default = [ "gtk" ];

      systemd.user.services.xdg-desktop-portal-gtk = {
        after = [
          "niri.service"
          "graphical-session.target"
        ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    })

    # ── Noctalia profile (quickshell + niri) ───────────────────────────────────────
    (lib.mkIf (cfg.profile == "noctalia") {
      programs.niri = {
        enable = true;
        package = inputs.niri.packages.${system}.niri-unstable;
      };

      # Launch niri directly via greetd — no DMS greeter
      services.greetd.settings.default_session = {
        command = "${inputs.niri.packages.${system}.niri-unstable}/bin/niri --session";
        user = userName;
      };

      xdg.portal.config.niri.default = [ "gtk" ];

      systemd.user.services.xdg-desktop-portal-gtk = {
        after = [
          "niri.service"
          "graphical-session.target"
        ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

    })

    # ── DMS-Hyprland profile ───────────────────────────────────────────────────────
    (lib.mkIf (cfg.profile == "dms-hyprland") {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${system}.hyprland;
      };

      programs.dank-material-shell = {
        enable = true;
        greeter = {
          enable = true;
          compositor.name = "hyprland";
          configHome = homeDir;
          configFiles = [ "${homeDir}/.config/DankMaterialShell/settings.json" ];
        };
      }
      // dmsCommonSettings;

      programs.dsearch.enable = true;

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

    # ── Caelestia-Hyprland profile ─────────────────────────────────────────────────
    (lib.mkIf (cfg.profile == "caelestia-hyprland") {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${system}.hyprland;
      };

      # Use a graphical greetd greeter instead of direct compositor autologin.
      programs.regreet.enable = true;
      services.greetd.settings.default_session.user = "greeter";

      # Add an explicit session entry that launches the profile-specific Hyprland
      # config through the official startup wrapper.
      services.displayManager.sessionPackages = [
        (pkgs.writeTextFile {
          name = "caelestia-hyprland-session";
          text = ''
            [Desktop Entry]
            Name=Caelestia Hyprland
            Comment=Hyprland with Caelestia profile configuration
            Exec=${
              inputs.hyprland.packages.${system}.hyprland
            }/bin/start-hyprland -- --config ${homeDir}/.config/hypr/hyprland-caelestia.conf
            Type=Application
            DesktopNames=Hyprland
          '';
          destination = "/share/wayland-sessions/caelestia-hyprland.desktop";
          derivationArgs.passthru.providedSessions = [ "caelestia-hyprland" ];
        })
      ];

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

  ];

}
