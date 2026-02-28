# Wayland-specific tools for desktop environment
# wlr-randr, waybar, swww, wl-clipboard, libnotify
{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    # Output management for wlroots-based compositors
    wlr-randr
    # Status bar for Wayland
    waybar
    # Wallpaper utility for Wayland
    swww
    # Clipboard management for Wayland
    wl-clipboard
    # Notification library (desktop integration)
    libnotify
  ];
}
