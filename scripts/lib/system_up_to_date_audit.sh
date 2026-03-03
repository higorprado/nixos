#!/usr/bin/env bash

audit_deps_for_script() {
  case "$1" in
    scripts/check-declarative-paths.sh) echo "rg" ;;
    scripts/check-dev-dotfiles-parity.sh) echo "find sort head git sed rg" ;;
    scripts/check-dotfiles-parity.sh) echo "find sort head rg sed" ;;
    scripts/check-flake-tracked.sh) echo "git rg cut" ;;
    scripts/check-logid-parity.sh) echo "diff cat" ;;
    scripts/check-nix-deprecations.sh) echo "rg" ;;
    scripts/check-nvim-contract.sh) echo "rg ps nvim pyright ruff lua-language-server vtsls node rust-analyzer lldb-dap" ;;
    scripts/check-repo-public-safety.sh) echo "rg grep mkdir mktemp wc cp id" ;;
    scripts/check-runtime-config-parity.sh) echo "cmp basename" ;;
    scripts/check-user-services-parity.sh) echo "rg readlink find sort" ;;
    scripts/nixos-post-switch-smoke.sh) echo "sudo nixos-rebuild id grep resolvectl systemctl command" ;;
    scripts/validate-host.sh) echo "nix sudo nixos-rebuild date hostname grep chmod" ;;
    *) echo "" ;;
  esac
}

audit_class_for_script() {
  case "$1" in
    scripts/check-dev-dotfiles-parity.sh|scripts/check-user-services-parity.sh|scripts/nixos-post-switch-smoke.sh)
      echo "move-private"
      ;;
    scripts/check-dotfiles-parity.sh|scripts/check-runtime-config-parity.sh|scripts/validate-host.sh)
      echo "repair"
      ;;
    *)
      echo "keep"
      ;;
  esac
}

audit_write_decision_baseline() {
  local out_file="$1"
  local exclude_emacs="$2"

  {
    printf 'decision_id\tsource_doc\trule\texpected_pattern\tseverity_if_broken\n'
    printf 'D001\tdocs/for-agents/009-private-ops-scripts.md\tRepo scripts should be shared/reproducible; personal ops scripts must stay private\tNo personal host identifiers or private backup endpoints in shared scripts\thigh\n'
    printf 'D002\tdocs/for-agents/006-validation-and-safety-gates.md\tFive Nix validation gates are mandatory after meaningful slices\tflake metadata + eval stateVersion + build home.path + build system.toplevel\thigh\n'
    printf 'D003\tdocs/for-agents/007-private-overrides-and-public-safety.md\tPublic safety gate must detect sensitive/path leakage\tNo unallowlisted local paths/private IP/personal email/tokens\thigh\n'
    printf 'D004\tAGENTS.md\tMutable copy-once files can intentionally diverge\tParity checks must distinguish mutable drift from hard failures\tmedium\n'
    printf 'D005\tdocs/for-agents/reference/003-multi-host-model.md\tShared scripts should avoid single-host hardcoding when not required\tAvoid fixed host/profile identifiers unless explicitly host-scoped\tmedium\n'
    printf 'D006\tdocs/for-agents/historical/903-catppuccin-centralization-execution.md\tCatppuccin decisions are centralized and should remain consistent\tNo contradictory per-module catppuccin toggles outside central registry\tmedium\n'
    if [ "$exclude_emacs" -eq 1 ]; then
      printf 'D007\tdocs/for-agents/plans/905-system-up-to-date-audit-plan.md\tEmacs checks excluded for this audit\tSkip emacs-specific findings\tlow\n'
    fi
  } >"$out_file"
}

audit_check_script_dependencies() {
  local script_rel="$1"
  local base="$2"
  local raw_dir="$3"
  local run_capture_fn="$4"
  local note_fn="$5"
  local script_incons_var="$6"
  local notes_var="$7"
  local deps_log missing_deps dep
  local -n script_incons_ref="$script_incons_var"
  # shellcheck disable=SC2178
  local -n notes_ref="$notes_var"

  deps_log="$raw_dir/${base}.deps.log"
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
    "$run_capture_fn" "deps:$script_rel" "$raw_dir/${base}.deps-status.log" false
    script_incons_ref=$((script_incons_ref + 1))
    notes_ref+=("missing dependencies")
    "$note_fn" "S-DEPS-$base" "medium" "$script_rel" "$deps_log" \
      "Script requires commands that are not currently available in PATH." \
      "Install missing dependencies or gate the script with preflight checks."
  else
    "$run_capture_fn" "deps:$script_rel" "$raw_dir/${base}.deps-status.log" true
  fi
}

audit_apply_policy_checks() {
  local script_rel="$1"
  local script_path="$2"
  local base="$3"
  local raw_dir="$4"
  local note_fn="$5"
  local script_incons_var="$6"
  local notes_var="$7"
  local -n script_incons_ref="$script_incons_var"
  # shellcheck disable=SC2178
  local -n notes_ref="$notes_var"

  case "$script_rel" in
    scripts/check-dev-dotfiles-parity.sh)
      if rg -n 'cerebelo|\.ssh/config|\.gitconfig' "$script_path" >"$raw_dir/${base}.policy-scan.log" 2>&1; then
        script_incons_ref=$((script_incons_ref + 1))
        notes_ref+=("contains personal host/dotfile assumptions")
        "$note_fn" "P001" "high" "$script_rel" "$raw_dir/${base}.policy-scan.log" \
          "Shared repo script encodes personal host/dotfile assumptions, conflicting with private-ops boundary." \
          "Move host-personal checks to private scripts or parameterize them."
      fi
      ;;
    scripts/check-user-services-parity.sh)
      if rg -n 'backup-restic-cerebelo|backup-rsync-cerebelo' "$script_path" >"$raw_dir/${base}.policy-scan.log" 2>&1; then
        script_incons_ref=$((script_incons_ref + 1))
        notes_ref+=("contains private backup service assumptions")
        "$note_fn" "P002" "high" "$script_rel" "$raw_dir/${base}.policy-scan.log" \
          "Shared script hardcodes private backup units tied to personal endpoint naming." \
          "Move this unit policy to private ops or externalize unit list through config."
      fi
      ;;
    scripts/nixos-post-switch-smoke.sh)
      if rg -n 'backup-restic-cerebelo|backup-rsync-cerebelo|claude|crush' "$script_path" >"$raw_dir/${base}.policy-scan.log" 2>&1; then
        script_incons_ref=$((script_incons_ref + 1))
        notes_ref+=("contains personal app and backup assumptions")
        "$note_fn" "P003" "medium" "$script_rel" "$raw_dir/${base}.policy-scan.log" \
          "Smoke script mixes shared checks with personal app and backup-specific assertions." \
          "Split shared smoke checks from private workstation checks."
      fi
      ;;
    scripts/check-dotfiles-parity.sh)
      if rg -n '"\$repo_root/home/\$home_user_dir"/\*\.nix' "$script_path" >"$raw_dir/${base}.policy-scan.log" 2>&1; then
        script_incons_ref=$((script_incons_ref + 1))
        notes_ref+=("top-level-only nix scan may miss nested declarations")
        "$note_fn" "P004" "medium" "$script_rel" "$raw_dir/${base}.policy-scan.log" \
          "Dotfiles parity scanner only reads top-level user nix files and can miss nested module declarations." \
          "Use recursive scan across home/<user>/**/*.nix for managed file discovery."
      fi
      ;;
    scripts/check-runtime-config-parity.sh)
      if rg -n 'check_pair .*/dms/settings\.json|check_pair .*/keyrs/config\.toml' "$script_path" >"$raw_dir/${base}.policy-scan.log" 2>&1 \
        && ! rg -q 'strict_mutable|mutable content drift|mode="\$3"' "$script_path"; then
        script_incons_ref=$((script_incons_ref + 1))
        notes_ref+=("strict runtime parity against mutable-copy targets")
        "$note_fn" "P005" "medium" "$script_rel" "$raw_dir/${base}.policy-scan.log" \
          "Runtime parity marks mutable copy-once files as hard failures, conflicting with mutable-config caveat." \
          "Classify known mutable targets as warn/drift instead of strict fail."
      fi
      ;;
    scripts/validate-host.sh)
      if rg -n 'flake_ref=.*#predator' "$script_path" >"$raw_dir/${base}.policy-scan.log" 2>&1; then
        script_incons_ref=$((script_incons_ref + 1))
        notes_ref+=("hardcoded host flake target")
        "$note_fn" "P006" "low" "$script_rel" "$raw_dir/${base}.policy-scan.log" \
          "Validation script is tied to one host target and is less portable across multi-host setups." \
          "Accept host as argument or environment variable."
      fi
      ;;
  esac
}

audit_run_script_exec_check() {
  local script_rel="$1"
  local script_path="$2"
  local base="$3"
  local raw_dir="$4"
  local is_nixos_host="$5"
  local sudo_noninteractive="$6"
  local allow_interactive_sudo="$7"
  local run_capture_fn="$8"
  local mark_skipped_fn="$9"
  local checks_tsv="${10}"
  local note_fn="${11}"
  local report_context_skips="${12}"
  local script_incons_var="${13}"
  local notes_var="${14}"
  local exec_status skip_reason
  local -n script_incons_ref="$script_incons_var"
  # shellcheck disable=SC2178
  local -n notes_ref="$notes_var"

  if [ "$script_rel" = "scripts/nixos-post-switch-smoke.sh" ]; then
    if [ "$is_nixos_host" -eq 1 ] && [ "$sudo_noninteractive" -eq 1 ]; then
      "$run_capture_fn" "exec:$script_rel" "$raw_dir/${base}.exec.log" bash "$script_path"
    elif [ "$is_nixos_host" -eq 1 ] && [ "$allow_interactive_sudo" = "1" ]; then
      "$run_capture_fn" "exec:$script_rel" "$raw_dir/${base}.exec.log" bash "$script_path"
    elif [ "$is_nixos_host" -eq 0 ]; then
      "$mark_skipped_fn" "exec:$script_rel" "not running on NixOS host" "$raw_dir/${base}.exec.log"
    else
      "$mark_skipped_fn" "exec:$script_rel" "requires passwordless sudo for non-interactive execution" "$raw_dir/${base}.exec.log"
    fi
  elif [ "$script_rel" = "scripts/validate-host.sh" ]; then
    if [ "$is_nixos_host" -eq 1 ] && [ "$sudo_noninteractive" -eq 0 ] && [ "$allow_interactive_sudo" != "1" ]; then
      "$mark_skipped_fn" "exec:$script_rel" "requires passwordless sudo for nixos-rebuild test" "$raw_dir/${base}.exec.log"
    else
      "$run_capture_fn" "exec:$script_rel" "$raw_dir/${base}.exec.log" bash "$script_path"
    fi
  else
    "$run_capture_fn" "exec:$script_rel" "$raw_dir/${base}.exec.log" bash "$script_path"
  fi

  exec_status="$(awk -F '\t' -v n="exec:$script_rel" '$1==n{print $2}' "$checks_tsv" | tail -n1)"
  if [ "$exec_status" = "fail" ]; then
    script_incons_ref=$((script_incons_ref + 1))
    notes_ref+=("runtime check failed")
    "$note_fn" "R-${base}-FAIL" "medium" "$script_rel" "$raw_dir/${base}.exec.log" \
      "Runtime execution failed, indicating drift or unmet assumptions." \
      "Review log evidence and decide whether to repair script or environment."
  elif [ "$exec_status" = "warn" ]; then
    script_incons_ref=$((script_incons_ref + 1))
    notes_ref+=("runtime check reported warnings")
    "$note_fn" "R-${base}-WARN" "low" "$script_rel" "$raw_dir/${base}.exec.log" \
      "Runtime execution completed with warnings, indicating partial drift." \
      "Inspect warnings and decide whether to tighten checks or accept documented exceptions."
  elif [ "$exec_status" = "skipped" ]; then
    skip_reason="$(sed -n 's/^SKIPPED: //p' "$raw_dir/${base}.exec.log" | head -n1)"
    if [ -z "$skip_reason" ]; then
      skip_reason="unspecified"
    fi
    notes_ref+=("runtime check skipped: $skip_reason")
    if [ "$report_context_skips" = "1" ]; then
      "$note_fn" "R-${base}-SKIP" "low" "$script_rel" "$raw_dir/${base}.exec.log" \
        "Runtime check could not run in current context." \
        "Re-run on target host/context to complete coverage."
      script_incons_ref=$((script_incons_ref + 1))
    fi
  fi
}

audit_write_summary_markdown() {
  local summary_file="$1"
  local repo_root="$2"
  local output_dir="$3"
  local exclude_emacs="$4"
  local report_context_skips="$5"
  local check_count="$6"
  local check_pass="$7"
  local check_warn="$8"
  local check_fail="$9"
  local check_skipped="${10}"
  local finding_count="${11}"
  local severity_high="${12}"
  local severity_medium="${13}"
  local severity_low="${14}"
  local findings_tsv="${15}"

  {
    printf '# System Up-To-Date Audit Summary\n\n'
    printf '## Context\n'
    printf "1. Repo: \`%s\`\n" "$repo_root"
    printf "2. Output: \`%s\`\n" "$output_dir"
    printf "3. Emacs excluded: \`%s\`\n" "$( [ "$exclude_emacs" -eq 1 ] && echo yes || echo no )"
    printf "4. Report context skips: \`%s\`\n" "$( [ "$report_context_skips" = "1" ] && echo yes || echo no )"
    printf '\n## Check Totals\n'
    printf "1. Total checks: \`%s\`\n" "$check_count"
    printf "2. Pass: \`%s\`\n" "$check_pass"
    printf "3. Warn: \`%s\`\n" "$check_warn"
    printf "4. Fail: \`%s\`\n" "$check_fail"
    printf "5. Skipped: \`%s\`\n" "$check_skipped"
    printf '\n## Findings Totals\n'
    printf "1. Total inconsistencies: \`%s\`\n" "$finding_count"
    printf "2. High: \`%s\`\n" "$severity_high"
    printf "3. Medium: \`%s\`\n" "$severity_medium"
    printf "4. Low: \`%s\`\n" "$severity_low"
    printf '\n## Verdict\n'
    if [ "$check_fail" -gt 0 ] || [ "$severity_high" -gt 0 ]; then
      printf 'FAIL\n'
    elif [ "$finding_count" -gt 0 ] || [ "$check_warn" -gt 0 ] || { [ "$report_context_skips" = "1" ] && [ "$check_skipped" -gt 0 ]; }; then
      printf 'PASS_WITH_WARNINGS\n'
    else
      printf 'PASS\n'
    fi
    printf '\n## Top Blockers\n'
    if [ "$finding_count" -eq 0 ]; then
      printf '1. None\n'
    else
      awk -F '\t' 'NR>1{print $1"\t"$2"\t"$3"\t"$4"\t"$5}' "$findings_tsv" \
        | awk -F '\t' '$2=="high"' \
        | head -n 5 \
        | nl -w1 -s'. ' \
        | sed 's/\t/ | /g'
      if ! awk -F '\t' 'NR>1 && $2=="high"{exit 1}' "$findings_tsv"; then
        :
      else
        printf '1. No high-severity blockers found.\n'
      fi
    fi
  } >"$summary_file"
}

audit_write_inconsistencies_markdown() {
  local inconsistencies_file="$1"
  local findings_tsv="$2"

  {
    printf '# Inconsistencies Report\n\n'
    printf 'Each finding includes: id, severity, location, evidence, why inconsistent, recommended action.\n\n'

    printf '## Policy mismatches\n'
    if awk -F '\t' 'NR>1 && $1 ~ /^P/{found=1} END{exit(found?0:1)}' "$findings_tsv"; then
      awk -F '\t' 'NR>1 && $1 ~ /^P/ {print $0}' "$findings_tsv" | while IFS=$'\t' read -r id sev loc ev why act; do
        printf "1. \`%s\` | \`%s\` | \`%s\`\n" "$id" "$sev" "$loc"
        printf "   - evidence: \`%s\`\n" "$ev"
        printf '   - why_inconsistent: %s\n' "$why"
        printf '   - recommended_action: %s\n' "$act"
      done
    else
      printf '1. None\n'
    fi

    printf '\n## Outdated assumptions\n'
    if awk -F '\t' 'NR>1 && ($1=="P004" || $1=="P006"){found=1} END{exit(found?0:1)}' "$findings_tsv"; then
      awk -F '\t' 'NR>1 && ($1=="P004" || $1=="P006") {print $0}' "$findings_tsv" | while IFS=$'\t' read -r id sev loc ev why act; do
        printf "1. \`%s\` | \`%s\` | \`%s\`\n" "$id" "$sev" "$loc"
        printf "   - evidence: \`%s\`\n" "$ev"
        printf '   - why_inconsistent: %s\n' "$why"
        printf '   - recommended_action: %s\n' "$act"
      done
    else
      printf '1. None\n'
    fi

    printf '\n## Private-boundary violations\n'
    if awk -F '\t' 'NR>1 && ($1=="P001" || $1=="P002" || $1=="P003"){found=1} END{exit(found?0:1)}' "$findings_tsv"; then
      awk -F '\t' 'NR>1 && ($1=="P001" || $1=="P002" || $1=="P003") {print $0}' "$findings_tsv" | while IFS=$'\t' read -r id sev loc ev why act; do
        printf "1. \`%s\` | \`%s\` | \`%s\`\n" "$id" "$sev" "$loc"
        printf "   - evidence: \`%s\`\n" "$ev"
        printf '   - why_inconsistent: %s\n' "$why"
        printf '   - recommended_action: %s\n' "$act"
      done
    else
      printf '1. None\n'
    fi

    printf '\n## Runtime parity drift\n'
    if awk -F '\t' 'NR>1 && $1 ~ /^R-.*-(FAIL|WARN)$/ {found=1} END{exit(found?0:1)}' "$findings_tsv"; then
      awk -F '\t' 'NR>1 && $1 ~ /^R-.*-(FAIL|WARN)$/ {print $0}' "$findings_tsv" | while IFS=$'\t' read -r id sev loc ev why act; do
        printf "1. \`%s\` | \`%s\` | \`%s\`\n" "$id" "$sev" "$loc"
        printf "   - evidence: \`%s\`\n" "$ev"
        printf '   - why_inconsistent: %s\n' "$why"
        printf '   - recommended_action: %s\n' "$act"
      done
    else
      printf '1. None\n'
    fi

    printf '\n## Skipped checks\n'
    if awk -F '\t' 'NR>1 && $1 ~ /^R-.*-SKIP$/ {found=1} END{exit(found?0:1)}' "$findings_tsv"; then
      awk -F '\t' 'NR>1 && $1 ~ /^R-.*-SKIP$/ {print $0}' "$findings_tsv" | while IFS=$'\t' read -r id sev loc ev why act; do
        printf "1. \`%s\` | \`%s\` | \`%s\`\n" "$id" "$sev" "$loc"
        printf "   - evidence: \`%s\`\n" "$ev"
        printf '   - why_inconsistent: %s\n' "$why"
        printf '   - recommended_action: %s\n' "$act"
      done
    else
      printf '1. None\n'
    fi
  } >"$inconsistencies_file"
}
