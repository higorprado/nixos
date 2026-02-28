# System monitoring tools
# fastfetch, btop, bottom, smartmontools, tmux
{ pkgs, ... }:
{
  programs.btop.enable = true;
  programs.bottom.enable = true;

  home.packages = with pkgs; [
    # System info
    fastfetch

    # Process monitors

    # SSD health
    smartmontools

    # Terminal multiplexer
    tmux
  ];
}
