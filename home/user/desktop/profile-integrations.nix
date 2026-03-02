{
  lib,
  osConfig,
  inputs,
  ...
}:
{
  # Profile-specific Home Manager integrations belong in the home layer.
  imports =
    lib.optionals osConfig.custom.desktop.capabilities.noctalia [
      inputs.noctalia.homeModules.default
      (
        { ... }:
        {
          programs.noctalia-shell = {
            enable = true;
            systemd.enable = true;
          };
        }
      )
    ]
    ++ lib.optionals osConfig.custom.desktop.capabilities.caelestiaHyprland [
      inputs.caelestia-shell.homeManagerModules.default
      (
        { ... }:
        {
          programs.caelestia = {
            enable = true;
            systemd.enable = true;
            systemd.target = "graphical-session.target";
            cli.enable = true;
          };
        }
      )
    ];
}
