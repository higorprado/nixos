{
  lib,
  customPkgs,
  osConfig,
  ...
}:
lib.mkIf osConfig.custom.desktop.keyrs.enable {

  # Provision ~/.config/keyrs/config.toml as a mutable copy on first deploy.
  # The file is never overwritten by subsequent rebuilds, so you can edit it
  # freely without triggering a system rebuild.
  home.activation.provisionKeyrsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/keyrs/config.toml" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/keyrs"
      $DRY_RUN_CMD cp ${../../../config/apps/keyrs/config.toml} "$HOME/.config/keyrs/config.toml"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/keyrs/config.toml"
    fi
  '';

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

  systemd.user.services.keyrs = {
    Unit = {
      Description = "keyrs keyboard remapper";
      # Only start inside a live Wayland/graphical session so that
      # WAYLAND_DISPLAY, XDG_RUNTIME_DIR, etc. are already in the environment.
      After = [ "graphical-session.target" ];
      ConditionPathExists = [ "%h/.config/keyrs/config.toml" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${customPkgs.keyrs}/bin/keyrs --config %h/.config/keyrs/config.toml";
      Restart = "on-failure";
      RestartSec = 2;
      # KEYRS_LOG controls verbosity; set to "info" while debugging.
      Environment = [ "KEYRS_LOG=warn" ];
      StandardOutput = "journal";
      StandardError = "journal";
    };
    # Tied to the graphical session: starts with it, stops when it ends.
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
