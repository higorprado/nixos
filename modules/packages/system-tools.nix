# System utility packages
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Filesystem tools
    btrfs-progs
  ];
}
