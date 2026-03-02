{ lib, ... }:
{
  options.custom.desktop.keyrs.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable keyrs keyboard remapper service";
  };

  options.custom.desktop.profile = lib.mkOption {
    type = lib.types.enum [ "dms" "niri-only" "noctalia" "dms-hyprland" "caelestia-hyprland" ];
    default = "dms";
    description = "Desktop profile to use";
  };
}
