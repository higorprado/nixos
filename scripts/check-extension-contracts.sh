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

is_allowed_host_role_assignment() {
  local file="$1"
  [[ "$file" == "modules/options/core-options.nix" ]] || [[ "$file" == hosts/*/default.nix ]]
}

is_allowed_desktop_profile_assignment() {
  local file="$1"
  [[ "$file" == "modules/options/desktop-options.nix" ]] || [[ "$file" == hosts/*/default.nix ]]
}

check_assignment_scope() {
  local label="$1"
  local pattern="$2"
  local checker="$3"
  local line file
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    file="${line%%:*}"
    if ! "$checker" "$file"; then
      report_fail "${label} assignment outside contract: ${line}"
    fi
  done < <(rg -n --glob '*.nix' "$pattern" hosts modules home flake.nix || true)
}

check_set_sync() {
  local left_label="$1"
  local left_file="$2"
  local right_label="$3"
  local right_file="$4"

  local missing extra
  missing="$(set_missing_entries "$left_file" "$right_file")"
  extra="$(set_extra_entries "$left_file" "$right_file")"

  if [[ -n "$missing" ]]; then
    report_fail "${right_label} missing entries present in ${left_label}: $(tr '\n' ' ' <<<"$missing")"
  fi
  if [[ -n "$extra" ]]; then
    report_fail "${right_label} has entries not declared in ${left_label}: $(tr '\n' ' ' <<<"$extra")"
  fi
}

require_pattern_in_file() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  if ! rg -q "$pattern" "$file"; then
    report_fail "$message"
  fi
}

check_assignment_scope "custom.host.role" '^[[:space:]]*custom\.host\.role[[:space:]]*=' is_allowed_host_role_assignment
check_assignment_scope "custom.desktop.profile" '^[[:space:]]*custom\.desktop\.profile[[:space:]]*=' is_allowed_desktop_profile_assignment

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

require_pattern_in_file 'packRegistry = import ./pack-registry.nix;' home/user/desktop/default.nix "home/user/desktop/default.nix must import pack-registry.nix"
require_pattern_in_file 'profilePackSets[[:space:]]*=' home/user/desktop/default.nix "home/user/desktop/default.nix must derive profilePackSets from profile metadata"
require_pattern_in_file '\+\+ selectedPackModules;' home/user/desktop/default.nix "home/user/desktop/default.nix must compose imports with selectedPackModules"

mapfile -t pack_names < <(extc_pack_names)
mapfile -t pack_set_names < <(extc_pack_set_names)

tmpdir="$(mktemp_dir_scoped extension-contracts)"
trap 'rm -rf "$tmpdir"' EXIT

mkset "$tmpdir/pack_names" "${pack_names[@]}"
mkset "$tmpdir/pack_set_names" "${pack_set_names[@]}"

for pack in "${pack_names[@]}"; do
  module_path="$(
    extc_pack_module_path "${pack}" 2>/dev/null || true
  )"
  if [[ -z "$module_path" ]]; then
    report_fail "pack '${pack}' missing module path in pack-registry.nix"
    continue
  fi
  if [[ ! -f "$module_path" ]]; then
    report_fail "pack '${pack}' references missing module: ${module_path}"
  fi
done

for set_name in "${pack_set_names[@]}"; do
  mapfile -t set_entries < <(
    extc_pack_set_entries "${set_name}"
  )
  for pack in "${set_entries[@]}"; do
    if ! grep -Fxq "$pack" "$tmpdir/pack_names"; then
      report_fail "pack set '${set_name}' references unknown pack '${pack}'"
    fi
  done
done

mapfile -t host_dirs < <(
  find hosts -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
    | sort -u
)

mapfile -t host_descriptor_entries < <(extc_host_descriptor_names)

mkset "$tmpdir/host_dirs" "${host_dirs[@]}"
mkset "$tmpdir/host_descriptors" "${host_descriptor_entries[@]}"
check_set_sync "host directories" "$tmpdir/host_dirs" "host descriptor entries" "$tmpdir/host_descriptors"

require_pattern_in_file 'hostDescriptors = import ./hosts/host-descriptors.nix;' flake.nix "flake.nix must import hosts/host-descriptors.nix"
require_pattern_in_file 'hostRegistry = lib.mapAttrs mkHostModules hostDescriptors;' flake.nix "flake.nix must derive hostRegistry from hostDescriptors via mkHostModules"
if [[ ! -x scripts/new-host-skeleton.sh ]]; then
  report_fail "scripts/new-host-skeleton.sh must exist and be executable"
fi

for host in "${host_dirs[@]}"; do
  if [[ ! -f "hosts/${host}/default.nix" ]]; then
    report_fail "host '${host}' missing hosts/${host}/default.nix"
  fi

  descriptor_role="$(
    extc_host_descriptor_role "${host}" 2>/dev/null || true
  )"
  descriptor_profile="$(
    extc_host_descriptor_desktop_profile "${host}" 2>/dev/null || true
  )"

  if [[ -z "$descriptor_role" ]]; then
    report_fail "host '${host}' missing descriptor role in hosts/host-descriptors.nix"
  elif ! rg -q "custom\\.host\\.role = \"${descriptor_role}\";" "hosts/${host}/default.nix"; then
    report_fail "host '${host}' default.nix must set custom.host.role = \"${descriptor_role}\" from descriptor"
  fi

  if [[ -z "$descriptor_profile" ]]; then
    report_fail "host '${host}' missing descriptor desktopProfile in hosts/host-descriptors.nix"
  elif ! rg -q "custom\\.desktop\\.profile = \"${descriptor_profile}\";" "hosts/${host}/default.nix"; then
    report_fail "host '${host}' default.nix must set custom.desktop.profile = \"${descriptor_profile}\" from descriptor"
  fi
done

mapfile -t module_profiles < <(
  find modules/profiles/desktop -maxdepth 1 -type f -name 'profile-*.nix' ! -name 'profile-registry.nix' ! -name 'profile-metadata.nix' -printf '%f\n' \
    | sed -E 's/^profile-(.*)\.nix$/\1/' \
    | sort -u
)

mapfile -t registry_profiles < <(
  sed -nE 's/^[[:space:]]*([a-z0-9-]+)[[:space:]]*=[[:space:]]*\.\/profile-[a-z0-9-]+\.nix;/\1/p' modules/profiles/desktop/profile-registry.nix \
    | sort -u
)

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  profile_key="${line%%=*}"
  profile_module="${line#*=}"
  profile_module="${profile_module#./profile-}"
  profile_module="${profile_module%.nix}"
  if [[ "$profile_key" != "$profile_module" ]]; then
    report_fail "profile registry key/path mismatch: ${line}"
  fi
done < <(
  sed -nE 's/^[[:space:]]*([a-z0-9-]+)[[:space:]]*=[[:space:]]*(\.\/profile-[a-z0-9-]+\.nix);/\1=\2/p' modules/profiles/desktop/profile-registry.nix
)

mapfile -t metadata_profiles < <(extc_metadata_profile_names)

require_pattern_in_file 'profileModules = import ../profiles/desktop/profile-registry.nix;' modules/options/desktop-options.nix "modules/options/desktop-options.nix must import desktop profile registry"
require_pattern_in_file 'type = lib.types.enum profileNames;' modules/options/desktop-options.nix "modules/options/desktop-options.nix must derive enum from profileNames"

mkset "$tmpdir/expected" "${registry_profiles[@]}"
mkset "$tmpdir/modules" "${module_profiles[@]}"
mkset "$tmpdir/registry" "${registry_profiles[@]}"
mkset "$tmpdir/metadata" "${metadata_profiles[@]}"

check_set_sync "profile registry" "$tmpdir/expected" "profile modules" "$tmpdir/modules"
check_set_sync "profile registry" "$tmpdir/expected" "profile metadata keys" "$tmpdir/metadata"

require_pattern_in_file 'profileMetadataRoot = import .*profile-metadata\.nix' scripts/check-profile-matrix.sh "scripts/check-profile-matrix.sh must import profile metadata root"
require_pattern_in_file 'profileMetadata = profileMetadataRoot\.profiles or profileMetadataRoot;' scripts/check-profile-matrix.sh "scripts/check-profile-matrix.sh must support schema-based profile metadata"
require_pattern_in_file 'expected = profileMetadata\..*capabilities;' scripts/check-profile-matrix.sh "scripts/check-profile-matrix.sh must derive expected capabilities from profile metadata"

required_capability_keys=(
  "desktopFiles"
  "desktopUserApps"
  "niri"
  "hyprland"
  "dms"
  "noctalia"
  "caelestiaHyprland"
)

for profile in "${registry_profiles[@]}"; do
  profile_json="$(
    extc_profile_json "${profile}"
  )"

  if [[ "$(jq -r 'type' <<<"$profile_json")" != "object" ]]; then
    report_fail "profile '${profile}' missing metadata object in modules/profiles/desktop/profile-metadata.nix"
    continue
  fi

  if ! jq -e 'has("capabilities") and has("requiredIntegrations") and has("optionalIntegrations") and has("packSets")' <<<"$profile_json" >/dev/null; then
    report_fail "profile '${profile}' metadata missing required fields"
  fi

  mapfile -t profile_pack_sets < <(jq -r '.packSets[]?' <<<"$profile_json" | sort -u)
  if [[ "${#profile_pack_sets[@]}" -eq 0 ]]; then
    report_fail "profile '${profile}' packSets must declare at least one set"
  fi
  for set_name in "${profile_pack_sets[@]}"; do
    if ! grep -Fxq "$set_name" "$tmpdir/pack_set_names"; then
      report_fail "profile '${profile}' references unknown pack set '${set_name}'"
    fi
  done

  for key in "${required_capability_keys[@]}"; do
    if ! jq -e ".capabilities | has(\"${key}\")" <<<"$profile_json" >/dev/null; then
      report_fail "profile '${profile}' capabilities missing key '${key}'"
    fi
  done
done

require_pattern_in_file 'profileMetadataRoot = import ./desktop/profile-metadata\.nix;' modules/profiles/profile-capabilities.nix "modules/profiles/profile-capabilities.nix must import profile metadata root"
require_pattern_in_file 'profileMetadata = profileMetadataRoot\.profiles or profileMetadataRoot;' modules/profiles/profile-capabilities.nix "modules/profiles/profile-capabilities.nix must support schema-based profile metadata"
require_pattern_in_file 'defaultCapabilities // selectedProfile\.capabilities' modules/profiles/profile-capabilities.nix "modules/profiles/profile-capabilities.nix must derive capabilities from selectedProfile.capabilities"

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-contracts] ok: host/profile extension contracts hold"
