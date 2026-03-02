{
  config,
  lib,
  ...
}:
let
  profile = config.custom.desktop.profile;
  hostRole = config.custom.host.role;
  isDesktopHost = hostRole == "desktop";
in
{
  config.custom.desktop.capabilities = {
    desktopFiles = isDesktopHost && lib.elem profile [
      "dms"
      "dms-hyprland"
      "caelestia-hyprland"
      "noctalia"
    ];

    desktopUserApps = isDesktopHost && lib.elem profile [
      "dms"
      "dms-hyprland"
      "caelestia-hyprland"
      "noctalia"
    ];

    niri = isDesktopHost && lib.elem profile [
      "dms"
      "niri-only"
      "noctalia"
    ];

    hyprland = isDesktopHost && lib.elem profile [
      "dms-hyprland"
      "caelestia-hyprland"
    ];

    dms = isDesktopHost && lib.elem profile [
      "dms"
      "dms-hyprland"
    ];

    noctalia = isDesktopHost && profile == "noctalia";

    caelestiaHyprland = isDesktopHost && profile == "caelestia-hyprland";
  };
}
