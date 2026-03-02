# File management and archive tools
# Nemo file manager, thumbnails, archive tools
{
  pkgs,
  lib,
  osConfig,
  ...
}:
lib.mkIf osConfig.custom.desktop.capabilities.desktopUserApps
  {
    home.packages = with pkgs; [
      # Nemo file manager (with extensions)
      nemo-with-extensions

      # Thumbnail generation for file managers
      tumbler
      ffmpegthumbnailer

      # Archive tools
      p7zip
      unrar
      file-roller
    ];

    # Override nemo's .desktop so launchers can find it by name ("Nemo") and by
    # the standard FileManager category. The upstream file ships as Name=Files
    # with no FileManager category, which causes most launchers to miss it.
    xdg.dataFile."applications/nemo.desktop".text = ''
      [Desktop Entry]
      Name=Nemo
      GenericName=File Manager
      Comment=Access and organize files
      Exec=nemo %U
      Icon=system-file-manager
      Terminal=false
      Type=Application
      StartupNotify=false
      Categories=GTK;Utility;FileManager;
      MimeType=inode/directory;application/x-gnome-saved-search;
      Keywords=files;folder;filesystem;explorer;nemo;

      [Desktop Action open-home]
      Name=Home
      Exec=nemo %U

      [Desktop Action open-computer]
      Name=Computer
      Exec=nemo computer:///

      [Desktop Action open-trash]
      Name=Trash
      Exec=nemo trash:///
    '';

    # Nemo's "Open Terminal Here" reads exec from GSettings at spawn time.
    # Using the bare name "kitty" fails because nemo's subprocess doesn't
    # inherit the user profile PATH. The fix is the full Nix store path so no
    # PATH resolution is needed.
    dconf.settings = {
      "org/cinnamon/desktop/applications/terminal" = {
        exec = "${pkgs.kitty}/bin/kitty";
        exec-arg = "--";
      };
    };
  }
