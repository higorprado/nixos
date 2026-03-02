{
  config,
  lib,
  inputs,
  customPkgs,
  llm-agents-pkgs,
  ...
}:
let
  userName = config.custom.user.name;
  desktopHost = config.custom.host.role == "desktop";
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs customPkgs llm-agents-pkgs; };
    sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
    ];
    users.${userName} =
      {
        pkgs,
        llm-agents-pkgs,
        inputs,
        customPkgs,
        ...
      }:
      {
        home.username = userName;
        home.homeDirectory = "/home/${userName}";
        home.stateVersion = "25.11";

        imports =
          [
            ./core # Essential CLI tools
            ./shell # fish, starship, terminal utilities
            ./programs # editors, terminals, shells, tools, gui apps
            ./apps # shared user app configs (cross-program or uncategorized)
            ./dev # dev tools, devenv, ai-agents
            ./services # keyrs, wallpaper (awww+dms-awww), backups, mpd, gtk-layer
          ]
          ++ lib.optionals desktopHost [ ./desktop ] # desktop-only HM modules
          ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

      };
  };
}
