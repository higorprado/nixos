{ lib, ... }:
{
  options.custom.terminal.default = lib.mkOption {
    type = lib.types.enum [
      "foot"
      "ghostty"
      "kitty"
      "alacritty"
      "wezterm"
    ];
    default = "foot";
    description = "Default terminal emulator. Sets the TERMINAL session variable.";
  };
}
