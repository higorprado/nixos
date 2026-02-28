{ config, lib, ... }:
let
  userName = config.custom.user.name;
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    users.${userName} = { pkgs, llm-agents-pkgs, inputs, customPkgs, ... }: {
      home.username = userName;
      home.homeDirectory = "/home/${userName}";
      home.stateVersion = "25.11";

      imports = [
        ./core # Essential CLI tools
        ./shell # fish, starship, terminal utilities
        ./programs # editors, terminals, shells, tools, gui apps
        ./apps # misc application configs (legacy)
        ./dev # dev tools, devenv, ai-agents
        ./desktop # gtk theme, cursor, xdg dirs/mime, niri/mpd configs
        ./services # keyrs, wallpaper (awww+dms-awww), backups, mpd, gtk-layer
      ] ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

    };
  };
}
