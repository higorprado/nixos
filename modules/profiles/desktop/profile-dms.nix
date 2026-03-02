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
  hasNiriOption = lib.hasAttrByPath [ "programs" "niri" "enable" ] options;
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
  config = lib.mkIf (desktopHost && cfg.profile == "dms") (
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
  );
}
