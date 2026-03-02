{ lib, ... }:
let
  mutableCopy = import ../lib/mutable-copy.nix { inherit lib; };
in

{
  # =============================================================================
  # Desktop Shell Custom Configs - Copied on first deploy (mutable, user-editable)
  # These are user-customizable configs that shells/desktops may modify.
  # =============================================================================

  # Niri custom config (user overrides, loaded by main config)
  home.activation.provisionNiriCustom = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    mutableCopy.mkCopyOnce {
      source = ../../../config/shells/niri-custom.kdl;
      target = "$HOME/.config/niri/custom.kdl";
    }
  );

  # Caelestia shell settings
  home.activation.provisionCaelestiaSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    mutableCopy.mkCopyOnce {
      source = ../../../config/shells/caelestia/shell.json;
      target = "$HOME/.config/caelestia/shell.json";
    }
  );

  # Noctalia settings
  home.activation.provisionNoctaliaSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${mutableCopy.mkCopyOnce {
      source = ../../../config/shells/noctalia/settings.json;
      target = "$HOME/.config/noctalia/settings.json";
    }}

    ${mutableCopy.mkCopyOnce {
      source = ../../../config/shells/noctalia/colors.json;
      target = "$HOME/.config/noctalia/colors.json";
    }}

    ${mutableCopy.mkCopyOnce {
      source = ../../../config/shells/noctalia/plugins.json;
      target = "$HOME/.config/noctalia/plugins.json";
    }}
  '';
}
