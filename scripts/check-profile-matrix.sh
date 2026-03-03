#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
repo_root="$(repo_root_from_script "${BASH_SOURCE[0]}")"
cd "$repo_root"

profiles=(
  "dms"
  "niri-only"
  "noctalia"
  "dms-hyprland"
  "caelestia-hyprland"
)

check_profile() {
  local profile="$1"

  local json
  json="$(
    nix eval --json --impure --expr "
      let
        flake = builtins.getFlake \"path:${repo_root}\";
        base = flake.nixosConfigurations.predator;
        lib = flake.inputs.nixpkgs.lib;
        cfg = (base.extendModules {
          modules = [
            {
              custom.host.role = lib.mkForce \"desktop\";
              custom.desktop.profile = lib.mkForce \"${profile}\";
            }
          ];
        }).config;
        user = cfg.custom.user.name;
      in
      {
        capabilities = cfg.custom.desktop.capabilities;
        systemDrv = cfg.system.build.toplevel.drvPath;
        homeDrv = cfg.home-manager.users.\${user}.home.path.drvPath;
      }
    "
  )"

  local cap_niri cap_hyprland cap_dms cap_noctalia cap_caelestia
  cap_niri="$(jq -r '.capabilities.niri' <<<"$json")"
  cap_hyprland="$(jq -r '.capabilities.hyprland' <<<"$json")"
  cap_dms="$(jq -r '.capabilities.dms' <<<"$json")"
  cap_noctalia="$(jq -r '.capabilities.noctalia' <<<"$json")"
  cap_caelestia="$(jq -r '.capabilities.caelestiaHyprland' <<<"$json")"

  case "$profile" in
    dms)
      [ "$cap_niri" = "true" ] || return 1
      [ "$cap_hyprland" = "false" ] || return 1
      [ "$cap_dms" = "true" ] || return 1
      ;;
    niri-only)
      [ "$cap_niri" = "true" ] || return 1
      [ "$cap_hyprland" = "false" ] || return 1
      [ "$cap_dms" = "false" ] || return 1
      ;;
    noctalia)
      [ "$cap_niri" = "true" ] || return 1
      [ "$cap_hyprland" = "false" ] || return 1
      [ "$cap_dms" = "false" ] || return 1
      [ "$cap_noctalia" = "true" ] || return 1
      ;;
    dms-hyprland)
      [ "$cap_niri" = "false" ] || return 1
      [ "$cap_hyprland" = "true" ] || return 1
      [ "$cap_dms" = "true" ] || return 1
      ;;
    caelestia-hyprland)
      [ "$cap_niri" = "false" ] || return 1
      [ "$cap_hyprland" = "true" ] || return 1
      [ "$cap_dms" = "false" ] || return 1
      [ "$cap_caelestia" = "true" ] || return 1
      ;;
    *)
      echo "[profile-matrix] unknown profile '$profile'" >&2
      return 1
      ;;
  esac

  local system_drv home_drv
  system_drv="$(jq -r '.systemDrv' <<<"$json")"
  home_drv="$(jq -r '.homeDrv' <<<"$json")"

  if [[ "$system_drv" != /nix/store/* ]]; then
    echo "[profile-matrix] fail: invalid system drv path for $profile: $system_drv" >&2
    return 1
  fi
  if [[ "$home_drv" != /nix/store/* ]]; then
    echo "[profile-matrix] fail: invalid home drv path for $profile: $home_drv" >&2
    return 1
  fi

  echo "[profile-matrix] ok: $profile (systemDrv/homeDrv/capabilities)"
}

for profile in "${profiles[@]}"; do
  check_profile "$profile"
done

echo "[profile-matrix] all profiles evaluated successfully"
