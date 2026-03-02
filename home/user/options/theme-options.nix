{ lib, ... }:
{
  options.custom.theme.zen.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable official Catppuccin Zen Browser CSS theme sync.";
  };
}
