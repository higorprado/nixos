# Desktop file-stack system settings
# Shared by desktop-capable profiles
{ config, lib, ... }:
{
  config = lib.mkIf config.custom.desktop.capabilities.desktopFiles {
    # gvfs daemon: required for nemo trash, network mounts, MTP, etc.
    services.gvfs.enable = true;

    # dconf/GSettings backend: nemo reads preferences via GSettings.
    programs.dconf.enable = true;
  };
}
