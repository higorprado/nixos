# Machine type profiles
{ ... }:
{
  imports = [
    ./profile-capabilities.nix
    ./desktop/default.nix
    ./desktop-files.nix
  ];
}
