{ den, ... }:
{
  den.aspects.docker = den.lib.parametric {
    includes = [
      ({ user, ... }: {
        nixos.users.users.${user.userName}.extraGroups = [ "docker" ];
      })
    ];

    nixos =
      { ... }:
      {
        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          daemon.settings = {
            data-root = "/persist/var/lib/docker";
          };
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
        };
      };
  };
}
