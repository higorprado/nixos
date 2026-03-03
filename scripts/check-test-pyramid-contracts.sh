#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

report_fail() {
  log_fail "test-pyramid" "$1"
  fail=1
}

require_cmds "test-pyramid" "jq"

config_file="tests/pyramid/config-test-pyramid.json"
if [[ ! -f "$config_file" ]]; then
  report_fail "missing config file: $config_file"
  exit 1
fi

if ! jq -e . "$config_file" >/dev/null; then
  report_fail "invalid JSON in $config_file"
  exit 1
fi

config_json="$(<"$config_file")"

require_layer() {
  local layer="$1"
  if ! jq -e --arg layer "$layer" '.layers[$layer] | type == "object"' <<<"$config_json" >/dev/null; then
    report_fail "missing layer '$layer' in $config_file"
    return
  fi

  if ! jq -e --arg layer "$layer" '.layers[$layer].owner | type == "string" and length > 0' <<<"$config_json" >/dev/null; then
    report_fail "layer '$layer' must define non-empty owner"
  fi

  if ! jq -e --arg layer "$layer" '.layers[$layer].budgetSeconds | type == "number" and . > 0' <<<"$config_json" >/dev/null; then
    report_fail "layer '$layer' must define budgetSeconds > 0"
  fi

  if ! jq -e --arg layer "$layer" '.layers[$layer].checks | type == "array" and length > 0' <<<"$config_json" >/dev/null; then
    report_fail "layer '$layer' must define at least one check"
  fi

  while IFS= read -r check_path; do
    [[ -z "$check_path" ]] && continue
    repo_rel="${check_path#./}"
    if [[ ! -e "$repo_rel" ]]; then
      report_fail "layer '$layer' references missing check path: $check_path"
    fi
  done < <(jq -r --arg layer "$layer" '.layers[$layer].checks[]?' <<<"$config_json")
}

require_category() {
  local category="$1"
  if ! jq -e --arg category "$category" '.categories[$category] | type == "object"' <<<"$config_json" >/dev/null; then
    report_fail "missing category '$category' in $config_file"
    return
  fi

  if ! jq -e --arg category "$category" '.categories[$category].layers | type == "array" and length > 0' <<<"$config_json" >/dev/null; then
    report_fail "category '$category' must map to at least one layer"
  fi

  while IFS= read -r mapped_layer; do
    [[ -z "$mapped_layer" ]] && continue
    case "$mapped_layer" in
      A|B|C) ;;
      *) report_fail "category '$category' references unknown layer '$mapped_layer'" ;;
    esac
  done < <(jq -r --arg category "$category" '.categories[$category].layers[]?' <<<"$config_json")

  if ! jq -e --arg category "$category" '.categories[$category].checks | type == "array" and length > 0' <<<"$config_json" >/dev/null; then
    report_fail "category '$category' must define at least one check"
  fi

  while IFS= read -r check_path; do
    [[ -z "$check_path" ]] && continue
    repo_rel="${check_path#./}"
    if [[ ! -e "$repo_rel" ]]; then
      report_fail "category '$category' references missing check path: $check_path"
    fi
  done < <(jq -r --arg category "$category" '.categories[$category].checks[]?' <<<"$config_json")

  if ! jq -e --arg category "$category" '.categories[$category].fixtures | type == "array" and length > 0' <<<"$config_json" >/dev/null; then
    report_fail "category '$category' must define at least one fixture"
  fi

  while IFS= read -r fixture_path; do
    [[ -z "$fixture_path" ]] && continue
    if [[ ! -e "$fixture_path" ]]; then
      report_fail "category '$category' references missing fixture: $fixture_path"
    fi
  done < <(jq -r --arg category "$category" '.categories[$category].fixtures[]?' <<<"$config_json")
}

for layer in A B C; do
  require_layer "$layer"
done

for category in host_addition profile_addition pack_addition option_migration_lifecycle; do
  require_category "$category"
done

host_fixture="tests/fixtures/host-addition/host-descriptor.json"
if ! jq -e 'has("role") and (.role == "desktop" or .role == "server") and has("desktopProfile")' "$host_fixture" >/dev/null; then
  report_fail "host fixture must contain role (desktop|server) and desktopProfile"
fi

profile_fixture="tests/fixtures/profile-addition/profile-metadata.json"
if ! jq -e 'has("capabilities") and has("requiredIntegrations") and has("optionalIntegrations") and has("packSets")' "$profile_fixture" >/dev/null; then
  report_fail "profile fixture must contain capabilities/integration/packSets fields"
fi
for key in desktopFiles desktopUserApps niri hyprland dms noctalia caelestiaHyprland; do
  if ! jq -e --arg key "$key" '.capabilities | has($key)' "$profile_fixture" >/dev/null; then
    report_fail "profile fixture capabilities missing key '$key'"
  fi
done

pack_fixture="tests/fixtures/pack-addition/pack-registry.json"
if ! jq -e 'has("packs") and has("packSets") and (.packs | type == "object") and (.packSets | type == "object")' "$pack_fixture" >/dev/null; then
  report_fail "pack fixture must contain packs and packSets objects"
fi
while IFS= read -r module_path; do
  [[ -z "$module_path" ]] && continue
  if [[ ! -f "$module_path" ]]; then
    report_fail "pack fixture references missing module: $module_path"
  fi
done < <(jq -r '.packs[]?.module // empty' "$pack_fixture")

while IFS= read -r pack_name; do
  [[ -z "$pack_name" ]] && continue
  if ! jq -e --arg pack "$pack_name" '.packs | has($pack)' "$pack_fixture" >/dev/null; then
    report_fail "pack fixture packSets reference unknown pack '$pack_name'"
  fi
done < <(jq -r '.packSets[]?[]?' "$pack_fixture")

option_fixture="tests/fixtures/option-migration-lifecycle/migration-registry.json"
if ! jq -e 'has("renamed") and has("aliases") and has("removed")' "$option_fixture" >/dev/null; then
  report_fail "option migration fixture must contain renamed/aliases/removed"
fi
if ! jq -e '.renamed | type == "array" and length > 0' "$option_fixture" >/dev/null; then
  report_fail "option migration fixture renamed list must be non-empty"
fi
if ! jq -e '.removed | type == "array" and length > 0' "$option_fixture" >/dev/null; then
  report_fail "option migration fixture removed list must be non-empty"
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[test-pyramid] ok: layer/category contracts and synthetic fixtures are valid"
