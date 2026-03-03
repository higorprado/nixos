{
  schemaVersion = 1;

  packs = {
    apps = {
      module = ./apps.nix;
    };
    files = {
      module = ./files.nix;
    };
    viewers = {
      module = ./viewers.nix;
    };
    media = {
      module = ./media.nix;
    };
    music-client = {
      module = ./music-client.nix;
    };
    monitors = {
      module = ./monitors.nix;
    };
  };

  packSets = {
    base = [ "monitors" ];
    desktop-user = [
      "apps"
      "viewers"
      "media"
      "music-client"
    ];
    desktop-files = [ "files" ];
  };
}
