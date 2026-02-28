# Podman container runtime (all machines)
{ pkgs, ... }:
{
  # Podman (Docker alternative, rootless by default)
  # Note: Docker is configured separately in docker.nix
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Keep Docker CLI bound to Docker daemon
  };

  # Distrobox for containerized development environments
  environment.systemPackages = [ pkgs.distrobox ];
}
