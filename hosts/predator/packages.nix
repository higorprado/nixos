{
  config,
  lib,
  pkgs,
  customPkgs,
  ...
}:

{
  environment.systemPackages = [
    customPkgs.predator-tui
  ]
  ++
    lib.optionals
      (config.custom.desktop.profile == "dms" || config.custom.desktop.profile == "dms-hyprland")
      (
        with pkgs;
        [
          (writeShellScriptBin "awww" ''exec ${swww}/bin/swww "$@"'')
          (writeShellScriptBin "awww-daemon" ''exec ${swww}/bin/swww-daemon "$@"'')
          customPkgs.dms-awww
        ]
      )
  # NVIDIA GPU monitoring
  ++ lib.optionals (config.custom.desktop.profile != "server") (
    with pkgs;
    [
      nvtopPackages.nvidia
    ]
  )
  # TPM2 tools for Predator laptop
  ++ (with pkgs; [ tpm2-tools ]);
}
