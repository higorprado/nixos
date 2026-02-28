# System packages
{ ... }:
{
  imports = [
    ./toolchains.nix
    ./system-tools.nix
    ./docs-tools.nix
    ./fonts.nix
  ];
}
