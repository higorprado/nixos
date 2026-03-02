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
}
