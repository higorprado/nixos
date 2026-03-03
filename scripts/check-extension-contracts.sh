#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/set_ops.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/set_ops.sh"
# shellcheck source=lib/nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/nix_eval.sh"
# shellcheck source=lib/extension_contracts_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/extension_contracts_eval.sh"
# shellcheck source=lib/extension_contracts_checks.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/extension_contracts_checks.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

usage() {
  cat <<'EOF'
Usage:
  scripts/check-extension-contracts.sh

Description:
  Validates host/profile/pack extension contracts and schema invariants.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_fail "extension-contracts" "unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

report_fail() {
  log_fail "extension-contracts" "$1"
  fail=1
}

require_cmds "extension-contracts" "awk" "find" "jq" "nix" "rg" "sed"

extc_check_assignment_scope "custom.host.role" '^[[:space:]]*custom\.host\.role[[:space:]]*=' extc_is_allowed_host_role_assignment report_fail
extc_check_assignment_scope "custom.desktop.profile" '^[[:space:]]*custom\.desktop\.profile[[:space:]]*=' extc_is_allowed_desktop_profile_assignment report_fail

profile_metadata_root_json="$(extc_profile_metadata_root_json)"
if ! jq -e 'has("schemaVersion") and has("profiles") and (.profiles | type == "object")' <<<"$profile_metadata_root_json" >/dev/null; then
  report_fail "profile-metadata.nix must expose schemaVersion and profiles attrset"
fi
if [[ "$(jq -r '.schemaVersion // ""' <<<"$profile_metadata_root_json")" != "1" ]]; then
  report_fail "profile-metadata.nix schemaVersion must be 1"
fi

pack_registry_root_json="$(extc_pack_registry_root_json)"
if ! jq -e 'has("schemaVersion") and has("packs") and has("packSets") and (.packs | type == "object") and (.packSets | type == "object")' <<<"$pack_registry_root_json" >/dev/null; then
  report_fail "pack-registry.nix must expose schemaVersion, packs, and packSets attrsets"
fi
if [[ "$(jq -r '.schemaVersion // ""' <<<"$pack_registry_root_json")" != "1" ]]; then
  report_fail "pack-registry.nix schemaVersion must be 1"
fi

extc_require_pattern_in_file 'packRegistry = import ./pack-registry.nix;' home/user/desktop/default.nix "home/user/desktop/default.nix must import pack-registry.nix" report_fail
extc_require_pattern_in_file 'profilePackSets[[:space:]]*=' home/user/desktop/default.nix "home/user/desktop/default.nix must derive profilePackSets from profile metadata" report_fail
extc_require_pattern_in_file '\+\+ selectedPackModules;' home/user/desktop/default.nix "home/user/desktop/default.nix must compose imports with selectedPackModules" report_fail

mapfile -t pack_names < <(extc_pack_names)
mapfile -t pack_set_names < <(extc_pack_set_names)

tmpdir="$(mktemp_dir_scoped extension-contracts)"
trap 'rm -rf "$tmpdir"' EXIT

mkset "$tmpdir/pack_names" "${pack_names[@]}"
mkset "$tmpdir/pack_set_names" "${pack_set_names[@]}"

extc_check_pack_modules_exist report_fail pack_names
extc_check_pack_set_entries_exist report_fail pack_set_names "$tmpdir/pack_names"

mapfile -t host_dirs < <(
  find hosts -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
    | sort -u
)

mapfile -t host_descriptor_entries < <(extc_host_descriptor_names)

mkset "$tmpdir/host_dirs" "${host_dirs[@]}"
mkset "$tmpdir/host_descriptors" "${host_descriptor_entries[@]}"
extc_check_set_sync "host directories" "$tmpdir/host_dirs" "host descriptor entries" "$tmpdir/host_descriptors" report_fail

extc_require_pattern_in_file 'hostDescriptors = import ./hosts/host-descriptors.nix;' flake.nix "flake.nix must import hosts/host-descriptors.nix" report_fail
extc_require_pattern_in_file 'hostRegistry = lib.mapAttrs mkHostModules hostDescriptors;' flake.nix "flake.nix must derive hostRegistry from hostDescriptors via mkHostModules" report_fail
if [[ ! -x scripts/new-host-skeleton.sh ]]; then
  report_fail "scripts/new-host-skeleton.sh must exist and be executable"
fi

extc_check_host_descriptor_matches_defaults report_fail host_dirs

mapfile -t module_profiles < <(extc_list_module_profiles)
mapfile -t registry_profiles < <(extc_list_registry_profiles)
extc_check_profile_registry_key_path_consistency report_fail "modules/profiles/desktop/profile-registry.nix"

mapfile -t metadata_profiles < <(extc_metadata_profile_names)

extc_require_pattern_in_file 'profileModules = import ../profiles/desktop/profile-registry.nix;' modules/options/desktop-options.nix "modules/options/desktop-options.nix must import desktop profile registry" report_fail
extc_require_pattern_in_file 'type = lib.types.enum profileNames;' modules/options/desktop-options.nix "modules/options/desktop-options.nix must derive enum from profileNames" report_fail

mkset "$tmpdir/expected" "${registry_profiles[@]}"
mkset "$tmpdir/modules" "${module_profiles[@]}"
mkset "$tmpdir/registry" "${registry_profiles[@]}"
mkset "$tmpdir/metadata" "${metadata_profiles[@]}"

extc_check_set_sync "profile registry" "$tmpdir/expected" "profile modules" "$tmpdir/modules" report_fail
extc_check_set_sync "profile registry" "$tmpdir/expected" "profile metadata keys" "$tmpdir/metadata" report_fail

extc_require_pattern_in_file 'profileMetadataRoot = import .*profile-metadata\.nix' scripts/check-profile-matrix.sh "scripts/check-profile-matrix.sh must import profile metadata root" report_fail
extc_require_pattern_in_file 'profileMetadata = profileMetadataRoot\.profiles or profileMetadataRoot;' scripts/check-profile-matrix.sh "scripts/check-profile-matrix.sh must support schema-based profile metadata" report_fail
extc_require_pattern_in_file 'expected = profileMetadata\..*capabilities;' scripts/check-profile-matrix.sh "scripts/check-profile-matrix.sh must derive expected capabilities from profile metadata" report_fail

extc_default_required_capability_keys >"$tmpdir/required_capability_keys"
extc_check_profiles_metadata_contracts report_fail registry_profiles "$tmpdir/required_capability_keys" "$tmpdir/pack_set_names"

extc_require_pattern_in_file 'profileMetadataRoot = import ./desktop/profile-metadata\.nix;' modules/profiles/profile-capabilities.nix "modules/profiles/profile-capabilities.nix must import profile metadata root" report_fail
extc_require_pattern_in_file 'profileMetadata = profileMetadataRoot\.profiles or profileMetadataRoot;' modules/profiles/profile-capabilities.nix "modules/profiles/profile-capabilities.nix must support schema-based profile metadata" report_fail
extc_require_pattern_in_file 'defaultCapabilities // selectedProfile\.capabilities' modules/profiles/profile-capabilities.nix "modules/profiles/profile-capabilities.nix must derive capabilities from selectedProfile.capabilities" report_fail

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-contracts] ok: host/profile extension contracts hold"
