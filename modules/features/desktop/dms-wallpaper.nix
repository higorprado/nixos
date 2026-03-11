{ den, ... }:
{
  den.aspects.dms-wallpaper = den.lib.parametric {
    includes = [
      (den.lib.take.exactly (
        { host, ... }:
        {
          nixos =
            { pkgs, ... }:
            {
              environment.systemPackages = [
                (pkgs.writeShellScriptBin "awww" ''exec ${pkgs.swww}/bin/swww "$@"'')
                (pkgs.writeShellScriptBin "awww-daemon" ''exec ${pkgs.swww}/bin/swww-daemon "$@"'')
                host.customPkgs.dms-awww
              ];
            };
        }
      ))
      (
        { host, user, ... }:
        {
          homeManager =
            { lib, pkgs, ... }:
            let
              mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
              dmsPackage = host.inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;
              awww = pkgs.writeShellScriptBin "awww" ''exec ${pkgs.swww}/bin/swww "$@"'';
              runDmsAwww = pkgs.writeShellApplication {
                name = "run-dms-awww";
                runtimeInputs = [
                  awww
                  pkgs.matugen
                ];
                text = ''
                  export DMS_AWWW_BIN=${lib.escapeShellArg "${host.customPkgs.dms-awww}/bin/dms-awww"}
                  ${builtins.readFile ../../../config/apps/dms/run-dms-awww.sh}
                '';
              };
              provisionDmsAwwwConfig = ''
                $DRY_RUN_CMD mkdir -p "$HOME/.config/dms-awww"
                $DRY_RUN_CMD cat > "$HOME/.config/dms-awww/config.toml" << EOF2
[general]
log_level = "info"
auto_detect_monitors = true
debounce_ms = 100

[awww]
enabled = true

[matugen]
enabled = true
default_scheme = "scheme-tonal-spot"
# Derived from the tracked DMS package used by Home Manager
shell_dir = "${dmsPackage}/share/quickshell/dms"
EOF2
                $DRY_RUN_CMD chmod 644 "$HOME/.config/dms-awww/config.toml"
              '';
            in
            {
              home.activation.provisionDmsAwwwConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] provisionDmsAwwwConfig;
              home.activation.provisionDmsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
                mutableCopy.mkCopyOnce {
                  source = ../../../config/apps/dms/settings.json;
                  target = "$HOME/.config/DankMaterialShell/settings.json";
                }
              );
              systemd.user.services = {
                awww-daemon = {
                  Unit = {
                    Description = "swww wallpaper daemon (awww-daemon)";
                    After = [ "graphical-session.target" ];
                    PartOf = [ "graphical-session.target" ];
                  };
                  Service = {
                    Type = "simple";
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
                    After = [
                      "graphical-session.target"
                      "awww-daemon.service"
                    ];
                    PartOf = [ "graphical-session.target" ];
                    Requires = [ "awww-daemon.service" ];
                    ConditionPathExists = [ "%h/.config/dms-awww/config.toml" ];
                  };
                  Service = {
                    Type = "simple";
                    ExecStart = "${runDmsAwww}/bin/run-dms-awww";
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
                    ReadWritePaths = [
                      "/tmp"
                      "%h/.config/DankMaterialShell"
                      "%h/.cache/DankMaterialShell"
                      "/run/user/%U"
                    ];
                    StandardOutput = "journal";
                    StandardError = "journal";
                  };
                  Install.WantedBy = [ "graphical-session.target" ];
                };
              };
            };
        }
      )
    ];
  };
}
