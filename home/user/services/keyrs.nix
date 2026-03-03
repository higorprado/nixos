{
  lib,
  osConfig,
  ...
}:
let
  mutableCopy = import ../lib/mutable-copy.nix { inherit lib; };
in
lib.mkIf osConfig.custom.desktop.keyrs.enable {

  # Provision ~/.config/keyrs/config.toml as a mutable copy on first deploy.
  # The file is never overwritten by subsequent rebuilds, so you can edit it
  # freely without triggering a system rebuild.
  home.activation.provisionKeyrsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    mutableCopy.mkCopyOnce {
      source = ../../../config/apps/keyrs/config.toml;
      target = "$HOME/.config/keyrs/config.toml";
    }
  );

  # Remove old manually-installed keyrs binaries (now managed via Nix package)
  home.activation.cleanupOldKeyrsBinaries = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for bin in keyrs keyrs-service keyrs-tui; do
      if [ -f "$HOME/.local/bin/$bin" ]; then
        $DRY_RUN_CMD rm -f "$HOME/.local/bin/$bin"
      fi
    done
    # Remove empty bin directory if it exists
    $DRY_RUN_CMD rmdir "$HOME/.local/bin" 2>/dev/null || true
  '';
}
