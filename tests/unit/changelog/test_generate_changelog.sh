#!/bin/bash

# 1️⃣ Charger paths
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"

# 2️⃣ Sourcer ce dont on a besoin
source "${TEST_HELPERS}"
source "${LOGGER_SCRIPT}"
source "${GIT_HELPERS_SCRIPT}"

# ============================================================================
# TEST 1: Generate basic changelog
# ============================================================================

test_generate_basic_changelog() {
    local repo=$(setup_temp_git_repo "changelog-basic")
    local changelog="$repo/CHANGELOG.md"
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag v1.0.0
    
    echo "feature" >> file.txt
    git add file.txt
    git commit -m "feat: add new feature"
    
    # Simulate changelog generation
    local commits=$(git_get_commits_since_tag "v1.0.0")
    
    if echo "$commits" | grep -q "feat: add new feature"; then
        echo -e "${GREEN}✓${NC} Changelog entries found"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Changelog entries not found"
        ((TESTS_FAILED++))
    fi
    
    teardown_temp_git_repo "$repo"
}

# ============================================================================
# TEST 2: Categorize commits in changelog
# ============================================================================

test_categorize_commits() {
    local repo=$(setup_temp_git_repo "changelog-categories")
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag v1.0.0
    
    # Add various commits
    echo "1" >> file.txt
    git add file.txt
    git commit -m "feat: add feature"
    
    echo "2" >> file.txt
    git add file.txt
    git commit -m "fix: resolve bug"
    
    echo "3" >> file.txt
    git add file.txt
    git commit -m "docs: update readme"
    
    local commits=$(git_get_commits_since_tag "v1.0.0")
    
    local has_feature=false
    local has_fix=false
    
    if echo "$commits" | grep -q "feat:"; then
        has_feature=true
    fi
    
    if echo "$commits" | grep -q "fix:"; then
        has_fix=true
    fi
    
    if [[ "$has_feature" == "true" ]] && [[ "$has_fix" == "true" ]]; then
        echo -e "${GREEN}✓${NC} Commits categorized correctly"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Commit categorization failed"
        ((TESTS_FAILED++))
    fi
    
    teardown_temp_git_repo "$repo"
}

# ============================================================================
# TEST 3: Include breaking changes
# ============================================================================

test_breaking_changes_in_changelog() {
    local repo=$(setup_temp_git_repo "changelog-breaking")
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag v1.0.0
    
    echo "breaking" >> file.txt
    git add file.txt
    git commit -m "feat: redesign API

BREAKING CHANGE: removed v1 endpoints"
    
    local commits=$(git_get_commits_since_tag "v1.0.0")
    
    if echo "$commits" | grep -q "BREAKING CHANGE"; then
        echo -e "${GREEN}✓${NC} Breaking changes detected"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Breaking changes not detected"
        ((TESTS_FAILED++))
    fi
    
    teardown_temp_git_repo "$repo"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  UNIT TESTS: Generate Changelog           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_generate_basic_changelog
test_categorize_commits
test_breaking_changes_in_changelog

print_test_summary
exit $?