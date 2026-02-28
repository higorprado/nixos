{ lib, osConfig, inputs, ... }:
let
  profile = osConfig.custom.desktop.profile;
in
{
  # Profile-specific Home Manager integrations belong in the home layer.
  imports =
    lib.optionals (profile == "noctalia") [
      inputs.noctalia.homeModules.default
      ({ ... }: {
        programs.noctalia-shell = {
          enable = true;
          systemd.enable = true;
        };
      })
    ]
    ++ lib.optionals (profile == "caelestia-hyprland") [
      inputs.caelestia-shell.homeManagerModules.default
      ({ ... }: {
        programs.caelestia = {
          enable = true;
          systemd.enable = true;
          systemd.target = "graphical-session.target";
          cli.enable = true;
        };
      })
    ];
}
