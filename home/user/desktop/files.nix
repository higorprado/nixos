# File management and archive tools
# Nautilus file manager, thumbnails, archive tools
{
  pkgs,
  lib,
  osConfig,
  ...
}:
lib.mkIf osConfig.custom.desktop.capabilities.desktopUserApps
  {
    home.packages = with pkgs; [
      # Nautilus file manager
      nautilus

      # Thumbnail generation for file managers
      tumbler
      ffmpegthumbnailer

      # Archive tools
      p7zip
      unrar
      file-roller
    ];
  }
