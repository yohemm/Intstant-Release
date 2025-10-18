#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"
source "${TEST_HELPERS}"
source "${LOGGER_SCRIPT}"
source "${VALIDATORS_SCRIPT}"

# ============================================================================
# TEST 1: Validate semver - valid versions
# ============================================================================

test_validate_semver_valid() {
    local versions=("v1.0.0" "1.0.0" "v0.1.0" "2.3.4")
    
    for version in "${versions[@]}"; do
        if validate_semver "$version" >/dev/null 2>&1; then
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗${NC} Should validate: $version"
            ((TESTS_FAILED++))
        fi
        ((TESTS_RUN++))
    done
    
    echo -e "${GREEN}✓${NC} Semver validation accepts valid versions"
}

# ============================================================================
# TEST 2: Validate semver - invalid versions
# ============================================================================

test_validate_semver_invalid() {
    local versions=("1.0" "v1" "not-a-version" "1.0.0.0")
    
    for version in "${versions[@]}"; do
        if ! validate_semver "$version" >/dev/null 2>&1; then
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗${NC} Should reject: $version"
            ((TESTS_FAILED++))
        fi
        ((TESTS_RUN++))
    done
    
    echo -e "${GREEN}✓${NC} Semver validation rejects invalid versions"
}

# ============================================================================
# TEST 3: Validate git repo
# ============================================================================

test_validate_git_repo() {
    local repo=$(setup_temp_git_repo "validator")
    
    if validate_git_repo >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Validates git repository"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Should validate git repo"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    cd - > /dev/null
    teardown_temp_git_repo "$repo"
}

# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  UNIT TESTS: Validators                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

test_validate_semver_valid
test_validate_semver_invalid
test_validate_git_repo

print_test_summary
exit $?