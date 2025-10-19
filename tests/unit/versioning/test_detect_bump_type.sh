#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"

# 2️⃣ Sourcer test helpers
source "${TEST_HELPERS}"

# 3️⃣ Sourcer les scripts à tester
source "${LOGGER_SCRIPT}"
source "${GIT_HELPERS_SCRIPT}"
source "${DETECT_BUMP_SCRIPT}"

# ============================================================================
# TEST 1: Detect MAJOR from BREAKING CHANGE
# ============================================================================

test_detect_major_breaking() {
    local original_dir=$(pwd)
    local repo=$(setup_temp_git_repo "major")
    local tag="v1.0.0-test-$RANDOM"
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag "$tag"
    
    echo "change" >> file.txt
    git add file.txt
    git commit -m "feat: new API
    
BREAKING CHANGE: removed old endpoint"
    
    local bump=$(detect_bump_type \
        --major-indicator "BREAKING CHANGE" \
        --minor-indicator "feat:" \
        --patch-indicator "fix:")
    
    assert_equals "major" "$bump" "Should detect MAJOR from BREAKING CHANGE"
    
    teardown_temp_git_repo "$repo" "$original_dir"
}

# ============================================================================
# TEST 2: Detect MINOR from feat:
# ============================================================================

test_detect_minor_feature() {
    local original_dir=$(pwd)
    local repo=$(setup_temp_git_repo "minor")
    local tag="v1.0.0-test-$RANDOM"
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag "$tag"
    
    echo "change" >> file.txt
    git add file.txt
    git commit -m "feat: add new feature"
    
    local bump=$(detect_bump_type \
        --major-indicator "BREAKING CHANGE" \
        --minor-indicator "feat:" \
        --patch-indicator "fix:")
    
    assert_equals "minor" "$bump" "Should detect MINOR from feat:"
    
    teardown_temp_git_repo "$repo" "$original_dir"
}

# ============================================================================
# TEST 3: Detect PATCH from fix:
# ============================================================================

test_detect_patch_fix() {
    local original_dir=$(pwd)
    local repo=$(setup_temp_git_repo "patch")
    local tag="v1.0.0-test-$RANDOM"
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag "$tag"
    
    echo "change" >> file.txt
    git add file.txt
    git commit -m "fix: resolve bug"
    
    local bump=$(detect_bump_type \
        --major-indicator "BREAKING CHANGE" \
        --minor-indicator "feat:" \
        --patch-indicator "fix:")
    
    assert_equals "patch" "$bump" "Should detect PATCH from fix:"
    
    teardown_temp_git_repo "$repo" "$original_dir"
}

# ============================================================================
# TEST 4: Priority: BREAKING > feat > fix
# ============================================================================

test_detect_priority() {
    local original_dir=$(pwd)
    local repo=$(setup_temp_git_repo "priority")
    local tag="v1.0.0-test-$RANDOM"
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag "$tag"
    
    echo "change1" >> file.txt
    git add file.txt
    git commit -m "fix: small fix"
    
    echo "change2" >> file.txt
    git add file.txt
    git commit -m "feat: new feature"
    
    echo "change3" >> file.txt
    git add file.txt
    git commit -m "refactor: reorganize code
    
BREAKING CHANGE: removed API"
    
    local bump=$(detect_bump_type \
        --major-indicator "BREAKING CHANGE" \
        --minor-indicator "feat:" \
        --patch-indicator "fix:")
    
    assert_equals "major" "$bump" "BREAKING CHANGE should take priority"
    
    teardown_temp_git_repo "$repo" "$original_dir"
}

# ============================================================================
# TEST 5: No commits = no bump
# ============================================================================

test_detect_no_bump() {
    local original_dir=$(pwd)
    local repo=$(setup_temp_git_repo "no-bump
    local tag="v1.0.0-test-$RANDOM"")
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag "$tag"
    
    local bump=$(detect_bump_type \
        --major-indicator "BREAKING CHANGE" \
        --minor-indicator "feat:" \
        --patch-indicator "fix:")
    
    assert_equals "none" "$bump" "Should detect NONE when no relevant commits"
    
    git tag -d "$tag" 2>/dev/null || true
    cd "$original_dir"
    teardown_temp_git_repo "$repo" "$original_dir"
}

# ============================================================================
# TEST 6: Custom indicators
# ============================================================================

test_detect_custom_indicators() {
    local original_dir=$(pwd)
    local repo=$(setup_temp_git_repo "auto")
    local tag="v1.0.0-test-$RANDOM"
    
    echo "initial" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    git tag "$tag"
    
    echo "change" >> file.txt
    git add file.txt
    git commit -m "[FEATURE] Custom feature indicator"
    
    # 🔑 CLEF: Skipper la config du projet
    local bump=$(SKIP_CONFIG=true detect_bump_type \
        --major-indicator "[BREAKING]" \
        --minor-indicator "[FEATURE]" \
        --patch-indicator "[FIX]")
    
    assert_equals "minor" "$bump" "Should work with custom indicators"
    
    cd "$original_dir"
    teardown_temp_git_repo "$repo" "$original_dir"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  UNIT TESTS: Detect Bump Type             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

test_detect_major_breaking
test_detect_minor_feature
test_detect_patch_fix
test_detect_priority
test_detect_no_bump
test_detect_custom_indicators

print_test_summary
exit $?