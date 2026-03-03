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
    printf 'D004\tAGENT.md\tMutable copy-once files can intentionally diverge\tParity checks must distinguish mutable drift from hard failures\tmedium\n'
    printf 'D005\tdocs/for-agents/003-multi-host-model.md\tShared scripts should avoid single-host hardcoding when not required\tAvoid fixed host/profile identifiers unless explicitly host-scoped\tmedium\n'
    printf 'D006\tdocs/for-agents/903-catppuccin-centralization-execution.md\tCatppuccin decisions are centralized and should remain consistent\tNo contradictory per-module catppuccin toggles outside central registry\tmedium\n'
    if [ "$exclude_emacs" -eq 1 ]; then
      printf 'D007\tdocs/for-agents/905-system-up-to-date-audit-plan.md\tEmacs checks excluded for this audit\tSkip emacs-specific findings\tlow\n'
    fi
  } >"$out_file"
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
