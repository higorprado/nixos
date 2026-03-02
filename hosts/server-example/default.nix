{
  lib,
  ...
}:
{
  imports = [
    ../../modules
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  networking.hostName = "server-example";

  # Explicit server role: desktop stack must remain disabled.
  custom.host.role = "server";
  custom.user.name = "ops";

  # Keep desktop profile defined for option compatibility; capabilities
  # collapse to false when host.role = "server".
  custom.desktop.profile = "dms";

  # Eval/build-focused skeleton: avoid hardware/boot assertions.
  boot.isContainer = true;
  networking.useHostResolvConf = lib.mkForce false;
  nixpkgs.config.allowUnfree = true;
}
