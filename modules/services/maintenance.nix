# System maintenance services
# fstrim (SSD trim), smartd (SSD health monitoring)
{ ... }:
{
  # SSD maintenance - TRIM timer
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # SSD Health Monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
  };
}
