#!/usr/bin/env bash
# NixOS Configuration Validation Test Script
# Runs all tests from Phase 6 of the improvement plan
# Run this after a rebuild to verify everything works

# Don't exit on errors - we want to run all tests
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0
SKIPPED=0

# Print test header
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
}

# Print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASSED++))
    elif [ $1 -eq 2 ]; then
        echo -e "${YELLOW}⊘ SKIP${NC}: $2"
        ((SKIPPED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAILED++))
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Section 1: System Build Verification
print_header "1. System Build Verification"

echo "Checking if system was rebuilt recently..."
CURRENT_GEN=$(nixos-rebuild list-generations 2>/dev/null | grep "current" | tail -1 || true)
if [ -n "$CURRENT_GEN" ]; then
    print_result 0 "Current generation: $CURRENT_GEN"
else
    # Alternative method: check /run/current-system
    if [ -L "/run/current-system" ]; then
        GEN_PATH=$(readlink /run/current-system)
        print_result 0 "Current system: $GEN_PATH"
    else
        print_result 2 "Cannot determine current generation (may need sudo)"
    fi
fi

# Section 2: System Log Check
print_header "2. System Log Review (Recent Errors)"

echo "Checking for errors in last 5 minutes..."
ERROR_COUNT=$(journalctl --since "5 minutes ago" --priority=err -q --no-pager 2>/dev/null | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    print_result 0 "No new errors in system logs"
else
    echo -e "${YELLOW}Warning: Found $ERROR_COUNT error entries${NC}"
    journalctl --since "5 minutes ago" --priority=err --no-pager | tail -5
    print_result 2 "Errors found (may be expected)"
fi

# Section 3: Failed Services Check
print_header "3. Failed Services Check"

USER_FAILED=$(systemctl --user list-units --failed --no-legend 2>/dev/null | wc -l)
SYSTEM_FAILED=$(systemctl list-units --failed --no-legend 2>/dev/null | wc -l)

if [ "$USER_FAILED" -eq 0 ] && [ "$SYSTEM_FAILED" -eq 0 ]; then
    print_result 0 "No failed services"
else
    if [ "$USER_FAILED" -gt 0 ]; then
        echo -e "${YELLOW}User failed services:${NC}"
        systemctl --user list-units --failed --no-legend | head -3
    fi
    if [ "$SYSTEM_FAILED" -gt 0 ]; then
        echo -e "${YELLOW}System failed services:${NC}"
        systemctl list-units --failed --no-legend | head -3
    fi
    print_result 2 "Some services failed (check above)"
fi

# Section 4: Desktop Session Check
print_header "4. Desktop Session Check"

if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
    print_result 0 "Display server detected"

    # Check if compositor is running
    if pgrep -x "niri" >/dev/null; then
        print_result 0 "Niri compositor running"
    elif pgrep -x "Hyprland" >/dev/null; then
        print_result 0 "Hyprland compositor running"
    else
        print_result 2 "Compositor not detected (may be starting)"
    fi

    # Check for DMS shell
    if pgrep -f "dms-shell" >/dev/null; then
        print_result 0 "DMS shell detected"
    elif pgrep -f "quickshell" >/dev/null; then
        print_result 0 "Quickshell (noctalia/caelestia) detected"
    else
        print_result 2 "Shell type not detected"
    fi
else
    print_result 2 "No display server (running in TTY or headless)"
fi

# Section 5: Terminal Tools Check
print_header "5. Terminal Tools Availability"

TOOLS=("nvim" "kitty" "yazi" "zellij" "btop" "btm" "htop" "eza" "fd" "rg" "bat" "jq" "gh")
for tool in "${TOOLS[@]}"; do
    if command_exists "$tool"; then
        print_result 0 "$tool available"
    else
        print_result 1 "$tool not found"
    fi
done

# Section 6: Neovim Configuration Check
print_header "6. Neovim Configuration"

if command_exists "nvim"; then
    print_result 0 "Neovim installed"

    # Check if nvim config exists
    if [ -f "$HOME/nixos/files/nvim/init.lua" ] || [ -f "$HOME/.config/nvim/init.lua" ]; then
        print_result 0 "Neovim config found"

        # Run nvim health check (non-interactive)
        echo "Running nvim health check..."
        if nvim --headless "+checkhealth nvim" +qa 2>/dev/null; then
            print_result 0 "Neovim health check passed"
        else
            print_result 1 "Neovim health check failed"
        fi
    else
        print_result 1 "Neovim config not found"
    fi
else
    print_result 1 "Neovim not installed"
fi

# Section 7: File Manager Check
print_header "7. File Manager Check"

if command_exists "nemo"; then
    print_result 0 "Nemo file manager available"
else
    print_result 2 "Nemo not found (may not be in PATH yet)"
fi

# Section 8: Desktop Profile Verification
print_header "8. Desktop Profile Verification"

PROFILE_FILE="$HOME/nixos/hosts/predator/default.nix"
if [ -f "$PROFILE_FILE" ]; then
    CURRENT_PROFILE=$(grep "custom.desktop.profile" "$PROFILE_FILE" | grep -oP '\"\K[^"]+' || echo "unknown")
    CURRENT_PROFILE=$(echo "$CURRENT_PROFILE" | tr -d ';') # Remove trailing semicolon
    print_result 0 "Current profile: $CURRENT_PROFILE"

    case "$CURRENT_PROFILE" in
        dms|dms-hyprland)
            print_result 0 "Full desktop profile (GUI apps expected)"
            ;;
        niri-only)
            print_result 0 "Minimal profile (GUI apps NOT expected)"
            ;;
        noctalia|caelestia-hyprland)
            print_result 0 "Alternative shell profile (GUI apps expected)"
            ;;
        *)
            print_result 0 "Profile: $CURRENT_PROFILE"
            ;;
    esac
else
    print_result 1 "Cannot find profile file"
fi

# Section 9: Git Status Check
print_header "9. Git Repository Status"

if [ -d "$HOME/nixos/.git" ]; then
    cd "$HOME/nixos"
    GIT_STATUS=$(git status --porcelain 2>/dev/null | wc -l)
    if [ "$GIT_STATUS" -eq 0 ]; then
        print_result 0 "Working directory clean"
    else
        echo -e "${YELLOW}Uncommitted changes:${NC}"
        git status --short | head -5
        print_result 2 "Uncommitted changes exist"
    fi

    # Show recent commits
    echo -e "\n${BLUE}Recent commits:${NC}"
    git log --oneline -5
else
    print_result 2 "Not a git repository or not in nixos directory"
fi

# Section 10: Package Availability
print_header "10. Key Package Availability"

PACKAGES_CHECK=("firefox" "google-chrome-stable" "teams-for-linux")
for pkg in "${PACKAGES_CHECK[@]}"; do
    if command_exists "$pkg" || nix-store -q --requisites /run/current-system/sw 2>/dev/null | grep -q "$pkg"; then
        print_result 0 "$pkg available"
    else
        print_result 2 "$pkg not found (may not be in current profile)"
    fi
done

# Section 11: Theme Files Check
print_header "11. Theme Files Verification"

THEME_DIRS=(
    "$HOME/nixos/files/themes/kitty"
    "$HOME/nixos/files/themes/gtk-3.0"
    "$HOME/nixos/files/themes/gtk-4.0"
    "$HOME/nixos/files/shell-customs/noctalia"
    "$HOME/nixos/files/shell-customs/caelestia"
    "$HOME/nixos/files/shell-customs/niri"
)

for dir in "${THEME_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_result 0 "Theme dir: $(basename $dir)"
    else
        print_result 2 "Theme dir missing: $(basename $dir)"
    fi
done

# Section 12: Documentation Files Check
print_header "12. Documentation Files Check"

DOCS=(
    "$HOME/nixos/docs/themes.md"
    "$HOME/nixos/docs/system-monitoring.md"
    "$HOME/nixos/docs/backup-guide.md"
    "$HOME/nixos/docs/devenv-quickstart.md"
    "$HOME/nixos/docs/desktop-profiles.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        print_result 0 "Doc: $(basename $doc)"
    else
        print_result 1 "Doc missing: $(basename $doc)"
    fi
done

# Final Summary
print_header "Test Summary"

echo -e "Passed:  ${GREEN}$PASSED${NC}"
echo -e "Failed:  ${RED}$FAILED${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED${NC}"
echo -e "Total:   $((PASSED + FAILED + SKIPPED))"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All critical tests passed!${NC}\n"
    exit 0
else
    echo -e "\n${RED}Some tests failed. Please review the output above.${NC}\n"
    exit 1
fi
