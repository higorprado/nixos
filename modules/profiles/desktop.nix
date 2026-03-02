{
  config,
  lib,
  inputs,
  options,
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
  desktopHost = config.custom.host.role == "desktop";
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.custom.user.name;
  homeDir = lib.attrByPath [ "users" "users" userName "home" ] "/home/${userName}" config;
  hasNiriOption = lib.hasAttrByPath [ "programs" "niri" "enable" ] options;
  hasHyprlandOption = lib.hasAttrByPath [ "programs" "hyprland" "enable" ] options;
  hasDmsOption = lib.hasAttrByPath [ "programs" "dank-material-shell" "enable" ] options;
  hasRegreetOption = lib.hasAttrByPath [ "programs" "regreet" "enable" ] options;

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
  config = lib.mkIf desktopHost (lib.mkMerge [
    # ── DMS profile (Niri compositor) ─────────────────────────────────────────────
    (lib.mkIf (cfg.profile == "dms") (
      lib.mkMerge [
        (lib.optionalAttrs hasNiriOption {
          programs.niri = {
            enable = true;
            package = inputs.niri.packages.${system}.niri-unstable;
          };
        })
        (lib.optionalAttrs hasDmsOption {
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
        })
      ]
    ))

    # ── niri-only profile (minimal) ────────────────────────────────────────────────
    (lib.mkIf (cfg.profile == "niri-only") (
      lib.mkMerge [
        (lib.optionalAttrs hasNiriOption {
          programs.niri = {
            enable = true;
            package = inputs.niri.packages.${system}.niri-unstable;
          };
        })
        {
          # Launch niri directly via greetd without any shell/greeter wrapper
          services.greetd.settings.default_session = {
            command = "${inputs.niri.packages.${system}.niri-unstable}/bin/niri --session";
            user = userName;
          };
        }
      ]
    ))

    # ── Noctalia profile (quickshell + niri) ───────────────────────────────────────
    (lib.mkIf (cfg.profile == "noctalia") (
      lib.mkMerge [
        (lib.optionalAttrs hasNiriOption {
          programs.niri = {
            enable = true;
            package = inputs.niri.packages.${system}.niri-unstable;
          };
        })
        {
          # Launch niri directly via greetd — no DMS greeter
          services.greetd.settings.default_session = {
            command = "${inputs.niri.packages.${system}.niri-unstable}/bin/niri --session";
            user = userName;
          };
        }
      ]
    ))

    # ── DMS-Hyprland profile ───────────────────────────────────────────────────────
    (lib.mkIf (cfg.profile == "dms-hyprland") (
      lib.mkMerge [
        (lib.optionalAttrs hasHyprlandOption {
          programs.hyprland = {
            enable = true;
            package = inputs.hyprland.packages.${system}.hyprland;
          };
        })
        (lib.optionalAttrs hasDmsOption {
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
        })
      ]
    ))

    # ── Caelestia-Hyprland profile ─────────────────────────────────────────────────
    (lib.mkIf (cfg.profile == "caelestia-hyprland") (
      lib.mkMerge [
        (lib.optionalAttrs hasHyprlandOption {
          programs.hyprland = {
            enable = true;
            package = inputs.hyprland.packages.${system}.hyprland;
          };
        })
        (lib.optionalAttrs hasRegreetOption {
          # Use a graphical greetd greeter instead of direct compositor autologin.
          programs.regreet.enable = true;
        })
        {
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
        }
      ]
    ))

  ]);

}
