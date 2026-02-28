# TUI (Terminal User Interface) development tools
# yazi, zellij, lazydocker, lazygit
{ pkgs, ... }:
{
  programs.lazygit.enable = true;
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";
  };
  programs.zellij.enable = true;

  home.packages = with pkgs; [
    # TUI for Docker/container management
    lazydocker
  ];
}
