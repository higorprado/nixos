{ pkgs, lib, ... }:
let
  nvimRuntimeCleanup = pkgs.writeShellScript "nvim-runtime-cleanup" ''
    set -euo pipefail

    state_dir="$HOME/.local/state/nvim"
    cache_dir="$HOME/.cache/nvim"
    swap_dir="$state_dir/swap"
    max_log_size=$((10 * 1024 * 1024)) # 10 MiB

    mkdir -p "$state_dir" "$cache_dir" "$swap_dir"

    trim_log_if_needed() {
      local file="$1"
      [ -f "$file" ] || return 0
      local size
      size="$(${pkgs.coreutils}/bin/stat -c %s "$file" 2>/dev/null || echo 0)"
      if [ "$size" -gt "$max_log_size" ]; then
        # Keep only the most recent lines to avoid unbounded log growth.
        ${pkgs.coreutils}/bin/tail -n 5000 "$file" > "$file.tmp"
        ${pkgs.coreutils}/bin/mv "$file.tmp" "$file"
      fi
    }

    trim_log_if_needed "$state_dir/lsp.log"
    trim_log_if_needed "$cache_dir/dap.log"

    # Remove stale swap artifacts only; keep shada/session/undo files intact.
    if [ -d "$swap_dir" ]; then
      ${pkgs.findutils}/bin/find "$swap_dir" -type f \
        \( -name "*.swp" -o -name "*.swo" -o -name "*.swn" -o -name "*.tmp" \) \
        -mtime +14 -delete
    fi
  '';
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
  };

  # Keep ~/.config/nvim synchronized with the repo source on every switch.
  # This avoids drift between ~/nixos/config/apps/nvim and the live Neovim config.
  home.activation.syncNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/nvim"
    $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --delete ${../../../../config/apps/nvim}/ "$HOME/.config/nvim/"
    $DRY_RUN_CMD chmod -R u+rwX,go+rX "$HOME/.config/nvim"
  '';

  # Nix-managed editor toolchain (single source of truth, no Mason auto-installs)
  home.packages = with pkgs; [
    # Python
    pyright
    ruff
    python3Packages.debugpy

    # Lua / Nix / TOML
    lua-language-server
    stylua
    nil # Nix LSP
    nixpkgs-fmt # Nix formatter
    statix # Nix linter
    taplo

    # JS/TS/JSON/YAML/Bash language servers
    vtsls
    vscode-js-debug
    nodePackages.typescript
    nodePackages."markdownlint-cli2"
    nodePackages.vscode-langservers-extracted
    nodePackages.yaml-language-server
    nodePackages.bash-language-server

    # Rust (LSP binary only; compiler/toolchain can remain project-local)
    rust-analyzer
    lldb

    # Go language support
    go
    gopls
    gotools
    gofumpt

    # Common format/lint helpers
    marksman
    shfmt
    shellcheck
  ];

  # Safe Neovim runtime hygiene (logs + stale swaps only).
  systemd.user.services.nvim-runtime-cleanup = {
    Unit.Description = "Neovim runtime cleanup (safe allowlist)";
    Service = {
      Type = "oneshot";
      ExecStart = nvimRuntimeCleanup;
    };
  };

  systemd.user.timers.nvim-runtime-cleanup = {
    Unit.Description = "Weekly Neovim runtime cleanup";
    Timer = {
      OnBootSec = "20min";
      OnCalendar = "weekly";
      Persistent = true;
      Unit = "nvim-runtime-cleanup.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
