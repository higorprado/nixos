# Shared binary cache configuration.
{ ... }:
{
  nix.settings.substituters = [ "https://cache.numtide.com" ];
  nix.settings.trusted-public-keys = [
    "cache.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
}
