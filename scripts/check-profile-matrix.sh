#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/nix_eval.sh"
enter_repo_root "${BASH_SOURCE[0]}"
repo_root="$(pwd)"

report_fail() {
  log_fail "profile-matrix" "$1"
}

require_cmds "profile-matrix" "jq" "nix"

mapfile -t profiles < <(
  nix_eval_json_expr "builtins.attrNames (import \"${repo_root}/modules/profiles/desktop/profile-metadata.nix\")" \
    | jq -r '.[]'
)

check_profile() {
  local profile="$1"

  local json
  json="$(
    nix_eval_json_expr "
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
        profileMetadata = import \"${repo_root}/modules/profiles/desktop/profile-metadata.nix\";
        expected = profileMetadata.\"${profile}\".capabilities;
        user = cfg.custom.user.name;
      in
      {
        capabilities = cfg.custom.desktop.capabilities;
        expected = expected;
        systemDrv = cfg.system.build.toplevel.drvPath;
        homeDrv = cfg.home-manager.users.\${user}.home.path.drvPath;
      }
    "
  )"

  mapfile -t expected_keys < <(jq -r '.expected | keys[]' <<<"$json")
  for key in "${expected_keys[@]}"; do
    local expected actual
    expected="$(jq -r ".expected.${key}" <<<"$json")"
    actual="$(jq -r ".capabilities.${key}" <<<"$json")"
    if [[ "$actual" != "$expected" ]]; then
      report_fail "${profile} capability '${key}' expected '${expected}', got '${actual}'"
      return 1
    fi
  done

  local missing_keys extra_keys
  missing_keys="$(jq -r '[.expected | keys[]] - [.capabilities | keys[]] | join(",")' <<<"$json")"
  extra_keys="$(jq -r '[.capabilities | keys[]] - [.expected | keys[]] | join(",")' <<<"$json")"
  if [[ -n "$missing_keys" ]]; then
    report_fail "${profile} missing capability keys: ${missing_keys}"
    return 1
  fi
  if [[ -n "$extra_keys" ]]; then
    report_fail "${profile} unexpected capability keys: ${extra_keys}"
    return 1
  fi

  local system_drv home_drv
  system_drv="$(jq -r '.systemDrv' <<<"$json")"
  home_drv="$(jq -r '.homeDrv' <<<"$json")"

  if [[ "$system_drv" != /nix/store/* ]]; then
    report_fail "invalid system drv path for ${profile}: ${system_drv}"
    return 1
  fi
  if [[ "$home_drv" != /nix/store/* ]]; then
    report_fail "invalid home drv path for ${profile}: ${home_drv}"
    return 1
  fi

  echo "[profile-matrix] ok: $profile (systemDrv/homeDrv/capabilities)"
}

for profile in "${profiles[@]}"; do
  check_profile "$profile"
done

echo "[profile-matrix] all profiles evaluated successfully"
