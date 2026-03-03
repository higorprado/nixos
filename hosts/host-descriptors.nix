{
  predator = {
    role = "desktop";
    desktopProfile = "dms";
    integrations = {
      disko = true;
      niri = true;
      hyprland = true;
      dms = true;
      homeManager = true;
      keyrs = true;
    };
  };

  server-example = {
    role = "server";
    desktopProfile = "dms";
    integrations = { };
  };
}
