# Networking configuration
# DNS resolution, NetworkManager, Avahi mDNS
{ ... }:
{
  # NetworkManager
  networking.networkmanager.enable = true;

  # DNS resolution (systemd-resolved + NetworkManager integration)
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved = {
    enable = true;
    settings.Resolve.DNSSEC = "allow-downgrade";
  };

  # mDNS for hostname.local resolution
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };
}
