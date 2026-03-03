{
  config,
  lib,
  ...
}:
let
  profile = config.custom.desktop.profile;
  hostRole = config.custom.host.role;
  isDesktopHost = hostRole == "desktop";
  profileMetadata = import ./desktop/profile-metadata.nix;
  defaultCapabilities = {
    desktopFiles = false;
    desktopUserApps = false;
    niri = false;
    hyprland = false;
    dms = false;
    noctalia = false;
    caelestiaHyprland = false;
  };
  selectedProfile =
    if builtins.hasAttr profile profileMetadata then
      profileMetadata.${profile}
    else
      null;
in
{
  config.custom.desktop.capabilities =
    if !isDesktopHost || selectedProfile == null then
      defaultCapabilities
    else
      defaultCapabilities // selectedProfile.capabilities;
}
