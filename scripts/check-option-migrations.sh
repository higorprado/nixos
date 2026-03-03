#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/nix_eval.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

report_fail() {
  log_fail "option-migrations" "$1"
  fail=1
}

require_cmds "option-migrations" "jq" "nix" "rg"

if ! rg -q './option-migrations.nix' modules/options/default.nix; then
  report_fail "modules/options/default.nix must import ./option-migrations.nix"
fi

registry_json="$(nix_eval_json_expr "import ${PWD}/modules/options/migration-registry.nix")"

if ! jq -e 'has("renamed") and has("aliases") and has("removed")' <<<"$registry_json" >/dev/null; then
  report_fail "modules/options/migration-registry.nix must expose renamed, aliases, and removed arrays"
fi

valid_month() {
  local month="$1"
  [[ "$month" =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]]
}

tmpdir="$(mktemp_dir_scoped option-migrations)"
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/registered_paths"

validate_renamed_or_alias() {
  local kind="$1"
  local entry="$2"
  local from_path to_path remove_after note

  if ! jq -e '.from | type == "array" and length > 0 and all(.[]; type == "string" and test("^[A-Za-z0-9_-]+$"))' <<<"$entry" >/dev/null; then
    report_fail "${kind} entry has invalid from path: ${entry}"
    return
  fi
  if ! jq -e '.to | type == "array" and length > 0 and all(.[]; type == "string" and test("^[A-Za-z0-9_-]+$"))' <<<"$entry" >/dev/null; then
    report_fail "${kind} entry has invalid to path: ${entry}"
    return
  fi

  remove_after="$(jq -r '.removeAfter // ""' <<<"$entry")"
  note="$(jq -r '.note // ""' <<<"$entry")"
  if ! valid_month "$remove_after"; then
    report_fail "${kind} entry removeAfter must use YYYY-MM: ${entry}"
  fi
  if [[ -z "$note" ]]; then
    report_fail "${kind} entry note must be non-empty: ${entry}"
  fi

  from_path="$(jq -r '.from | join(".")' <<<"$entry")"
  to_path="$(jq -r '.to | join(".")' <<<"$entry")"
  if [[ "$from_path" == "$to_path" ]]; then
    report_fail "${kind} entry from/to cannot be identical: ${entry}"
  fi

  echo "$from_path" >>"$tmpdir/registered_paths"
}

while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  validate_renamed_or_alias "renamed" "$entry"
done < <(jq -c '.renamed[]?' <<<"$registry_json")

while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  validate_renamed_or_alias "alias" "$entry"
done < <(jq -c '.aliases[]?' <<<"$registry_json")

while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  local_path="$(jq -r '.path | join(".")' <<<"$entry" 2>/dev/null || true)"

  if ! jq -e '.path | type == "array" and length > 0 and all(.[]; type == "string" and test("^[A-Za-z0-9_-]+$"))' <<<"$entry" >/dev/null; then
    report_fail "removed entry has invalid path: ${entry}"
    continue
  fi

  remove_after="$(jq -r '.removeAfter // ""' <<<"$entry")"
  message="$(jq -r '.message // ""' <<<"$entry")"
  if ! valid_month "$remove_after"; then
    report_fail "removed entry removeAfter must use YYYY-MM: ${entry}"
  fi
  if [[ -z "$message" ]]; then
    report_fail "removed entry message must be non-empty: ${entry}"
  fi

  local_path="$(jq -r '.path | join(".")' <<<"$entry")"
  echo "$local_path" >>"$tmpdir/registered_paths"
done < <(jq -c '.removed[]?' <<<"$registry_json")

sort -u "$tmpdir/registered_paths" -o "$tmpdir/registered_paths"

base_ref=""
if git rev-parse --verify origin/main >/dev/null 2>&1; then
  base_ref="origin/main"
elif git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
  base_ref="HEAD~1"
fi

if [[ -n "$base_ref" ]]; then
  mapfile -t removed_option_paths < <(
    git diff --unified=0 "$base_ref"...HEAD -- modules/options home/user/options \
      | sed -nE 's/^-+[[:space:]]*options\.([A-Za-z0-9_.-]+)[[:space:]]*=.*/\1/p' \
      | sort -u
  )

  for option_path in "${removed_option_paths[@]}"; do
    [[ -z "$option_path" ]] && continue
    escaped_path="${option_path//./\\.}"
    if rg -n "^[[:space:]]*options\.${escaped_path}[[:space:]]*=" modules/options home/user/options >/dev/null; then
      continue
    fi
    if ! grep -Fxq "$option_path" "$tmpdir/registered_paths"; then
      report_fail "option '${option_path}' removed without migration-registry entry (base: ${base_ref})"
    fi
  done
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[option-migrations] ok: option migration contracts hold"
