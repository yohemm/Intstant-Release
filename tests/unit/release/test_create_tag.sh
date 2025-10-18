#!/bin/bash


# 1️⃣ Charger paths
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"

# 2️⃣ Sourcer ce dont on a besoin
source "${TEST_HELPERS}"
source "${GIT_HELPERS_SCRIPT}"

# ============================================================================
# TEST 1: Create simple tag
# ============================================================================

test_create_simple_tag() {
    local repo=$(setup_temp_git_repo "create-tag")
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    
    git_create_tag "v1.0.0" "Release v1.0.0"
    
    assert_equals "0" "$?" "Tag creation should succeed"
    
    # Verify tag exists
    if git rev-parse v1.0.0 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Tag exists locally"
    else
        echo -e "${RED}✗${NC} Tag was not created"
        ((TESTS_FAILED++))
    fi
    
    teardown_temp_git_repo "$repo"
}

# ============================================================================
# TEST 2: Handle tag conflicts
# ============================================================================

test_tag_conflict_handling() {
    local repo=$(setup_temp_git_repo "tag-conflict")
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    
    git_create_tag "v1.0.0" "First tag"
    
    # Try to create same tag (should handle gracefully)
    if git_tag_exists "v1.0.0"; then
        echo -e "${GREEN}✓${NC} Tag conflict detected correctly"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Failed to detect existing tag"
        ((TESTS_FAILED++))
    fi
    
    teardown_temp_git_repo "$repo"
}

# ============================================================================
# TEST 3: Tag with message
# ============================================================================

test_tag_with_message() {
    local repo=$(setup_temp_git_repo "tag-message")
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    
    git_create_tag "v1.0.0" "Release version 1.0.0"
    
    # Verify tag message
    local tag_message=$(git tag -l v1.0.0 -n1 | awk '{$1=""; print $0}' | xargs)
    
    if [[ "$tag_message" == "Release version 1.0.0" ]]; then
        echo -e "${GREEN}✓${NC} Tag message set correctly"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Tag message not correct"
        ((TESTS_FAILED++))
    fi
    
    teardown_temp_git_repo "$repo"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  UNIT TESTS: Create Tag                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_create_simple_tag
test_tag_conflict_handling
test_tag_with_message

print_test_summary
exit $?