#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/system_up_to_date_audit.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/system_up_to_date_audit.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF'
Usage:
  scripts/audit-system-up-to-date.sh [--output <dir>] [--strict] [--exclude-emacs|--include-emacs] [--allow-dirty]

Options:
  --output <dir>     Write report artifacts to this directory.
  --strict           Exit non-zero when any inconsistency is found.
  --exclude-emacs    Exclude emacs-related findings/checks (default).
  --include-emacs    Include emacs-related findings/checks.
  --allow-dirty      Allow running in a dirty git worktree.
  -h, --help         Show this help.

Environment:
  AUDIT_ALLOW_INTERACTIVE_SUDO=1
    Allow sudo-gated checks to run even without sudo -n (for interactive runs).
  AUDIT_REPORT_CONTEXT_SKIPS=1
    Report context/sudo skips as low-severity findings.
EOF
}

STRICT=0
EXCLUDE_EMACS=1
OUTPUT_DIR=""
ALLOW_DIRTY=0
allow_interactive_sudo="${AUDIT_ALLOW_INTERACTIVE_SUDO:-0}"
report_context_skips="${AUDIT_REPORT_CONTEXT_SKIPS:-0}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --output)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --exclude-emacs)
      EXCLUDE_EMACS=1
      shift
      ;;
    --include-emacs)
      EXCLUDE_EMACS=0
      shift
      ;;
    --allow-dirty)
      ALLOW_DIRTY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_fail "system-up-to-date-audit" "unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$ALLOW_DIRTY" -ne 1 ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dirty="$(git status --porcelain=v1 || true)"
  if [ -n "$dirty" ]; then
    log_fail "system-up-to-date-audit" "git worktree is dirty; re-run with --allow-dirty to override"
    exit 2
  fi
fi

if [ -z "$OUTPUT_DIR" ]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  OUTPUT_DIR="$REPO_ROOT/reports/system-up-to-date-$ts"
fi

RAW_DIR="$OUTPUT_DIR/raw"
mkdir -p "$RAW_DIR"

summary_file="$OUTPUT_DIR/summary.md"
incons_file="$OUTPUT_DIR/inconsistencies.md"
matrix_file="$OUTPUT_DIR/scripts-matrix.csv"
findings_tsv="$RAW_DIR/findings.tsv"
checks_tsv="$RAW_DIR/check-status.tsv"

scripts=(
  "scripts/check-declarative-paths.sh"
  "scripts/check-dev-dotfiles-parity.sh"
  "scripts/check-dotfiles-parity.sh"
  "scripts/check-flake-tracked.sh"
  "scripts/check-logid-parity.sh"
  "scripts/check-nix-deprecations.sh"
  "scripts/check-nvim-contract.sh"
  "scripts/check-repo-public-safety.sh"
  "scripts/check-runtime-config-parity.sh"
  "scripts/check-user-services-parity.sh"
  "scripts/nixos-post-switch-smoke.sh"
  "scripts/validate-host.sh"
)

check_count=0
check_pass=0
check_warn=0
check_fail=0
check_skipped=0

finding_count=0
severity_high=0
severity_medium=0
severity_low=0

note_finding() {
  local id="$1"
  local severity="$2"
  local location="$3"
  local evidence="$4"
  local why="$5"
  local action="$6"

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" "$severity" "$location" "$evidence" "$why" "$action" >>"$findings_tsv"
  finding_count=$((finding_count + 1))
  case "$severity" in
    high) severity_high=$((severity_high + 1)) ;;
    medium) severity_medium=$((severity_medium + 1)) ;;
    low) severity_low=$((severity_low + 1)) ;;
  esac
}

run_capture() {
  local name="$1"
  local log="$2"
  shift 2
  local code=0

  check_count=$((check_count + 1))

  if "$@" >"$log" 2>&1; then
    code=0
  else
    code=$?
  fi

  local status="pass"
  if [ "$code" -ne 0 ]; then
    status="fail"
  elif rg -qi '(^|[^a-z])(warn|warning)([^a-z]|$)|\[warn\]|\bWARN\b' "$log" >/dev/null 2>&1; then
    status="warn"
  fi

  case "$status" in
    pass) check_pass=$((check_pass + 1)) ;;
    warn) check_warn=$((check_warn + 1)) ;;
    fail) check_fail=$((check_fail + 1)) ;;
  esac

  printf '%s\t%s\t%s\t%s\n' "$name" "$status" "$code" "$log" >>"$checks_tsv"
  return 0
}

mark_skipped() {
  local name="$1"
  local reason="$2"
  local log="$3"
  check_count=$((check_count + 1))
  check_skipped=$((check_skipped + 1))
  printf 'SKIPPED: %s\n' "$reason" >"$log"
  printf '%s\t%s\t%s\t%s\n' "$name" "skipped" "-" "$log" >>"$checks_tsv"
}

is_nixos_host=0
if [ -f /etc/os-release ] && rg -q '^ID=nixos$' /etc/os-release; then
  is_nixos_host=1
fi

sudo_noninteractive=0
if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
  sudo_noninteractive=1
fi

audit_write_decision_baseline "$RAW_DIR/decision-baseline.tsv" "$EXCLUDE_EMACS"

printf 'id\tseverity\tlocation\tevidence\twhy_inconsistent\trecommended_action\n' >"$findings_tsv"
printf 'check\tstatus\texit_code\tlog_path\n' >"$checks_tsv"
printf 'script,status,classification,inconsistency_count,notes\n' >"$matrix_file"

(
  cd "$REPO_ROOT"
  rg --files scripts | sort >"$RAW_DIR/scripts-list.txt"
  if [ "$EXCLUDE_EMACS" -eq 1 ]; then
    rg -n 'emacs|doom|spacemacs' home modules config scripts docs >"$RAW_DIR/emacs-reference-scan.txt" 2>/dev/null || true
  fi
)

for script_rel in "${scripts[@]}"; do
  script_path="$REPO_ROOT/$script_rel"
  base="$(basename "$script_rel" .sh)"
  script_incons=0
  notes=()

  if [ ! -f "$script_path" ]; then
    notes+=("missing script file")
    script_incons=$((script_incons + 1))
    note_finding "S-MISSING-$base" "high" "$script_rel" "$RAW_DIR/scripts-list.txt" \
      "Script listed in plan is missing from repository." \
      "Restore script or update audit plan inventory."
    printf '%s,%s,%s,%s,%s\n' "$script_rel" "fail" "$(audit_class_for_script "$script_rel")" "$script_incons" "\"${notes[*]}\"" >>"$matrix_file"
    continue
  fi

  bashn_log="$RAW_DIR/${base}.bashn.log"
  run_capture "bash-n:$script_rel" "$bashn_log" bash -n "$script_path"
  bashn_status="$(awk -F '\t' -v n="bash-n:$script_rel" '$1==n{print $2}' "$checks_tsv" | tail -n1)"
  if [ "$bashn_status" = "fail" ]; then
    script_incons=$((script_incons + 1))
    notes+=("bash -n failed")
    note_finding "S-BASHN-$base" "high" "$script_rel" "$bashn_log" \
      "Script has syntax errors and cannot be relied on for audit automation." \
      "Fix shell syntax before using script in validation pipelines."
  fi

  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck_log="$RAW_DIR/${base}.shellcheck.log"
    run_capture "shellcheck:$script_rel" "$shellcheck_log" shellcheck "$script_path"
    shellcheck_status="$(awk -F '\t' -v n="shellcheck:$script_rel" '$1==n{print $2}' "$checks_tsv" | tail -n1)"
    if [ "$shellcheck_status" = "fail" ] || [ "$shellcheck_status" = "warn" ]; then
      script_incons=$((script_incons + 1))
      notes+=("shellcheck issues")
      note_finding "S-SHC-$base" "low" "$script_rel" "$shellcheck_log" \
        "Shellcheck reported quality issues that can hide runtime edge cases." \
        "Resolve shellcheck findings or document suppressions with justification."
    fi
  else
    mark_skipped "shellcheck:$script_rel" "shellcheck not installed" "$RAW_DIR/${base}.shellcheck.log"
  fi

  deps_log="$RAW_DIR/${base}.deps.log"
  : >"$deps_log"
  missing_deps=0
  for dep in $(audit_deps_for_script "$script_rel"); do
    if command -v "$dep" >/dev/null 2>&1; then
      printf 'ok %s -> %s\n' "$dep" "$(command -v "$dep")" >>"$deps_log"
    else
      printf 'missing %s\n' "$dep" >>"$deps_log"
      missing_deps=$((missing_deps + 1))
    fi
  done
  if [ "$missing_deps" -gt 0 ]; then
    run_capture "deps:$script_rel" "$RAW_DIR/${base}.deps-status.log" false
    script_incons=$((script_incons + 1))
    notes+=("missing dependencies")
    note_finding "S-DEPS-$base" "medium" "$script_rel" "$deps_log" \
      "Script requires commands that are not currently available in PATH." \
      "Install missing dependencies or gate the script with preflight checks."
  else
    run_capture "deps:$script_rel" "$RAW_DIR/${base}.deps-status.log" true
  fi

  case "$script_rel" in
    scripts/check-dev-dotfiles-parity.sh)
      if rg -n 'cerebelo|\.ssh/config|\.gitconfig' "$script_path" >"$RAW_DIR/${base}.policy-scan.log" 2>&1; then
        script_incons=$((script_incons + 1))
        notes+=("contains personal host/dotfile assumptions")
        note_finding "P001" "high" "$script_rel" "$RAW_DIR/${base}.policy-scan.log" \
          "Shared repo script encodes personal host/dotfile assumptions, conflicting with private-ops boundary." \
          "Move host-personal checks to private scripts or parameterize them."
      fi
      ;;
    scripts/check-user-services-parity.sh)
      if rg -n 'backup-restic-cerebelo|backup-rsync-cerebelo' "$script_path" >"$RAW_DIR/${base}.policy-scan.log" 2>&1; then
        script_incons=$((script_incons + 1))
        notes+=("contains private backup service assumptions")
        note_finding "P002" "high" "$script_rel" "$RAW_DIR/${base}.policy-scan.log" \
          "Shared script hardcodes private backup units tied to personal endpoint naming." \
          "Move this unit policy to private ops or externalize unit list through config."
      fi
      ;;
    scripts/nixos-post-switch-smoke.sh)
      if rg -n 'backup-restic-cerebelo|backup-rsync-cerebelo|claude|crush' "$script_path" >"$RAW_DIR/${base}.policy-scan.log" 2>&1; then
        script_incons=$((script_incons + 1))
        notes+=("contains personal app and backup assumptions")
        note_finding "P003" "medium" "$script_rel" "$RAW_DIR/${base}.policy-scan.log" \
          "Smoke script mixes shared checks with personal app and backup-specific assertions." \
          "Split shared smoke checks from private workstation checks."
      fi
      ;;
    scripts/check-dotfiles-parity.sh)
      if rg -n '"\$repo_root/home/\$home_user_dir"/\*\.nix' "$script_path" >"$RAW_DIR/${base}.policy-scan.log" 2>&1; then
        script_incons=$((script_incons + 1))
        notes+=("top-level-only nix scan may miss nested declarations")
        note_finding "P004" "medium" "$script_rel" "$RAW_DIR/${base}.policy-scan.log" \
          "Dotfiles parity scanner only reads top-level user nix files and can miss nested module declarations." \
          "Use recursive scan across home/<user>/**/*.nix for managed file discovery."
      fi
      ;;
    scripts/check-runtime-config-parity.sh)
      if rg -n 'check_pair .*/dms/settings\.json|check_pair .*/keyrs/config\.toml' "$script_path" >"$RAW_DIR/${base}.policy-scan.log" 2>&1 \
        && ! rg -q 'strict_mutable|mutable content drift|mode="\$3"' "$script_path"; then
        script_incons=$((script_incons + 1))
        notes+=("strict runtime parity against mutable-copy targets")
        note_finding "P005" "medium" "$script_rel" "$RAW_DIR/${base}.policy-scan.log" \
          "Runtime parity marks mutable copy-once files as hard failures, conflicting with mutable-config caveat." \
          "Classify known mutable targets as warn/drift instead of strict fail."
      fi
      ;;
    scripts/validate-host.sh)
      if rg -n 'flake_ref=.*#predator' "$script_path" >"$RAW_DIR/${base}.policy-scan.log" 2>&1; then
        script_incons=$((script_incons + 1))
        notes+=("hardcoded host flake target")
        note_finding "P006" "low" "$script_rel" "$RAW_DIR/${base}.policy-scan.log" \
          "Validation script is tied to one host target and is less portable across multi-host setups." \
          "Accept host as argument or environment variable."
      fi
      ;;
  esac

  if [ "$script_rel" = "scripts/nixos-post-switch-smoke.sh" ]; then
    if [ "$is_nixos_host" -eq 1 ] && [ "$sudo_noninteractive" -eq 1 ]; then
      run_capture "exec:$script_rel" "$RAW_DIR/${base}.exec.log" bash "$script_path"
    elif [ "$is_nixos_host" -eq 1 ] && [ "$allow_interactive_sudo" = "1" ]; then
      run_capture "exec:$script_rel" "$RAW_DIR/${base}.exec.log" bash "$script_path"
    elif [ "$is_nixos_host" -eq 0 ]; then
      mark_skipped "exec:$script_rel" "not running on NixOS host" "$RAW_DIR/${base}.exec.log"
    else
      mark_skipped "exec:$script_rel" "requires passwordless sudo for non-interactive execution" "$RAW_DIR/${base}.exec.log"
    fi
  elif [ "$script_rel" = "scripts/validate-host.sh" ]; then
    if [ "$is_nixos_host" -eq 1 ] && [ "$sudo_noninteractive" -eq 0 ] && [ "$allow_interactive_sudo" != "1" ]; then
      mark_skipped "exec:$script_rel" "requires passwordless sudo for nixos-rebuild test" "$RAW_DIR/${base}.exec.log"
    else
      run_capture "exec:$script_rel" "$RAW_DIR/${base}.exec.log" bash "$script_path"
    fi
  else
    run_capture "exec:$script_rel" "$RAW_DIR/${base}.exec.log" bash "$script_path"
  fi

  exec_status="$(awk -F '\t' -v n="exec:$script_rel" '$1==n{print $2}' "$checks_tsv" | tail -n1)"
  if [ "$exec_status" = "fail" ]; then
    script_incons=$((script_incons + 1))
    notes+=("runtime check failed")
    note_finding "R-${base}-FAIL" "medium" "$script_rel" "$RAW_DIR/${base}.exec.log" \
      "Runtime execution failed, indicating drift or unmet assumptions." \
      "Review log evidence and decide whether to repair script or environment."
  elif [ "$exec_status" = "warn" ]; then
    script_incons=$((script_incons + 1))
    notes+=("runtime check reported warnings")
    note_finding "R-${base}-WARN" "low" "$script_rel" "$RAW_DIR/${base}.exec.log" \
      "Runtime execution completed with warnings, indicating partial drift." \
      "Inspect warnings and decide whether to tighten checks or accept documented exceptions."
  elif [ "$exec_status" = "skipped" ]; then
    skip_reason="$(sed -n 's/^SKIPPED: //p' "$RAW_DIR/${base}.exec.log" | head -n1)"
    if [ -z "$skip_reason" ]; then
      skip_reason="unspecified"
    fi
    notes+=("runtime check skipped: $skip_reason")
    if [ "$report_context_skips" = "1" ]; then
      note_finding "R-${base}-SKIP" "low" "$script_rel" "$RAW_DIR/${base}.exec.log" \
        "Runtime check could not run in current context." \
        "Re-run on target host/context to complete coverage."
      script_incons=$((script_incons + 1))
    fi
  fi

  script_status="ok"
  if [ "$script_incons" -gt 0 ]; then
    script_status="warn"
  fi
  if [ "$bashn_status" = "fail" ] || [ "$exec_status" = "fail" ]; then
    script_status="fail"
  fi

  if [ "${#notes[@]}" -eq 0 ]; then
    notes+=("no inconsistencies detected")
  fi

  joined_notes="$(printf '%s; ' "${notes[@]}")"
  joined_notes="${joined_notes%; }"
  printf '%s,%s,%s,%s,"%s"\n' \
    "$script_rel" "$script_status" "$(audit_class_for_script "$script_rel")" "$script_incons" "$joined_notes" >>"$matrix_file"
done

audit_write_summary_markdown \
  "$summary_file" \
  "$REPO_ROOT" \
  "$OUTPUT_DIR" \
  "$EXCLUDE_EMACS" \
  "$report_context_skips" \
  "$check_count" \
  "$check_pass" \
  "$check_warn" \
  "$check_fail" \
  "$check_skipped" \
  "$finding_count" \
  "$severity_high" \
  "$severity_medium" \
  "$severity_low" \
  "$findings_tsv"

audit_write_inconsistencies_markdown "$incons_file" "$findings_tsv"

if [ "$STRICT" -eq 1 ] && [ "$finding_count" -gt 0 ]; then
  echo "Audit completed with inconsistencies (strict mode)." >&2
  exit 1
fi

echo "Audit completed: $OUTPUT_DIR"
