{ den, ... }:
{
  den.aspects.dms = den.lib.parametric {
    includes = [
      (den.lib.take.exactly (
        { host, user, ... }:
        let
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
          nixos =
            { config, lib, ... }:
            let
              trackedUser = import ../../../lib/primary-tracked-user.nix { inherit lib; };
              userName = trackedUser.primaryTrackedUserName host;
              homeDir = config.users.users.${userName}.home;
            in
            {
              home-manager.sharedModules = [ host.inputs.dms.homeModules.dank-material-shell ];

              programs.dsearch.enable = true;

              programs.dank-material-shell.greeter = {
                enable = true;
                compositor.name = "niri";
                configHome = homeDir;
                configFiles = [ "${homeDir}/.config/DankMaterialShell/settings.json" ];
              };
            };

          homeManager = {
            programs.dank-material-shell =
              {
                enable = true;
              }
              // dmsCommonSettings;
          };
        }
      ))
    ];
  };
}
