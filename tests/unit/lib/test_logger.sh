#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"
source "${TEST_HELPERS}"
source "${LOGGER_SCRIPT}"

# ============================================================================
# TEST 1: log_info sends to stderr
# ============================================================================

test_log_info_to_stderr() {
    local output
    output=$(log_info "Test message" 2>&1 1>/dev/null)
    
    if echo "$output" | grep -q "Test message"; then
        echo -e "${GREEN}✓${NC} log_info outputs to stderr"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} log_info should output to stderr"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

# ============================================================================
# TEST 2: log_debug only shows in DEBUG mode
# ============================================================================

test_log_debug_debug_mode() {
    DEBUG=true
    local output
    output=$(log_debug "Debug message" 2>&1 1>/dev/null)
    
    if echo "$output" | grep -q "Debug message"; then
        echo -e "${GREEN}✓${NC} log_debug shows in DEBUG=true"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} log_debug should show in DEBUG=true"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

test_log_debug_no_debug_mode() {
    DEBUG=false
    local output
    output=$(log_debug "Debug message" 2>&1 1>/dev/null)
    
    if [[ -z "$output" ]]; then
        echo -e "${GREEN}✓${NC} log_debug hidden in DEBUG=false"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} log_debug should be hidden in DEBUG=false"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

# ============================================================================
# TEST 3: Audit log is created
# ============================================================================

test_audit_log_created() {
    local test_log="/tmp/test-audit-$$.log"
    export AUDIT_LOG="$test_log"
    
    log_info "Test audit" >/dev/null 2>&1
    
    if [[ -f "$test_log" ]]; then
        echo -e "${GREEN}✓${NC} Audit log file created"
        ((TESTS_PASSED++))
        rm -f "$test_log"
    else
        echo -e "${RED}✗${NC} Audit log file should be created"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  UNIT TESTS: Logger                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

test_log_info_to_stderr
test_log_debug_debug_mode
test_log_debug_no_debug_mode
test_audit_log_created

print_test_summary
exit $?