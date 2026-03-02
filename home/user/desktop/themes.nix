{ pkgs, ... }:

{
  # Runtime tool used by wallpaper/theme integrations.
  home.packages = with pkgs; [
    matugen
  ];
}
