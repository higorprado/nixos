{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";

    # Keep tmux managed by Home Manager while loading the previous
    # CachyOS config verbatim.
    extraConfig = builtins.readFile ../../../../config/tmux/tmux.conf;
  };

  # Keep the historical parent path managed as one symlink to avoid migration
  # failures from old read-only symlinked trees.
  xdg.configFile."tmux/plugins/tmux-plugins".source = pkgs.runCommandLocal "tmux-plugins-dir" {} ''
    mkdir -p "$out"
    ln -s ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu "$out/tmux-cpu"
  '';
}
