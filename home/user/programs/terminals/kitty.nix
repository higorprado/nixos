{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Mono Nerd Font Mono";
      size = 12;
    };
    settings = {
      scrollback_lines = 10000;
      enable_audio_bell = false;
      background_opacity = "1.0";
      cursor_blink_interval = 0;
      tab_bar_style = "powerline";
      window_padding_width = 8; # Moved here
    };
  };
}
