#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"
source "${TEST_HELPERS}"
source "${LOGGER_SCRIPT}"
source "${GIT_HELPERS_SCRIPT}"

# ============================================================================
# TEST 1: git_config_user
# ============================================================================

test_git_config_user() {
    local repo=$(setup_temp_git_repo "git-config")
    
    git_config_user "TestBot" "test@example.com" >/dev/null 2>&1
    
    local user_name=$(git config user.name)
    local user_email=$(git config user.email)
    
    if [[ "$user_name" == "TestBot" ]] && [[ "$user_email" == "test@example.com" ]]; then
        echo -e "${GREEN}✓${NC} Git user configured correctly"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Git user not configured"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    cd - > /dev/null
    teardown_temp_git_repo "$repo"
}

# ============================================================================
# TEST 2: git_get_last_tag
# ============================================================================

test_git_get_last_tag() {
    local repo=$(setup_temp_git_repo "git-tag")
    
    echo "test" > file.txt
    git add file.txt
    git commit -m "Test" >/dev/null 2>&1
    git tag v1.0.0 >/dev/null 2>&1
    
    local tag=$(git_get_last_tag)
    
    if [[ "$tag" == "v1.0.0" ]]; then
        echo -e "${GREEN}✓${NC} Retrieved last tag correctly"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Should retrieve v1.0.0, got: $tag"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    cd - > /dev/null
    teardown_temp_git_repo "$repo"
}

# ============================================================================
# TEST 3: git_tag_exists
# ============================================================================

test_git_tag_exists() {
    local repo=$(setup_temp_git_repo "git-exists")
    
    echo "test" > file.txt
    git add file.txt
    git commit -m "Test" >/dev/null 2>&1
    git tag v1.0.0 >/dev/null 2>&1
    
    if git_tag_exists "v1.0.0" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Tag exists check passed"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Should find existing tag"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    if ! git_tag_exists "nonexistent" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Tag not found check passed"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Should not find nonexistent tag"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    cd - > /dev/null
    teardown_temp_git_repo "$repo"
}

# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  UNIT TESTS: Git Helpers                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

test_git_config_user
test_git_get_last_tag
test_git_tag_exists

print_test_summary
exit $?