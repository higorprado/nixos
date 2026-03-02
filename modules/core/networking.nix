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
    # Avoid running two mDNS responders at the same time (resolved + avahi).
    settings.Resolve.MulticastDNS = false;
  };

  # Some D-Bus policy fragments reference the legacy "netdev" group.
  # Defining it avoids runtime warning spam on hosts where this group is absent.
  users.groups.netdev = { };

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
