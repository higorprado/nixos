{ pkgs, inputs }:

{
  linuwu-sense = pkgs.callPackage ./linuwu-sense.nix { };
  predator-tui = pkgs.callPackage ./predator-tui.nix { };
  keyrs = pkgs.callPackage ./keyrs.nix { src = inputs.keyrsSource; };
  dms-awww = pkgs.callPackage ./dms-awww.nix { src = inputs.dmsAwwwSource; };
  rmpc = inputs.rmpc.packages.${pkgs.system}.default;
  catppuccin-zen-browser = pkgs.callPackage ./catppuccin-zen-browser.nix {
    src = inputs.catppuccinZenBrowserSource;
  };
}
