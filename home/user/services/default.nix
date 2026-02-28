{ ... }:

{
  imports = [
    ./keyrs.nix
    ./wallpaper.nix
    ./media.nix
    ./backup.nix # Daily backup of SSH keys, GPG keys, dconf
  ];
}
