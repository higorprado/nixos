#!/usr/bin/env bash

# shellcheck source=nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/nix_eval.sh"

extc_profile_metadata_root_json() {
  nix_eval_json_expr "import ${PWD}/modules/profiles/desktop/profile-metadata.nix"
}

extc_profile_metadata_profiles_json() {
  nix_eval_json_expr "
    let
      metadataRoot = import ${PWD}/modules/profiles/desktop/profile-metadata.nix;
      metadata = metadataRoot.profiles or metadataRoot;
    in
      metadata
  "
}

extc_profile_json() {
  local profile="$1"
  nix_eval_json_expr "
    let
      metadataRoot = import ${PWD}/modules/profiles/desktop/profile-metadata.nix;
      metadata = metadataRoot.profiles or metadataRoot;
    in
      metadata.\"${profile}\" or null
  "
}

extc_metadata_profile_names() {
  extc_profile_metadata_profiles_json | jq -r 'keys[]' | sort -u
}

extc_pack_registry_root_json() {
  nix_eval_json_expr "import ${PWD}/home/user/desktop/pack-registry.nix"
}

extc_pack_names() {
  nix_eval_json_expr "builtins.attrNames (import ${PWD}/home/user/desktop/pack-registry.nix).packs" \
    | jq -r '.[]' \
    | sort -u
}

extc_pack_set_names() {
  nix_eval_json_expr "builtins.attrNames (import ${PWD}/home/user/desktop/pack-registry.nix).packSets" \
    | jq -r '.[]' \
    | sort -u
}

extc_pack_module_path() {
  local pack="$1"
  nix_eval_raw_expr "toString ((import ${PWD}/home/user/desktop/pack-registry.nix).packs.\"${pack}\".module)"
}

extc_pack_set_entries() {
  local set_name="$1"
  nix_eval_json_expr "(import ${PWD}/home/user/desktop/pack-registry.nix).packSets.\"${set_name}\"" \
    | jq -r '.[]?' \
    | sort -u
}

extc_host_descriptor_names() {
  nix_eval_json_expr "builtins.attrNames (import ${PWD}/hosts/host-descriptors.nix)" \
    | jq -r '.[]' \
    | sort -u
}

extc_host_descriptor_role() {
  local host="$1"
  nix_eval_raw_expr "(import ${PWD}/hosts/host-descriptors.nix).\"${host}\".role"
}

extc_host_descriptor_desktop_profile() {
  local host="$1"
  nix_eval_raw_expr "(import ${PWD}/hosts/host-descriptors.nix).\"${host}\".desktopProfile"
}
