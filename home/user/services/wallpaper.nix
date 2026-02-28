{ config, pkgs, lib, customPkgs, osConfig, ... }:

lib.mkIf (osConfig.custom.desktop.profile == "dms" || osConfig.custom.desktop.profile == "dms-hyprland") {
  # Provision ~/.config/dms-awww/config.toml as a mutable copy on first deploy.
  # Edit this file to tune log level, monitor list, matugen scheme, etc.
  # shell_dir is dynamically determined from the dms binary path
  home.activation.provisionDmsAwwwConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.config/dms-awww"
        # Determine DMS share path dynamically from the dms binary
        DMS_SHARE_PATH=$(realpath $(dirname $(readlink -f /run/current-system/sw/bin/dms))/../share/quickshell/dms)
        # Always write/update the config with current shell_dir
        $DRY_RUN_CMD cat > "$HOME/.config/dms-awww/config.toml" << EOF
    [general]
    log_level = "info"
    auto_detect_monitors = true
    debounce_ms = 100

    [awww]
    enabled = true

    [matugen]
    enabled = true
    default_scheme = "scheme-tonal-spot"
    # Dynamically determined from dms binary location (updated on rebuild)
    shell_dir = "$DMS_SHARE_PATH"
    EOF
        $DRY_RUN_CMD chmod 644 "$HOME/.config/dms-awww/config.toml"
  '';

  # Provision ~/.config/DankMaterialShell/settings.json as a mutable file.
  # DMS reads AND writes to this file (wallpaper, theme changes via the UI).
  # A symlink to the nix store would be read-only and prevent saving changes.
  home.activation.provisionDmsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/DankMaterialShell/settings.json" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/DankMaterialShell"
      $DRY_RUN_CMD cp ${../../../config/apps/dms/settings.json} "$HOME/.config/DankMaterialShell/settings.json"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/DankMaterialShell/settings.json"
    fi
  '';

  systemd.user.services = {
    # swww wallpaper daemon — provides the "awww-daemon" binary used by dms-awww.
    awww-daemon = {
      Unit = {
        Description = "swww wallpaper daemon (awww-daemon)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        # Use the real swww-daemon binary directly for reliability.
        ExecStart = "${pkgs.swww}/bin/swww-daemon";
        Environment = [
          "HOME=%h"
          "XDG_RUNTIME_DIR=/run/user/%U"
        ];
        Restart = "on-failure";
        RestartSec = 2;
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    dms-awww = {
      Unit = {
        Description = "DMS-AWWW: wallpaper + matugen integration for DMS";
        Documentation = [ "https://github.com/higorprado/dms-awww-integration" ];
        After = [ "graphical-session.target" "awww-daemon.service" ];
        PartOf = [ "graphical-session.target" ];
        Requires = [ "awww-daemon.service" ];
        ConditionPathExists = [ "%h/.config/dms-awww/config.toml" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${customPkgs.dms-awww}/bin/dms-awww";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
          "HOME=%h"
          "XDG_RUNTIME_DIR=/run/user/%U"
        ];
        EnvironmentFile = "-%h/.config/dms-awww/environment";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        # ~/.cache/DankMaterialShell: dms-awww writes cached wallpaper state.
        # /run/user/%U: D-Bus socket, Wayland socket.
        ReadWritePaths = [
          "/tmp"
          "%h/.cache/DankMaterialShell"
          "/run/user/%U"
        ];
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
