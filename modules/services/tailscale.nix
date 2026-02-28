# Tailscale VPN mesh network
{ ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
}
