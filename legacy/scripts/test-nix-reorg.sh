#!/usr/bin/env bash
# NixOS Reorganization Test Script
# Tests that the Nix configuration is valid after reorganization
# Run this after each phase of the reorganization

set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

echo "======================================"
echo "NixOS Reorganization Test Script"
echo "======================================"
echo ""

HOME_USER_DIR="$(find home -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | head -n1)"
if [ -z "$HOME_USER_DIR" ]; then
    HOME_USER_DIR="user"
fi

# Test 1: Flake evaluation
echo "1. Testing flake evaluation..."
if nix flake check 2>&1 | grep -q "error:"; then
    print_result 1 "Flake has errors"
    echo "Run: nix flake check"
else
    print_result 0 "Flake evaluates cleanly"
fi

# Test 2: Check for broken imports
echo ""
echo "2. Checking for broken import paths..."
echo "   (Looking for files that reference 'files/' directory)"
BROKEN_REFS=$(grep -r "files/" home/ modules/ --include="*.nix" 2>/dev/null | grep -v "nix files" | wc -l)
if [ "$BROKEN_REFS" -gt 0 ]; then
    print_result 1 "Found $BROKEN_REFS references to 'files/' directory"
    grep -rn "files/" home/ modules/ --include="*.nix" 2>/dev/null | grep -v "nix files" | head -5
else
    print_result 0 "No broken 'files/' references found"
fi

# Test 3: Check home imports
echo ""
echo "3. Checking home/${HOME_USER_DIR} imports..."
if [ -f "home/${HOME_USER_DIR}/default.nix" ]; then
    # Extract imports and check if files exist (ignore comments)
    MISSING_IMPORTS=0
    for import in $(grep -oP '\s+\K[\./][a-z-]+' "home/${HOME_USER_DIR}/default.nix" 2>/dev/null | sort -u); do
        import_path="${import#\./}"
        if [ ! -d "home/${HOME_USER_DIR}/$import_path" ] && [ ! -f "home/${HOME_USER_DIR}/${import_path}.nix" ]; then
            echo "  Missing: $import_path"
            ((MISSING_IMPORTS++))
        fi
    done
    if [ "$MISSING_IMPORTS" -eq 0 ]; then
        print_result 0 "All home imports resolve"
    else
        print_result 1 "Missing $MISSING_IMPORTS import(s)"
    fi
else
    print_result 2 "home/${HOME_USER_DIR}/default.nix not found"
fi

# Test 4: Check Nix file formatting
echo ""
echo "4. Checking Nix file formatting..."
# Check formatting only on changed files
FMT_OUTPUT=$(nixpkgs-fmt --check home/${HOME_USER_DIR}/desktop/*.nix home/${HOME_USER_DIR}/programs/**/*.nix home/${HOME_USER_DIR}/services/*.nix modules/*.nix home/${HOME_USER_DIR}/apps/*.nix 2>&1)
# Extract the count of files that would be reformatted
REFORMAT_COUNT=$(echo "$FMT_OUTPUT" | grep -oP '^\d+(?= /)' || echo "0")
if [ "$REFORMAT_COUNT" -gt 0 ]; then
    print_result 1 "Some Nix files need formatting ($REFORMAT_COUNT files)"
    echo "$FMT_OUTPUT" | head -3
else
    print_result 0 "Nix files are properly formatted"
fi

# Test 5: Test build (dry run)
echo ""
echo "5. Testing nixos-rebuild test (dry run)..."
if sudo nixos-rebuild test --flake "path:$(pwd)#predator" --dry-run 2>&1 | tail -1 | grep -q "error:"; then
    print_result 1 "Dry run failed (check above for errors)"
else
    # This is a dry-run check - actual build in later phase
    print_result 0 "Dry-run check passed"
fi

# Summary
echo ""
echo "======================================"
echo "Test Summary"
echo "======================================"
echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Some tests failed. Please review above.${NC}"
    exit 1
fi
