#!/bin/bash


source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"

# 2️⃣ Sourcer test helpers
source "${TEST_HELPERS}"

# 3️⃣ Sourcer les scripts à tester
source "${LOGGER_SCRIPT}"
source "${GIT_HELPERS_SCRIPT}"
source "${CALCULATE_VERSION_SCRIPT}"
# ============================================================================
# TEST 1: Calculate version from bump type
# ============================================================================

test_calculate_major_bump() {
    local old_version="v1.2.3"
    local new_version=$(calculate_version "$old_version" "major")
    
    assert_equals "v2.0.0" "$new_version" "Should bump major version correctly"
}

test_calculate_minor_bump() {
    local old_version="v1.2.3"
    local new_version=$(calculate_version "$old_version" "minor")
    
    assert_equals "v1.3.0" "$new_version" "Should bump minor version correctly"
}

test_calculate_patch_bump() {
    local old_version="v1.2.3"
    local new_version=$(calculate_version "$old_version" "patch")
    
    assert_equals "v1.2.4" "$new_version" "Should bump patch version correctly"
}

test_calculate_no_bump() {
    local old_version="v1.2.3"
    local new_version=$(calculate_version "$old_version" "none")
    
    assert_equals "v1.2.3" "$new_version" "Should keep version unchanged on no bump"
}

test_calculate_with_prerelease() {
    local old_version="v1.2.3"
    local new_version=$(calculate_version "$old_version" "minor" "rc")
    
    assert_matches_regex "v1\.3\.0-rc\." "$new_version" "Should add prerelease suffix"
}

test_calculate_without_v_prefix() {
    local old_version="1.2.3"
    local new_version=$(calculate_version "$old_version" "patch")
    
    assert_equals "1.2.4" "$new_version" "Should handle versions without v prefix"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  UNIT TESTS: Calculate Version            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

test_calculate_major_bump
test_calculate_minor_bump
test_calculate_patch_bump
test_calculate_no_bump
test_calculate_with_prerelease
test_calculate_without_v_prefix

print_test_summary
exit $?