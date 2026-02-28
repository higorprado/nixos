{ pkgs, config, ... }: {
  # Install devenv CLI and cachix for binary cache
  home.packages = with pkgs; [ devenv cachix ];

  # Configure direnv with nix-direnv for fast, cached environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  # Global direnvrc for devenv integration
  # This enables "use devenv" in .envrc files
  xdg.configFile."direnv/direnvrc".text = pkgs.lib.mkForce (builtins.readFile
    (pkgs.runCommand "devenv-direnvrc" { buildInputs = [ pkgs.devenv ]; } ''
      devenv direnvrc > $out
    ''));
}
