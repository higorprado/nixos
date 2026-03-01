{ ... }:
{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = {}
      if wezterm.config_builder then
        config = wezterm.config_builder()
      end

      dofile(catppuccin_plugin).apply_to_config(config, catppuccin_config)

      config.font = wezterm.font("JetBrains Mono Nerd Font Mono")
      config.font_size = 12
      config.color_scheme_dirs = { "/usr/share/wezterm/colors" }

      -- Disable audible bell
      config.audible_bell = "Disabled"

      -- Scrollback
      config.scrollback_lines = 10000

      return config
    '';
  };
}
