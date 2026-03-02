# Desktop profile modules aggregator
{ ... }:
{
  imports = [
    ./base.nix
    ./capability-shared.nix
    ./profile-dms.nix
    ./profile-niri-only.nix
    ./profile-noctalia.nix
    ./profile-dms-hyprland.nix
    ./profile-caelestia-hyprland.nix
  ];
}
