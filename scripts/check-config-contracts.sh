#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

report_fail() {
  log_fail "config-contracts" "$1"
  fail=1
}

expect_equal() {
  local label="$1"
  local got="$2"
  local expected="$3"
  if [ "$got" != "$expected" ]; then
    report_fail "${label}: expected '${expected}', got '${got}'"
  fi
}

predator_role="$(nix eval --raw "path:$PWD#nixosConfigurations.predator.config.custom.host.role")"
server_role="$(nix eval --raw "path:$PWD#nixosConfigurations.server-example.config.custom.host.role")"
expect_equal "predator host role" "$predator_role" "desktop"
expect_equal "server-example host role" "$server_role" "server"

predator_caps_json="$(nix eval --json "path:$PWD#nixosConfigurations.predator.config.custom.desktop.capabilities")"
server_caps_json="$(nix eval --json "path:$PWD#nixosConfigurations.server-example.config.custom.desktop.capabilities")"

expect_equal "predator default niri capability" "$(jq -r '.niri' <<<"$predator_caps_json")" "true"
expect_equal "predator default hyprland capability" "$(jq -r '.hyprland' <<<"$predator_caps_json")" "false"
expect_equal "predator default dms capability" "$(jq -r '.dms' <<<"$predator_caps_json")" "true"

for key in niri hyprland dms noctalia caelestiaHyprland desktopFiles desktopUserApps; do
  expect_equal "server-example capability ${key}" "$(jq -r ".${key}" <<<"$server_caps_json")" "false"
done

hm_user="$(nix eval --raw "path:$PWD#nixosConfigurations.predator.config.custom.user.name")"
if rg -n "home-manager\\.users\\.${hm_user}\\." .github scripts docs/for-agents docs/for-humans README.md >/dev/null; then
  report_fail "found hardcoded home-manager user '${hm_user}' in tracked CI/script/docs paths"
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[config-contracts] ok: role/capability/username-indirection invariants hold"
