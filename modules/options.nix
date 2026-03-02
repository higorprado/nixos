# Custom options and feature flags
{ lib, ... }:
{
  options.custom.user.name = lib.mkOption {
    type = lib.types.str;
    default = "user";
    description = "Primary local username for system and Home Manager wiring";
  };

  options.custom.host.role = lib.mkOption {
    type = lib.types.enum [
      "desktop"
      "server"
    ];
    default = "desktop";
    description = "Host role used to gate desktop-only behavior";
  };

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
