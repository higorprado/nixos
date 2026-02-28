{ inputs, config, lib, pkgs, customPkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./hardware.nix
    ./packages.nix
    ./performance.nix
    ../../modules
    ../../home/user
  ] ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  # Hostname
  networking.hostName = "predator";

  # Desktop profile
  custom.desktop.profile = "dms";

  # Feature flags
  custom.desktop.keyrs.enable = true;

  # khal 0.13.0 docs fail to build with sphinx-9.x (sphinxcontrib-newsfeed bug).
  nixpkgs.overlays = [
    (_: prev: {
      khal = prev.khal.overrideAttrs (old: {
        nativeBuildInputs = builtins.filter
          (p: !(prev.lib.hasInfix "sphinx" (p.name or "")))
          old.nativeBuildInputs;
        outputs = [ "out" "dist" ];
      });
    })
  ];

  # Bootloader configuration (GRUB with EFI)
  boot.loader = {
    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };

    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
  };

}
