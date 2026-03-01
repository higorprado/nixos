{ ... }:

{
  imports = [
    ./keyrs.nix
    ./wallpaper.nix
    ./music-client.nix
    ./backup.nix # Daily backup of SSH keys, GPG keys, dconf
  ];
}
