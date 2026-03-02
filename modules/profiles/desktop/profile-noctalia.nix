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
  hasNiriOption = lib.hasAttrByPath [ "programs" "niri" "enable" ] options;
in
{
  config = lib.mkIf (desktopHost && cfg.profile == "noctalia") (
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
  );
}
