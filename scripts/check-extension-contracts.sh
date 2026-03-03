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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mapfile -t enum_profiles < <(
  awk '/types\.enum[[:space:]]*\[/,/\];/' modules/options/desktop-options.nix \
    | rg -o '"[a-z0-9-]+"' \
    | tr -d '"' \
    | sort -u
)

mapfile -t module_profiles < <(
  find modules/profiles/desktop -maxdepth 1 -type f -name 'profile-*.nix' -printf '%f\n' \
    | sed -E 's/^profile-(.*)\.nix$/\1/' \
    | sort -u
)

mapfile -t imported_profiles < <(
  rg -No './profile-[a-z0-9-]+\.nix' modules/profiles/desktop/default.nix \
    | sed -E 's#\./profile-([a-z0-9-]+)\.nix#\1#' \
    | sort -u
)

mapfile -t matrix_profiles < <(
  awk '/profiles=\(/,/\)/' scripts/check-profile-matrix.sh \
    | rg -o '"[a-z0-9-]+"' \
    | tr -d '"' \
    | sort -u
)

mkset "$tmpdir/enum" "${enum_profiles[@]}"
mkset "$tmpdir/modules" "${module_profiles[@]}"
mkset "$tmpdir/imports" "${imported_profiles[@]}"
mkset "$tmpdir/matrix" "${matrix_profiles[@]}"

check_set_sync "desktop option enum" "$tmpdir/enum" "profile modules" "$tmpdir/modules"
check_set_sync "desktop option enum" "$tmpdir/enum" "desktop profile imports" "$tmpdir/imports"
check_set_sync "desktop option enum" "$tmpdir/enum" "profile matrix list" "$tmpdir/matrix"

for profile in "${enum_profiles[@]}"; do
  if ! rg -q "\"${profile}\"" modules/profiles/profile-capabilities.nix; then
    report_fail "profile '${profile}' missing from modules/profiles/profile-capabilities.nix"
  fi
done

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-contracts] ok: host/profile extension contracts hold"
