# Docker container runtime (all machines)
{ config, lib, pkgs, ... }:
{
  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Docker Compose v2 is included with docker package
  # No need for separate docker-compose package
}
