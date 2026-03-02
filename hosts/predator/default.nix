{
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./hardware.nix
    ./packages.nix
    ./performance.nix
    ../../modules
    ../../home/user
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

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
        nativeBuildInputs = builtins.filter (
          p: !(prev.lib.hasInfix "sphinx" (p.name or ""))
        ) old.nativeBuildInputs;
        outputs = [
          "out"
          "dist"
        ];
      });
    })
    (_: prev: {
      # Upstream dsearch currently installs its user unit with executable bits.
      # systemd warns for executable unit files under /etc/systemd/user.
      dsearch = prev.dsearch.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          if [ -f "$out/lib/systemd/user/dsearch.service" ]; then
            chmod 0644 "$out/lib/systemd/user/dsearch.service"
          fi
          if [ -f "$out/share/systemd/user/dsearch.service" ]; then
            chmod 0644 "$out/share/systemd/user/dsearch.service"
          fi
        '';
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
