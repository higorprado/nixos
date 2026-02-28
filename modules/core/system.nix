# Core system settings
# Timezone, locale, user account, state version, zram swap, Nix settings
{ config, lib, pkgs, ... }:
let
  userName = config.custom.user.name;
in
{
  assertions = [
    {
      assertion = userName != "user" && userName != "" && userName != "root";
      message = ''
        custom.user.name is unresolved (${userName}).
        Refusing to create an unsafe default user. Set custom.user.name in local private overrides.
        If using nh, call with a path flake (example: nh os switch path:/home/your-user/nixos)
        instead of git-style flake refs that ignore untracked private overrides.
      '';
    }
  ];

  # Enable fish shell
  programs.fish.enable = true;

  # Timezone
  time.timeZone = "America/Sao_Paulo";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = { LC_CTYPE = "pt_BR.UTF-8"; };

  # User account
  users.users.${userName} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "docker"
      "input"
      "uinput"
      "rfkill"
      "linuwu_sense"
    ];
  };

  users.groups.linuwu_sense = { };

  # NixOS state version
  system.stateVersion = "25.11";

  # Nix package manager settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" userName ];
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://nixpkgs-python.cachix.org"
      "https://catppuccin.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    ];
  };

  # ZRAM swap (compressed RAM-based swap)
  zramSwap.enable = true;
  # CachyOS uses ~12GB ZRAM (37% of 32GB) and actively uses ~6GB.
  # Match that allocation to avoid OOM under normal workload.
  zramSwap.memoryPercent = 100;
}
