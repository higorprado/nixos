{ config, lib, ... }:

{
  # =============================================================================
  # Desktop Shell Custom Configs - Copied on first deploy (mutable, user-editable)
  # These are user-customizable configs that shells/desktops may modify.
  # =============================================================================

  # Niri custom config (user overrides, loaded by main config)
  home.activation.provisionNiriCustom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/niri/custom.kdl" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/niri"
      $DRY_RUN_CMD cp ${../../../config/shells/niri-custom.kdl} "$HOME/.config/niri/custom.kdl"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/niri/custom.kdl"
    fi
  '';

  # Caelestia shell settings
  home.activation.provisionCaelestiaSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/caelestia/shell.json" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/caelestia"
      $DRY_RUN_CMD cp ${../../../config/shells/caelestia/shell.json} "$HOME/.config/caelestia/shell.json"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/caelestia/shell.json"
    fi
  '';

  # Noctalia settings
  home.activation.provisionNoctaliaSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/noctalia/settings.json" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/noctalia"
      $DRY_RUN_CMD cp ${../../../config/shells/noctalia/settings.json} "$HOME/.config/noctalia/settings.json"
      $DRY_RUN_CMD cp ${../../../config/shells/noctalia/colors.json} "$HOME/.config/noctalia/colors.json"
      $DRY_RUN_CMD cp ${../../../config/shells/noctalia/plugins.json} "$HOME/.config/noctalia/plugins.json"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/noctalia/"*.json
    fi
  '';
}
