{ lib, ... }:
let
  mutableCopy = import ../lib/mutable-copy.nix { inherit lib; };
in

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
  };

  # =============================================================================
  # Application Configs - Copied on first deploy (mutable, user-editable)
  # =============================================================================

  # Fcitx5 input method (mutable - user configuration)
  home.activation.provisionFcitx5 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/fcitx5/conf"
    ${mutableCopy.mkCopyOnce {
      source = ../../../config/apps/fcitx5/profile;
      target = "$HOME/.config/fcitx5/profile";
    }}
  '';
}
