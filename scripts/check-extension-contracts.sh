#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

report_fail() {
  log_fail "extension-contracts" "$1"
  fail=1
}

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

mkset() {
  local out="$1"
  shift
  printf '%s\n' "$@" | sed '/^$/d' | sort -u >"$out"
}

check_set_sync() {
  local left_label="$1"
  local left_file="$2"
  local right_label="$3"
  local right_file="$4"

  local missing extra
  missing="$(comm -23 "$left_file" "$right_file" || true)"
  extra="$(comm -13 "$left_file" "$right_file" || true)"

  if [[ -n "$missing" ]]; then
    report_fail "${right_label} missing entries present in ${left_label}: $(tr '\n' ' ' <<<"$missing")"
  fi
  if [[ -n "$extra" ]]; then
    report_fail "${right_label} has entries not declared in ${left_label}: $(tr '\n' ' ' <<<"$extra")"
  fi
}

check_assignment_scope "custom.host.role" '^[[:space:]]*custom\.host\.role[[:space:]]*=' is_allowed_host_role_assignment
check_assignment_scope "custom.desktop.profile" '^[[:space:]]*custom\.desktop\.profile[[:space:]]*=' is_allowed_desktop_profile_assignment

if ! rg -q 'packRegistry = import ./pack-registry.nix;' home/user/desktop/default.nix; then
  report_fail "home/user/desktop/default.nix must import pack-registry.nix"
fi
if ! rg -q 'profilePackSets[[:space:]]*=' home/user/desktop/default.nix; then
  report_fail "home/user/desktop/default.nix must derive profilePackSets from profile metadata"
fi
if ! rg -q '\+\+ selectedPackModules;' home/user/desktop/default.nix; then
  report_fail "home/user/desktop/default.nix must compose imports with selectedPackModules"
fi

mapfile -t pack_names < <(
  awk '
    /^[[:space:]]*packs = \{/ { in_packs = 1; next }
    in_packs && /^[[:space:]]*packSets = \{/ { in_packs = 0 }
    in_packs { print }
  ' home/user/desktop/pack-registry.nix \
    | sed -nE 's/^[[:space:]]*([a-z0-9-]+)[[:space:]]*=[[:space:]]*\{/\1/p' \
    | sort -u
)

mapfile -t pack_set_names < <(
  awk '
    /^[[:space:]]*packSets = \{/ { in_sets = 1; next }
    in_sets && /^[[:space:]]*};/ { in_sets = 0 }
    in_sets { print }
  ' home/user/desktop/pack-registry.nix \
    | sed -nE 's/^[[:space:]]*([a-z0-9-]+)[[:space:]]*=[[:space:]]*\[.*/\1/p' \
    | sort -u
)

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkset "$tmpdir/pack_names" "${pack_names[@]}"
mkset "$tmpdir/pack_set_names" "${pack_set_names[@]}"

for pack in "${pack_names[@]}"; do
  block="$(
    awk "/^[[:space:]]*${pack}[[:space:]]*=[[:space:]]*\\{/,/^[[:space:]]*\\};/" home/user/desktop/pack-registry.nix
  )"
  module_rel="$(sed -nE 's/^[[:space:]]*module[[:space:]]*=[[:space:]]*\.\/([a-z0-9-]+\.nix);/\1/p' <<<"$block" | head -n 1)"
  if [[ -z "$module_rel" ]]; then
    report_fail "pack '${pack}' missing module path in pack-registry.nix"
    continue
  fi
  if [[ ! -f "home/user/desktop/${module_rel}" ]]; then
    report_fail "pack '${pack}' references missing module: home/user/desktop/${module_rel}"
  fi
done

for set_name in "${pack_set_names[@]}"; do
  set_block="$(
    awk "/^[[:space:]]*${set_name}[[:space:]]*=[[:space:]]*\\[/,/\\];/" home/user/desktop/pack-registry.nix
  )"
  mapfile -t set_entries < <(rg -o '"[a-z0-9-]+"' <<<"$set_block" | tr -d '"' | sort -u)
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

mapfile -t host_registry_entries < <(
  awk '/hostRegistry = \{/,/^[[:space:]]*\};/' flake.nix \
    | sed -nE 's/^[[:space:]]*([a-z0-9-]+)[[:space:]]*=[[:space:]]*\[.*/\1/p' \
    | sort -u
)

mkset "$tmpdir/host_dirs" "${host_dirs[@]}"
mkset "$tmpdir/host_registry" "${host_registry_entries[@]}"
check_set_sync "host directories" "$tmpdir/host_dirs" "host registry entries" "$tmpdir/host_registry"

for host in "${host_dirs[@]}"; do
  if [[ ! -f "hosts/${host}/default.nix" ]]; then
    report_fail "host '${host}' missing hosts/${host}/default.nix"
  fi
  if ! rg -q "\./hosts/${host}/default\.nix" flake.nix; then
    report_fail "host '${host}' missing ./hosts/${host}/default.nix reference in flake hostRegistry"
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

mapfile -t metadata_profiles < <(
  sed -nE 's/^  ([a-z0-9-]+) = \{/\1/p' modules/profiles/desktop/profile-metadata.nix \
    | sort -u
)

if ! rg -q 'profileModules = import ../profiles/desktop/profile-registry.nix;' modules/options/desktop-options.nix; then
  report_fail "modules/options/desktop-options.nix must import desktop profile registry"
fi
if ! rg -q 'type = lib.types.enum profileNames;' modules/options/desktop-options.nix; then
  report_fail "modules/options/desktop-options.nix must derive enum from profileNames"
fi

mkset "$tmpdir/expected" "${registry_profiles[@]}"
mkset "$tmpdir/modules" "${module_profiles[@]}"
mkset "$tmpdir/registry" "${registry_profiles[@]}"
mkset "$tmpdir/metadata" "${metadata_profiles[@]}"

check_set_sync "profile registry" "$tmpdir/expected" "profile modules" "$tmpdir/modules"
check_set_sync "profile registry" "$tmpdir/expected" "profile metadata keys" "$tmpdir/metadata"

if ! rg -q 'builtins\.attrNames \(import .*profile-metadata\.nix' scripts/check-profile-matrix.sh; then
  report_fail "scripts/check-profile-matrix.sh must derive profile list from profile metadata"
fi
if ! rg -q 'expected = profileMetadata\..*capabilities;' scripts/check-profile-matrix.sh; then
  report_fail "scripts/check-profile-matrix.sh must derive expected capabilities from profile metadata"
fi

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
  block="$(awk "/^  ${profile} = \\{/,/^  \\};/" modules/profiles/desktop/profile-metadata.nix)"
  if [[ -z "$block" ]]; then
    report_fail "profile '${profile}' missing metadata block in modules/profiles/desktop/profile-metadata.nix"
    continue
  fi

  if ! rg -q 'capabilities = \{' <<<"$block"; then
    report_fail "profile '${profile}' metadata missing capabilities block"
  fi
  if ! rg -q 'requiredIntegrations = ' <<<"$block"; then
    report_fail "profile '${profile}' metadata missing requiredIntegrations"
  fi
  if ! rg -q 'optionalIntegrations = ' <<<"$block"; then
    report_fail "profile '${profile}' metadata missing optionalIntegrations"
  fi
  if ! rg -q 'packSets = ' <<<"$block"; then
    report_fail "profile '${profile}' metadata missing packSets"
  fi

  pack_set_block="$(awk '/packSets = \[/,/\];/' <<<"$block")"
  mapfile -t profile_pack_sets < <(rg -o '"[a-z0-9-]+"' <<<"$pack_set_block" | tr -d '"' | sort -u)
  if [[ "${#profile_pack_sets[@]}" -eq 0 ]]; then
    report_fail "profile '${profile}' packSets must declare at least one set"
  fi
  for set_name in "${profile_pack_sets[@]}"; do
    if ! grep -Fxq "$set_name" "$tmpdir/pack_set_names"; then
      report_fail "profile '${profile}' references unknown pack set '${set_name}'"
    fi
  done

  for key in "${required_capability_keys[@]}"; do
    if ! rg -q "${key}[[:space:]]*=" <<<"$block"; then
      report_fail "profile '${profile}' capabilities missing key '${key}'"
    fi
  done
done

if ! rg -q 'profileMetadata = import ./desktop/profile-metadata.nix;' modules/profiles/profile-capabilities.nix; then
  report_fail "modules/profiles/profile-capabilities.nix must import profile metadata"
fi
if ! rg -q 'defaultCapabilities // selectedProfile\.capabilities' modules/profiles/profile-capabilities.nix; then
  report_fail "modules/profiles/profile-capabilities.nix must derive capabilities from selectedProfile.capabilities"
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-contracts] ok: host/profile extension contracts hold"
