# Machine type profiles
{ ... }:
{
  imports = [
    ./profile-capabilities.nix
    ./desktop-base.nix
    ./desktop-capability-shared.nix
    ./desktop.nix
    ./desktop-files.nix
  ];
}
