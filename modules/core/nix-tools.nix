# Nix tools - nh program (universal)
# Easy way to run Nix commands and manage generations
{ ... }:
{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}
