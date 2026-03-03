{
  dms = {
    capabilities = {
      desktopFiles = true;
      desktopUserApps = true;
      niri = true;
      hyprland = false;
      dms = true;
      noctalia = false;
      caelestiaHyprland = false;
    };
    requiredIntegrations = [
      "niri"
      "dms"
    ];
    optionalIntegrations = [ ];
    packSets = [
      "base"
      "desktop-user"
      "desktop-files"
    ];
  };

  niri-only = {
    capabilities = {
      desktopFiles = false;
      desktopUserApps = false;
      niri = true;
      hyprland = false;
      dms = false;
      noctalia = false;
      caelestiaHyprland = false;
    };
    requiredIntegrations = [ "niri" ];
    optionalIntegrations = [ ];
    packSets = [ "base" ];
  };

  noctalia = {
    capabilities = {
      desktopFiles = true;
      desktopUserApps = true;
      niri = true;
      hyprland = false;
      dms = false;
      noctalia = true;
      caelestiaHyprland = false;
    };
    requiredIntegrations = [ "niri" ];
    optionalIntegrations = [ "noctalia-shell" ];
    packSets = [
      "base"
      "desktop-user"
      "desktop-files"
    ];
  };

  dms-hyprland = {
    capabilities = {
      desktopFiles = true;
      desktopUserApps = true;
      niri = false;
      hyprland = true;
      dms = true;
      noctalia = false;
      caelestiaHyprland = false;
    };
    requiredIntegrations = [
      "hyprland"
      "dms"
    ];
    optionalIntegrations = [ ];
    packSets = [
      "base"
      "desktop-user"
      "desktop-files"
    ];
  };

  caelestia-hyprland = {
    capabilities = {
      desktopFiles = true;
      desktopUserApps = true;
      niri = false;
      hyprland = true;
      dms = false;
      noctalia = false;
      caelestiaHyprland = true;
    };
    requiredIntegrations = [ "hyprland" ];
    optionalIntegrations = [ "caelestia-shell" ];
    packSets = [
      "base"
      "desktop-user"
      "desktop-files"
    ];
  };
}
