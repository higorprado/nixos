{ pkgs, ... }:

{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--no-cmd" ];
  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      # Docker
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
      dex = "docker exec -it";

      # Python
      pym = "python -m";

      # Git
      gs = "git status";
      gd = "git diff";
      gds = "git diff --staged";
      gp = "git push";
      gl = "git pull";

      # Navigation
      l = "eza -alh";
      ll = "eza -l";
      lla = "eza -la";
      ls = "eza";
      la = "eza -a";
      lt = "eza --tree";
      z = "__zoxide_z";
      zi = "__zoxide_zi";

      # Utilities
      cat = "bat";

      # Existing abbreviations
      venv = "python -m venv .venv && source .venv/bin/activate.fish";
      pipi = "pip install";
      pipp = "pip install --pre";
      ga = "git add";
      gc = "git commit";
      gb = "git branch";

      # Emacs
      emacs = "emacsclient -c -a ''";
      e = "emacsclient -c -a ''";

      # Nix Commands
      nu = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock";
      nus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos --out-link \"$HOME/nixos/result\"";
      nut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos --out-link \"$HOME/nixos/result\"";
    };

    interactiveShellInit = ''
      # Suppress default greeting
      function fish_greeting; end

      # Auto-allow direnv in ~/code directory
      function __direnv_auto_allow --on-variable PWD
        if string match -q "$HOME/code/*" $PWD; or string match -q "$HOME/Code/*" $PWD
          and test -f .envrc
          and not direnv status | grep -q "Allowed"
          direnv allow >/dev/null 2>&1
        end
      end


      # Keep Yazi directory-jump convenience from current host.
      function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
          builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      end

      set --export BUN_INSTALL "$HOME/.bun"
      fish_add_path "$BUN_INSTALL/bin"
      fish_add_path "$HOME/.opencode/bin"
      fish_add_path "$HOME/.config/emacs/bin"
    '';
  };
}
