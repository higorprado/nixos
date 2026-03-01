# Desktop GUI applications
# Firefox, Chrome, Teams, Meld
{ pkgs, config, lib, osConfig, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
lib.mkIf
  (
    osConfig.custom.desktop.profile == "dms" ||
    osConfig.custom.desktop.profile == "dms-hyprland" ||
    osConfig.custom.desktop.profile == "caelestia-hyprland" ||
    osConfig.custom.desktop.profile == "noctalia"
  )
{
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      isDefault = true;
      path = "y4loqr0b.default";
      extensions.force = true;
    };
  };

  programs.chromium.enable = true;
  programs.brave.enable = true;

  home.packages = with pkgs; [
    # Zen Browser from dedicated upstream flake (not in nixpkgs here)
    inputs.zen-browser.packages.${system}.default

    # Google Chrome with NVIDIA/Wayland flickering fix
    # Note: Catppuccin browser module does not support google-chrome upstream.
    (google-chrome.override {
      commandLineArgs = [
        "--ozone-platform-hint=auto"
        "--ozone-platform=wayland"
        "--enable-features=WaylandWindowDecorations"
        "--disable-gpu-compositing"
      ];
    })

    # Business communication
    teams-for-linux

    # Visual diff/merge tool
    meld
  ];

}
