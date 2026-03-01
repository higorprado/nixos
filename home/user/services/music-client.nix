{ config, lib, osConfig, ... }:

let
  homeDir = config.home.homeDirectory;
in
lib.mkIf
  (
    osConfig.custom.desktop.profile == "dms"
    || osConfig.custom.desktop.profile == "dms-hyprland"
    || osConfig.custom.desktop.profile == "caelestia-hyprland"
      || osConfig.custom.desktop.profile == "noctalia"
  )
{
  services.mpd = {
    enable = true;
    enableSessionVariables = false;

    musicDirectory = "${homeDir}/Music";
    dataDir = "${config.xdg.stateHome}/mpd";
    playlistDirectory = "${config.xdg.configHome}/mpd/playlists";
    dbFile = "${config.xdg.stateHome}/mpd/database";

    network = {
      listenAddress = "/tmp/mpd_socket";
      port = 6600;
    };

    extraConfig = ''
      auto_update             "yes"
      restore_paused          "yes"

      audio_output {
          type                "pipewire"
          name                "PipeWire Output"
      }
    '';
  };

}
