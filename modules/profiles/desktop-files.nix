# Desktop file-stack system settings
# Shared by desktop-capable profiles
{ config, lib, ... }:
let
  profile = config.custom.desktop.profile;
  desktopFilesEnabled =
    profile == "dms"
    || profile == "dms-hyprland"
    || profile == "caelestia-hyprland"
    || profile == "noctalia";
in
{
  config = lib.mkIf desktopFilesEnabled {
    # gvfs daemon: required for nemo trash, network mounts, MTP, etc.
    services.gvfs.enable = true;

    # dconf/GSettings backend: nemo reads preferences via GSettings.
    programs.dconf.enable = true;
  };
}
