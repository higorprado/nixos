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
  hasDmsOption = lib.hasAttrByPath [ "programs" "dank-material-shell" "enable" ] options;

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
  config = lib.mkIf (desktopHost && cfg.profile == "dms-hyprland") (
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
  );
}
