{ pkgs, ... }:
{
  programs.bat.enable = true;
  programs.eza = {
    enable = true;
    # Prevent upstream fish alias injection (l/la/ll/...) so we keep a
    # pure abbreviation-based workflow managed in fish.nix.
    enableFishIntegration = false;
  };

  home.packages = with pkgs; [
    # ============================================
    # CLI Utilities (truly global, used everywhere)
    # ============================================
    gh # GitHub CLI
    jq # JSON processor
    fd # Fast find alternative
    tree # Directory tree viewer
    sd # Sed alternative
    # ripgrep # Moved to core/packages.nix (global tool)
    uv # Python package/project manager

    # ============================================
    # Nix Development
    # ============================================
    nixfmt # Nix code formatter
  ];

  # Note: Docker is enabled system-wide in modules/services/docker.nix
  # User-level Docker socket access is handled via docker group membership
  # defined in modules/core/system.nix
}
