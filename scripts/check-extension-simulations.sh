#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

report_fail() {
  log_fail "extension-simulations" "$1"
  fail=1
}

host_json="$(
  nix eval --json --impure --expr "
    let
      flake = builtins.getFlake \"path:${PWD}\";
      cfg = (flake.nixosConfigurations.server-example.extendModules {
        modules = [
          ({ lib, ... }: {
            networking.hostName = lib.mkForce \"synthetic-ext-host\";
          })
          {
            # Keep role explicit to ensure server semantics remain enforced.
            custom.host.role = \"server\";
          }
        ];
      }).config;
    in
    {
      role = cfg.custom.host.role;
      capabilities = cfg.custom.desktop.capabilities;
      systemDrv = cfg.system.build.toplevel.drvPath;
    }
  "
)"

if [[ "$(jq -r '.role' <<<"$host_json")" != "server" ]]; then
  report_fail "synthetic host simulation must keep role=server"
fi

for key in niri hyprland dms noctalia caelestiaHyprland desktopFiles desktopUserApps; do
  if [[ "$(jq -r ".capabilities.${key}" <<<"$host_json")" != "false" ]]; then
    report_fail "synthetic host simulation expected capability ${key}=false"
  fi
done

if [[ "$(jq -r '.systemDrv' <<<"$host_json")" != /nix/store/* ]]; then
  report_fail "synthetic host simulation produced invalid system drv path"
fi

profile_json="$(
  nix eval --json --impure --expr "
    let
      registry = import ${PWD}/modules/profiles/desktop/profile-registry.nix;
      metadataRoot = import ${PWD}/modules/profiles/desktop/profile-metadata.nix;
      metadata = metadataRoot.profiles or metadataRoot;
      packRegistry = import ${PWD}/home/user/desktop/pack-registry.nix;
      synthetic = \"synthetic-profile\";

      syntheticRegistry = registry // { \${synthetic} = registry.dms; };
      syntheticMetadata = metadata // { \${synthetic} = metadata.dms; };

      packSets = syntheticMetadata.\${synthetic}.packSets;
      packNames = builtins.concatLists (map (setName: packRegistry.packSets.\${setName} or [ ]) packSets);
      missingPacks = builtins.filter (packName: !(builtins.hasAttr packName packRegistry.packs)) packNames;
    in
    {
      hasSyntheticRegistry = builtins.hasAttr synthetic syntheticRegistry;
      hasSyntheticMetadata = builtins.hasAttr synthetic syntheticMetadata;
      registryCount = builtins.length (builtins.attrNames syntheticRegistry);
      metadataCount = builtins.length (builtins.attrNames syntheticMetadata);
      packSets = packSets;
      missingPacks = missingPacks;
    }
  "
)"

if [[ "$(jq -r '.hasSyntheticRegistry' <<<"$profile_json")" != "true" ]]; then
  report_fail "synthetic profile must be insertable in profile registry"
fi
if [[ "$(jq -r '.hasSyntheticMetadata' <<<"$profile_json")" != "true" ]]; then
  report_fail "synthetic profile must be insertable in profile metadata"
fi

if [[ "$(jq -r '.registryCount' <<<"$profile_json")" != "$(jq -r '.metadataCount' <<<"$profile_json")" ]]; then
  report_fail "synthetic registry/metadata counts must stay aligned"
fi

if [[ "$(jq -r '.packSets | length' <<<"$profile_json")" -lt 1 ]]; then
  report_fail "synthetic profile packSets must not be empty"
fi

if [[ "$(jq -r '.missingPacks | length' <<<"$profile_json")" != "0" ]]; then
  report_fail "synthetic profile packSets resolved missing pack references"
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-simulations] ok: synthetic host/profile extension checks passed"
