{ config, pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 1.0;
        dimensions = {
          columns = 80;
          lines = 24;
        };
        padding = {
          x = 4;
          y = 4;
        };
      };
      font = {
        normal = {
          family = "JetBrains Mono Nerd Font Mono";
          style = "Regular";
        };
        size = 12;
      };
    };
  };
}
