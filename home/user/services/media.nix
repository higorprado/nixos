{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  services.mpd = {
    enable = true;
    musicDirectory = "${homeDir}/Music";
  };
}
