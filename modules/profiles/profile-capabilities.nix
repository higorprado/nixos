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
  options.custom.desktop.capabilities = {
    desktopFiles = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether desktop file-stack services (for example gvfs/dconf) should be enabled.";
    };

    desktopUserApps = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether desktop user application modules should be enabled.";
    };

    niri = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the selected profile uses Niri as compositor.";
    };

    hyprland = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the selected profile uses Hyprland as compositor.";
    };

    dms = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the selected profile uses Dank Material Shell.";
    };

    noctalia = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the selected profile is Noctalia.";
    };

    caelestiaHyprland = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the selected profile is Caelestia-Hyprland.";
    };
  };

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
