{
  config,
  lib,
  ...
}:

{
  # Terminal emulators are enabled via their respective Home Manager modules
  # in foot.nix, kitty.nix, alacritty.nix, wezterm.nix, and ghostty.nix.
  # Switch the default at the module level with: custom.terminal.default = "ghostty";

  options.custom.terminal.default = lib.mkOption {
    type = lib.types.enum [
      "foot"
      "ghostty"
      "kitty"
      "alacritty"
      "wezterm"
    ];
    default = "foot";
    description = "Default terminal emulator. Sets the TERMINAL session variable.";
  };

  config = {
    home.packages = [ ];

    # Set default terminal for the system
    home.sessionVariables.TERMINAL = config.custom.terminal.default;

    # Fish shell configuration for terminal switching
    programs.fish.interactiveShellInit = lib.mkAfter ''
      # Terminal switching function
      function switch-terminal
        set terminal $argv[1]
        if test -z "$terminal"
          echo "Usage: switch-terminal <foot|ghostty|kitty|alacritty|wezterm>"
          return 1
        end

        switch $terminal
          case foot ghostty kitty alacritty wezterm
            set -gx TERMINAL $terminal
            echo "Default terminal set to: $terminal"
            echo "Run '$terminal' to launch"
          case '*'
            echo "Unknown terminal: $terminal"
            echo "Available: foot, ghostty, kitty, alacritty, wezterm"
            return 1
        end
      end

      # AI agent launcher function
      function ai
        set agent $argv[1]
        set dir (pwd)

        if test -z "$agent"
          echo "Available AI agents:"
          echo "  claude, cc  - Claude Code"
          echo "  opencode, oc - OpenCode"
          echo "  crush       - Crush AI"
          return 0
        end

        switch $agent
          case claude cc
            cd $dir && claude
          case opencode oc
            cd $dir && opencode
          case crush
            cd $dir && crush
          case '*'
            echo "Unknown agent: $agent"
            ai
        end
      end
    '';

    # Fish abbreviations for terminal switching
    programs.fish.shellAbbrs = {
      tf = "switch-terminal foot";
      tg = "switch-terminal ghostty";
      tk = "switch-terminal kitty";
      ta = "switch-terminal alacritty";
      tw = "switch-terminal wezterm";
    };
  };
}
