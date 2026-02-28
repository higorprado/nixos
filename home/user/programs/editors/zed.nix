{ config, lib, pkgs, inputs, ... }:

{
  home.packages = [ 
    inputs.zed-editor.packages.${pkgs.stdenv.hostPlatform.system}.zed-editor-bin
  ];

  home.activation.setupZedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ZED_DIR="$HOME/.config/zed"

    if [ ! -d "$ZED_DIR" ]; then
      $DRY_RUN_CMD mkdir -p "$ZED_DIR"
    fi

    if [ ! -f "$ZED_DIR/settings.json" ]; then
      $DRY_RUN_CMD cp ${../../../../config/apps/zed/zed-settings.json} "$ZED_DIR/settings.json"
      $DRY_RUN_CMD chmod u+rw "$ZED_DIR/settings.json"
    fi

    if [ ! -f "$ZED_DIR/keymap.json" ]; then
      $DRY_RUN_CMD cp ${../../../../config/apps/zed/zed-keymap.json} "$ZED_DIR/keymap.json"
      $DRY_RUN_CMD chmod u+rw "$ZED_DIR/keymap.json"
    fi
  '';
}