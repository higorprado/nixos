# Core system modules
{ ... }:
{
  imports = [
    ./system.nix
    ./networking.nix
    ./security.nix
    ./keyboard.nix
    ./nix-tools.nix
  ];
}
