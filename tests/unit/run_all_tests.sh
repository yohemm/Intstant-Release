#!/bin/bash

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Export for use in scripts
export PROJECT_ROOT
export DEBUG="${DEBUG:-false}"
export DRY_RUN="${DRY_RUN:-false}"

test_suites=(
    "tests/unit/lib/test_logger.sh"
    "tests/unit/lib/test_validators.sh"
    "tests/unit/lib/test_git_helpers.sh"
    "tests/unit/versioning/test_detect_bump_type.sh"
    "tests/unit/versioning/test_calculate_version.sh"
    "tests/unit/changelog/test_generate_changelog.sh"
    "tests/unit/release/test_create_tag.sh"
)

run_test_suite() {
    local suite="$1"
    
    if [[ ! -f "$suite" ]]; then
        echo -e "${RED}✗ Test file not found: $suite${NC}"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    bash "$suite"
}

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  UNIT TEST SUITE - MVP TDD                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    
    local failed_suites=()
    
    for suite in "${test_suites[@]}"; do
        echo -e "${BLUE}Running: $(basename "$suite")${NC}"
        
        if run_test_suite "$suite"; then
            echo -e "${GREEN}✓ Passed${NC}"
        else
            echo -e "${RED}✗ Failed${NC}"
            failed_suites+=("$suite")
        fi
        echo ""
    done
    
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  FINAL SUMMARY                             ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    
    if [[ ${#failed_suites[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓ All test suites passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed suites:${NC}"
        for suite in "${failed_suites[@]}"; do
            echo "  - $suite"
        done
        return 1
    fi
}

main