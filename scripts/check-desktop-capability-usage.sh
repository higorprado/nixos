#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

require_cmd "desktop-capabilities" "rg"

# Raw profile comparisons should live only in capability source and desktop
# profile implementation modules.
allowlist=(
  "modules/profiles/profile-capabilities.nix"
)

is_allowed() {
  local candidate="$1"
  local allowed
  for allowed in "${allowlist[@]}"; do
    if [[ "$candidate" == "$allowed" ]]; then
      return 0
    fi
  done
  if [[ "$candidate" == modules/profiles/desktop/* ]]; then
    return 0
  fi
  return 1
}

matches="$(rg -n --glob '*.nix' \
  'osConfig\.custom\.desktop\.profile ==|cfg\.profile ==|profile == \"(dms|niri-only|noctalia|dms-hyprland|caelestia-hyprland)\"' \
  modules home || true)"

if [[ -z "$matches" ]]; then
  echo "[desktop-capabilities] ok: no raw profile comparisons found"
  exit 0
fi

violations=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  file="${line%%:*}"
  if ! is_allowed "$file"; then
    violations+="$line"$'\n'
  fi
done <<<"$matches"

if [[ -n "$violations" ]]; then
  echo "[desktop-capabilities] fail: raw profile comparisons found outside allowlist"
  printf '%s' "$violations"
  exit 1
fi

echo "[desktop-capabilities] ok: raw profile comparisons limited to capability source/desktop modules"
