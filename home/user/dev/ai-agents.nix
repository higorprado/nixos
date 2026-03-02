{ llm-agents-pkgs, ... }:

{
  home.packages = with llm-agents-pkgs; [
    kilocode-cli
    codex
    claude-code
    opencode
    crush
  ];

  # Claude Code global configuration
  xdg.configFile."claude/CLAUDE.md".text = ''
    # Claude Code Context

    You are running in a NixOS environment managed by Home Manager.

    ## System Information
    - OS: NixOS (unstable channel)
    - Shell: fish with starship prompt
    - Terminal: Kitty (default) with Ghostty, Foot, Alacritty, Wezterm available
    - Editor: Neovim (default) with VS Code available

    ## Development Tools
    - devenv for project environments
    - direnv for automatic environment loading
    - git with GitHub CLI (gh)

    ## Project Structure
    - System config: `~/nixos/`
  '';

  # Crush configuration
  xdg.configFile."crush/crush.json".text = builtins.toJSON {
    api = {
      anthropic = {
        apiKey = "$ANTHROPIC_API_KEY";
      };
      openai = {
        apiKey = "$OPENAI_API_KEY";
      };
    };
    ui = {
      theme = "catppuccin_mocha";
    };
  };

  # MCP configuration for NixOS context
  xdg.configFile."claude/mcp_servers.json".text = builtins.toJSON {
    mcpServers = {
      nixos = {
        command = "uvx";
        args = [
          "mcp-nixos"
          "--option"
          "nixpkgs"
          "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz"
        ];
      };
    };
  };

  # Fish abbreviations for AI agents
  programs.fish.shellAbbrs = {
    claude = "claude";
    cc = "claude";
    opencode = "opencode";
    oc = "opencode";
    crush = "crush";
  };
}
