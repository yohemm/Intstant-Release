#!/bin/bash

# ============================================================================
# TEST FRAMEWORK - Helpers and Assertions
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0


# 1️⃣ Charger paths EN PREMIER
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/paths.sh"

# 2️⃣ Sourcer logger
source "${LOGGER_SCRIPT}"

export AUDIT_LOG="${INSTANTRELEASE_ROOT}/tmp/test-audit-$$.log"
export DEBUG="${DEBUG:-false}"

# ============================================================================
# ASSERTION FUNCTIONS
# ============================================================================

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_matches_regex() {
    local pattern="$1"
    local value="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    if [[ "$value" =~ $pattern ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Pattern: $pattern"
        echo "  Value:   $value"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_exit_code() {
    local expected=$1
    local actual=$2
    local test_name="$3"
    
    ((TESTS_RUN++))
    if [[ $expected -eq $actual ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    if [[ -f "$file" ]] && grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Pattern not found in: $file"
        echo "  Looking for: $pattern"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  File not found: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ============================================================================
# SETUP & TEARDOWN
# ============================================================================

setup_temp_git_repo() {
    local repo_name="$1"
    local repo_dir="/tmp/test-repo-${repo_name}-$$"
    local git_dir="/tmp/test-git-${repo_name}-$$"
    
    rm -rf "$repo_dir"
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    export GIT_CONFIG_GLOBAL=/tmp/git-global-$$
    export GIT_CONFIG_SYSTEM=/tmp/git-system-$$
    export GIT_CEILING_DIRECTORIES="$repo_dir"
    export HOME="/tmp/test-home-$$"
    
    mkdir -p "$HOME"
    
    git init --initial-branch=main --separate-git-dir="$git_dir"
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    local git_root=$(git rev-parse --show-toplevel)
    
    if [[ "$git_root" != "$repo_dir" ]]; then
        echo "ERROR: Not in correct repo! Expected: $repo_dir, Got: $git_root" >&2
        cd /
        return 1
    fi
    
    echo "$repo_dir"
}

teardown_temp_git_repo() {
    local repo_dir="$1"
    local original_dir="${2:-.}"
    local repo_name=$(basename "$repo_dir" | sed "s/-[0-9]*$//")
    local pid="${repo_dir##*-}"
    
    # Nettoyer les exports
    unset GIT_CONFIG_GLOBAL
    unset GIT_CONFIG_SYSTEM
    unset GIT_CEILING_DIRECTORIES
    unset HOME
    
    cd "$original_dir"
    rm -rf "$repo_dir" \
           "/tmp/test-git-${repo_name}-${pid}" \
           "/tmp/.gitconfig-${pid}" \
           "/tmp/.gitconfig-sys-${pid}" \
           "/tmp/test-home-${pid}"
}

cleanup_all_tags() {
    # Nettoyer TOUS les tags v1.0.0 du repo principal
    git tag -d v1.0.0 2>/dev/null || true
    git tag -d v2.0.0 2>/dev/null || true
    git tag -d v0.1.0 2>/dev/null || true
}

# ============================================================================
# SUMMARY
# ============================================================================

print_test_summary() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║           TEST SUMMARY                     ║"
    echo "╚════════════════════════════════════════════╝"
    echo "Total:   $TESTS_RUN"
    echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ $TESTS_FAILED test(s) failed!${NC}"
        return 1
    fi
}