{
  config,
  lib,
  inputs,
  options,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;
  desktopHost = config.custom.host.role == "desktop";
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.custom.user.name;
  homeDir = lib.attrByPath [ "users" "users" userName "home" ] "/home/${userName}" config;
  hasHyprlandOption = lib.hasAttrByPath [ "programs" "hyprland" "enable" ] options;
  hasRegreetOption = lib.hasAttrByPath [ "programs" "regreet" "enable" ] options;
in
{
  config = lib.mkIf (desktopHost && cfg.profile == "caelestia-hyprland") (
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
  );
}
