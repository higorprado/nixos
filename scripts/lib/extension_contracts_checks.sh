#!/usr/bin/env bash

# shellcheck source=set_ops.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/set_ops.sh"

extc_is_allowed_host_role_assignment() {
  local file="$1"
  [[ "$file" == "modules/options/core-options.nix" ]] || [[ "$file" == hosts/*/default.nix ]]
}

extc_is_allowed_desktop_profile_assignment() {
  local file="$1"
  [[ "$file" == "modules/options/desktop-options.nix" ]] || [[ "$file" == hosts/*/default.nix ]]
}

extc_check_assignment_scope() {
  local label="$1"
  local pattern="$2"
  local checker="$3"
  local fail_fn="$4"
  local line file

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    file="${line%%:*}"
    if ! "$checker" "$file"; then
      "$fail_fn" "${label} assignment outside contract: ${line}"
    fi
  done < <(rg -n --glob '*.nix' "$pattern" hosts modules home flake.nix || true)
}

extc_check_set_sync() {
  local left_label="$1"
  local left_file="$2"
  local right_label="$3"
  local right_file="$4"
  local fail_fn="$5"

  local missing extra
  missing="$(set_missing_entries "$left_file" "$right_file")"
  extra="$(set_extra_entries "$left_file" "$right_file")"

  if [[ -n "$missing" ]]; then
    "$fail_fn" "${right_label} missing entries present in ${left_label}: $(tr '\n' ' ' <<<"$missing")"
  fi
  if [[ -n "$extra" ]]; then
    "$fail_fn" "${right_label} has entries not declared in ${left_label}: $(tr '\n' ' ' <<<"$extra")"
  fi
}

extc_require_pattern_in_file() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  local fail_fn="$4"

  if ! rg -q "$pattern" "$file"; then
    "$fail_fn" "$message"
  fi
}

extc_check_pack_modules_exist() {
  local fail_fn="$1"
  local -n pack_names_ref="$2"
  local pack module_path

  for pack in "${pack_names_ref[@]}"; do
    module_path="$(extc_pack_module_path "${pack}" 2>/dev/null || true)"
    if [[ -z "$module_path" ]]; then
      "$fail_fn" "pack '${pack}' missing module path in pack-registry.nix"
      continue
    fi
    if [[ ! -f "$module_path" ]]; then
      "$fail_fn" "pack '${pack}' references missing module: ${module_path}"
    fi
  done
}

extc_check_pack_set_entries_exist() {
  local fail_fn="$1"
  local -n pack_set_names_ref="$2"
  local pack_names_file="$3"
  local set_name pack
  local -a set_entries=()

  for set_name in "${pack_set_names_ref[@]}"; do
    mapfile -t set_entries < <(extc_pack_set_entries "${set_name}")
    for pack in "${set_entries[@]}"; do
      if ! grep -Fxq "$pack" "$pack_names_file"; then
        "$fail_fn" "pack set '${set_name}' references unknown pack '${pack}'"
      fi
    done
  done
}

extc_check_host_descriptor_matches_defaults() {
  local fail_fn="$1"
  local -n host_dirs_ref="$2"
  local host descriptor_role descriptor_profile

  for host in "${host_dirs_ref[@]}"; do
    if [[ ! -f "hosts/${host}/default.nix" ]]; then
      "$fail_fn" "host '${host}' missing hosts/${host}/default.nix"
    fi

    descriptor_role="$(extc_host_descriptor_role "${host}" 2>/dev/null || true)"
    descriptor_profile="$(extc_host_descriptor_desktop_profile "${host}" 2>/dev/null || true)"

    if [[ -z "$descriptor_role" ]]; then
      "$fail_fn" "host '${host}' missing descriptor role in hosts/host-descriptors.nix"
    elif ! rg -q "custom\\.host\\.role = \"${descriptor_role}\";" "hosts/${host}/default.nix"; then
      "$fail_fn" "host '${host}' default.nix must set custom.host.role = \"${descriptor_role}\" from descriptor"
    fi

    if [[ -z "$descriptor_profile" ]]; then
      "$fail_fn" "host '${host}' missing descriptor desktopProfile in hosts/host-descriptors.nix"
    elif ! rg -q "custom\\.desktop\\.profile = \"${descriptor_profile}\";" "hosts/${host}/default.nix"; then
      "$fail_fn" "host '${host}' default.nix must set custom.desktop.profile = \"${descriptor_profile}\" from descriptor"
    fi
  done
}

extc_list_module_profiles() {
  find modules/profiles/desktop -maxdepth 1 -type f -name 'profile-*.nix' ! -name 'profile-registry.nix' ! -name 'profile-metadata.nix' -printf '%f\n' \
    | sed -E 's/^profile-(.*)\.nix$/\1/' \
    | sort -u
}

extc_list_registry_profiles() {
  sed -nE 's/^[[:space:]]*([a-z0-9-]+)[[:space:]]*=[[:space:]]*\.\/profile-[a-z0-9-]+\.nix;/\1/p' modules/profiles/desktop/profile-registry.nix \
    | sort -u
}

extc_check_profile_registry_key_path_consistency() {
  local fail_fn="$1"
  local registry_file="$2"
  local line profile_key profile_module

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    profile_key="${line%%=*}"
    profile_module="${line#*=}"
    profile_module="${profile_module#./profile-}"
    profile_module="${profile_module%.nix}"
    if [[ "$profile_key" != "$profile_module" ]]; then
      "$fail_fn" "profile registry key/path mismatch: ${line}"
    fi
  done < <(
    sed -nE 's/^[[:space:]]*([a-z0-9-]+)[[:space:]]*=[[:space:]]*(\.\/profile-[a-z0-9-]+\.nix);/\1=\2/p' "$registry_file"
  )
}

extc_default_required_capability_keys() {
  cat <<'EOF'
desktopFiles
desktopUserApps
niri
hyprland
dms
noctalia
caelestiaHyprland
EOF
}

extc_check_profiles_metadata_contracts() {
  local fail_fn="$1"
  local -n registry_profiles_ref="$2"
  local required_capability_keys_file="$3"
  local pack_set_names_file="$4"
  local profile profile_json key set_name
  local -a profile_pack_sets=()

  for profile in "${registry_profiles_ref[@]}"; do
    profile_json="$(extc_profile_json "${profile}")"

    if [[ "$(jq -r 'type' <<<"$profile_json")" != "object" ]]; then
      "$fail_fn" "profile '${profile}' missing metadata object in modules/profiles/desktop/profile-metadata.nix"
      continue
    fi

    if ! jq -e 'has("capabilities") and has("requiredIntegrations") and has("optionalIntegrations") and has("packSets")' <<<"$profile_json" >/dev/null; then
      "$fail_fn" "profile '${profile}' metadata missing required fields"
    fi

    mapfile -t profile_pack_sets < <(jq -r '.packSets[]?' <<<"$profile_json" | sort -u)
    if [[ "${#profile_pack_sets[@]}" -eq 0 ]]; then
      "$fail_fn" "profile '${profile}' packSets must declare at least one set"
    fi
    for set_name in "${profile_pack_sets[@]}"; do
      if ! grep -Fxq "$set_name" "$pack_set_names_file"; then
        "$fail_fn" "profile '${profile}' references unknown pack set '${set_name}'"
      fi
    done

    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      if ! jq -e ".capabilities | has(\"${key}\")" <<<"$profile_json" >/dev/null; then
        "$fail_fn" "profile '${profile}' capabilities missing key '${key}'"
      fi
    done <"$required_capability_keys_file"
  done
}
