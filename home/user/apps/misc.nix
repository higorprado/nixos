{ lib, ... }:

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
    if [ ! -f "$HOME/.config/fcitx5/profile" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/fcitx5/conf"
      $DRY_RUN_CMD cp ${../../../config/apps/fcitx5/profile} "$HOME/.config/fcitx5/profile"
    fi
  '';
}
