# Music client stack
# mpd, rmpc, youtube runtime dependencies, and config payload wiring
{
  lib,
  pkgs,
  customPkgs,
  osConfig,
  ...
}:

lib.mkIf
  (
    osConfig.custom.desktop.profile == "dms"
    || osConfig.custom.desktop.profile == "dms-hyprland"
    || osConfig.custom.desktop.profile == "caelestia-hyprland"
    || osConfig.custom.desktop.profile == "noctalia"
  )
  {
    home.packages = with pkgs; [
      # Runtime requirements for rmpc youtube playback
      ffmpeg
      (python3.withPackages (ps: [ ps.mutagen ]))

      # Music client stack
      mpd
      customPkgs.rmpc
    ];

    xdg.configFile."mpd/mpd.conf".source = ../../../config/apps/mpd/mpd.conf;
    xdg.configFile."rmpc/config.ron".source = ../../../config/apps/rmpc/config.ron;
    xdg.configFile."rmpc/themes/cap_mac.ron".source = ../../../config/apps/rmpc/themes/cap_mac.ron;
  }
