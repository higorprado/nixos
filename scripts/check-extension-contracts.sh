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
if ! rg -q '\+\+ packRegistry\.packModules;' home/user/desktop/default.nix; then
  report_fail "home/user/desktop/default.nix must compose imports with packRegistry.packModules"
fi

mapfile -t pack_modules < <(
  sed -nE 's/^[[:space:]]*\.\/([a-z0-9-]+\.nix)[[:space:]]*$/\1/p' home/user/desktop/pack-registry.nix \
    | sort -u
)

for module in "${pack_modules[@]}"; do
  if [[ ! -f "home/user/desktop/${module}" ]]; then
    report_fail "pack registry references missing module: home/user/desktop/${module}"
  fi
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mapfile -t module_profiles < <(
  find modules/profiles/desktop -maxdepth 1 -type f -name 'profile-*.nix' ! -name 'profile-registry.nix' -printf '%f\n' \
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

mapfile -t matrix_profiles < <(
  awk '/profiles=\(/,/\)/' scripts/check-profile-matrix.sh \
    | rg -o '"[a-z0-9-]+"' \
    | tr -d '"' \
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
mkset "$tmpdir/matrix" "${matrix_profiles[@]}"

check_set_sync "profile registry" "$tmpdir/expected" "profile modules" "$tmpdir/modules"
check_set_sync "profile registry" "$tmpdir/expected" "profile matrix list" "$tmpdir/matrix"

for profile in "${registry_profiles[@]}"; do
  if ! rg -q "\"${profile}\"" modules/profiles/profile-capabilities.nix; then
    report_fail "profile '${profile}' missing from modules/profiles/profile-capabilities.nix"
  fi
done

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-contracts] ok: host/profile extension contracts hold"
