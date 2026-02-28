# Bluetooth hardware support
# Import only in hosts that have Bluetooth hardware
{ ... }:
{
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
