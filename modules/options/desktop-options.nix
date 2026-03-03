{ lib, ... }:
let
  profileModules = import ../profiles/desktop/profile-registry.nix;
  profileNames = builtins.attrNames profileModules;
in
{
  options.custom.desktop.keyrs.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable keyrs keyboard remapper service";
  };

  options.custom.desktop.profile = lib.mkOption {
    type = lib.types.enum profileNames;
    default = "dms";
    description = "Desktop profile to use";
  };
}
