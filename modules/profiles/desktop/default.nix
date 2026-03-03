# Desktop profile modules aggregator
{ ... }:
let
  profileModules = import ./profile-registry.nix;
  profileNames = builtins.attrNames profileModules;
in
{
  imports =
    [
      ./base.nix
      ./capability-shared.nix
    ]
    ++ map (name: profileModules.${name}) profileNames;
}
