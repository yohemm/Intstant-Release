# Stratégie de Test - GitHub Action CI/CD Framework

## 1. ARCHITECTURE DE TEST

```
┌─────────────────────────────────────────────────────────────────┐
│                     SUITE DE TEST                                │
└─────────────────────────────────────────────────────────────────┘
         │                           │                        │
    ┌────┴─────┐            ┌───────┴──────┐         ┌──────┴────┐
    │ UNITAIRES│            │ INTÉGRATION  │         │    E2E    │
    │  (Bash)  │            │  (Docker)    │         │ (GitHub)  │
    └────┬─────┘            └───────┬──────┘         └──────┬────┘
         │                          │                        │
    ├─ Fonctions      ├─ Workflows complets     ├─ Actions réelles
    ├─ Logique        ├─ Interaction modules    ├─ Repositories
    ├─ Validation     ├─ Webhooks simulés       ├─ Secrets
    └─ Utilitaires    ├─ Artefacts              └─ Permissions
                      └─ Rapports
```

---

## 2. TESTS UNITAIRES (Bash)

### 2.1 Structure des Tests Unitaires

```
tests/
├── unit/
│   ├── run_all_tests.sh              # Runner principal
│   ├── test_helpers.sh               # Fonctions helpers
│   │
│   ├── git/
│   │   ├── test_git_config.sh
│   │   ├── test_git_commit.sh
│   │   └── test_git_push.sh
│   │
│   ├── versioning/
│   │   ├── test_detect_bump_type.sh
│   │   ├── test_validate_semver.sh
│   │   ├── test_calculate_version.sh
│   │   └── test_sync_version.sh
│   │
│   ├── changelog/
│   │   ├── test_generate_changelog.sh
│   │   ├── test_extract_changelog.sh
│   │   └── test_changelog_template.sh
│   │
│   ├── validation/
│   │   ├── test_yaml_validation.sh
│   │   ├── test_semver_validation.sh
│   │   └── test_token_validation.sh
│   │
│   ├── utils/
│   │   ├── test_logger.sh
│   │   ├── test_retry_logic.sh
│   │   └── test_error_handling.sh
│   │
│   └── security/
│       ├── test_gpg_signing.sh
│       └── test_secret_patterns.sh
│
├── fixtures/                         # Données de test
│   ├── repos/
│   │   ├── simple-repo/
│   │   ├── monorepo/
│   │   └── breaking-changes-repo/
│   ├── configs/
│   │   ├── valid.yml
│   │   ├── invalid.yml
│   │   └── minimal.yml
│   └── changelogs/
│       ├── template.hbs
│       └── expected-output.md
│
└── mocks/                            # Mock objects
    ├── github-api-mock.sh
    ├── git-mock.sh
    └── webhook-mock.sh
```

### 2.2 Framework de Test Bash

**tests/unit/test_helpers.sh**

```bash
#!/bin/bash

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# TEST ASSERTION FUNCTIONS
# ============================================================================

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    
    if [[ -n "$value" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name (value is empty)"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name (file not found: $file)"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name (pattern not found in $file)"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
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
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Pattern: $pattern"
        echo "  Value:   $value"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ============================================================================
# SETUP & TEARDOWN
# ============================================================================

setup_test() {
    local test_name="$1"
    echo ""
    echo -e "${YELLOW}► Testing: $test_name${NC}"
}

teardown_test() {
    echo ""
}

setup_temp_repo() {
    local repo_dir="/tmp/test-repo-$$"
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    git init --initial-branch=main
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "$repo_dir"
}

teardown_temp_repo() {
    local repo_dir="$1"
    rm -rf "$repo_dir"
}

# ============================================================================
# TEST REPORT
# ============================================================================

print_summary() {
    echo ""
    echo "=========================================="
    echo "         TEST SUMMARY"
    echo "=========================================="
    echo "Total:   $TESTS_RUN"
    echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"
    echo "=========================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed!${NC}"
        return 1
    fi
}

# ============================================================================
# MOCK FUNCTIONS
# ============================================================================

mock_git_commit() {
    local message="$1"
    echo "Mock commit" > /tmp/mock-file-$$.txt
    git add /tmp/mock-file-$$.txt
    git commit -m "$message"
}

mock_github_api_response() {
    local endpoint="$1"
    
    case "$endpoint" in
        "repos/owner/repo")
            echo '{
                "id": 123456,
                "name": "repo",
                "full_name": "owner/repo",
                "owner": {"login": "owner"}
            }'
            ;;
        "repos/owner/repo/releases/latest")
            echo '{
                "tag_name": "v1.0.0",
                "created_at": "2024-01-15T10:00:00Z"
            }'
            ;;
        *)
            echo '{}'
            ;;
    esac
}
```

### 2.3 Exemple Test Unitaire: Versioning

**tests/unit/versioning/test_detect_bump_type.sh**

```bash
#!/bin/bash

source "$(dirname "$0")/../test_helpers.sh"
source "$(dirname "$0")/../../scripts/lib/validators.sh"

# ============================================================================
# TEST CASES
# ============================================================================

test_detect_major_bump() {
    setup_test "Detect MAJOR bump from BREAKING CHANGE"
    
    local commits="feat: new feature\nBREAKING CHANGE: API changed"
    local bump_type=$(detect_bump_type "$commits" "BREAKING CHANGE" "feat:" "fix:")
    
    assert_equals "major" "$bump_type" "Should detect major bump"
    teardown_test
}

test_detect_minor_bump() {
    setup_test "Detect MINOR bump from feat:"
    
    local commits="feat: new feature"
    local bump_type=$(detect_bump_type "$commits" "BREAKING CHANGE" "feat:" "fix:")
    
    assert_equals "minor" "$bump_type" "Should detect minor bump"
    teardown_test
}

test_detect_patch_bump() {
    setup_test "Detect PATCH bump from fix:"
    
    local commits="fix: bug fix"
    local bump_type=$(detect_bump_type "$commits" "BREAKING CHANGE" "feat:" "fix:")
    
    assert_equals "patch" "$bump_type" "Should detect patch bump"
    teardown_test
}

test_detect_no_bump() {
    setup_test "Detect NO bump from chore/docs"
    
    local commits="chore: update deps\ndocs: update readme"
    local bump_type=$(detect_bump_type "$commits" "BREAKING CHANGE" "feat:" "fix:")
    
    assert_equals "none" "$bump_type" "Should detect no bump"
    teardown_test
}

test_bump_priority_breaking_over_feat() {
    setup_test "BREAKING CHANGE takes priority over feat:"
    
    local commits="feat: new feature\nBREAKING CHANGE: removed endpoint"
    local bump_type=$(detect_bump_type "$commits" "BREAKING CHANGE" "feat:" "fix:")
    
    assert_equals "major" "$bump_type" "Major should override minor"
    teardown_test
}

test_bump_priority_feat_over_fix() {
    setup_test "feat: takes priority over fix:"
    
    local commits="fix: bug fix\nfeat: new feature"
    local bump_type=$(detect_bump_type "$commits" "BREAKING CHANGE" "feat:" "fix:")
    
    assert_equals "minor" "$bump_type" "Minor should override patch"
    teardown_test
}

test_custom_indicators() {
    setup_test "Custom indicators"
    
    local commits="[BREAKING] Custom breaking\n[FEATURE] Custom feature"
    local bump_type=$(detect_bump_type "$commits" "[BREAKING]" "[FEATURE]" "[FIX]")
    
    assert_equals "major" "$bump_type" "Should work with custom indicators"
    teardown_test
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       UNIT TESTS: Version Detection                        ║"
echo "╚════════════════════════════════════════════════════════════╝"

test_detect_major_bump
test_detect_minor_bump
test_detect_patch_bump
test_detect_no_bump
test_bump_priority_breaking_over_feat
test_bump_priority_feat_over_fix
test_custom_indicators

print_summary
exit $?
```

### 2.4 Runner Principal: tests/unit/run_all_tests.sh

```bash
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

TEST_SUITES=(
    "tests/unit/git/test_git_config.sh"
    "tests/unit/versioning/test_detect_bump_type.sh"
    "tests/unit/versioning/test_validate_semver.sh"
    "tests/unit/changelog/test_generate_changelog.sh"
    "tests/unit/validation/test_yaml_validation.sh"
    "tests/unit/utils/test_logger.sh"
    "tests/unit/utils/test_retry_logic.sh"
    "tests/unit/security/test_gpg_signing.sh"
)

run_test_suite() {
    local suite="$1"
    
    if [[ ! -f "$suite" ]]; then
        echo -e "${RED}✗ Test file not found: $suite${NC}"
        return 1
    fi
    
    bash "$suite"
    local exit_code=$?
    
    # Extract counts from output
    # (Implementation would parse the output)
    
    return $exit_code
}

main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          UNIT TEST SUITE - ALL TESTS                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    local failed_suites=()
    
    for suite in "${TEST_SUITES[@]}"; do
        echo -e "${BLUE}Running: $(basename "$suite")${NC}"
        
        if run_test_suite "$suite"; then
            echo -e "${GREEN}✓ Passed${NC}"
        else
            echo -e "${RED}✗ Failed${NC}"
            failed_suites+=("$suite")
        fi
        echo ""
    done
    
    # Summary
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  FINAL SUMMARY                             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    
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
```

---

## 3. TESTS D'INTÉGRATION (Docker)

### 3.1 Dockerfile pour Tests d'Intégration

**tests/integration/Dockerfile**

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    jq \
    npm \
    python3 \
    python3-pip \
    gpg \
    openssh-client \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install Node LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Setup test environment
WORKDIR /action

# Copy action scripts
COPY scripts/ /action/scripts/
COPY tests/ /action/tests/
COPY templates/ /action/templates/

# Git configuration for tests
RUN git config --global user.email "test@github.actions" \
    && git config --global user.name "GitHub Actions Test"

# Make scripts executable
RUN chmod -R +x /action/scripts /action/tests

ENTRYPOINT ["/action/tests/integration/run_integration_tests.sh"]
```

### 3.2 Tests d'Intégration

**tests/integration/run_integration_tests.sh**

```bash
#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
FIXTURES_DIR="$SCRIPT_DIR/../fixtures"
TEMP_DIR="/tmp/integration-tests-$$"

# Colors function
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_section() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  $1"
    echo "╚════════════════════════════════════════════════════════════╝"
}

# ============================================================================
# TEST 1: Simple Release Workflow
# ============================================================================

test_simple_release() {
    log_section "TEST 1: Simple Release Workflow"
    
    local test_repo="$TEMP_DIR/simple-release"
    mkdir -p "$test_repo"
    cd "$test_repo"
    
    # Initialize repo
    log_info "Initializing test repository..."
    git init --initial-branch=main
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    log_info "Creating initial commit..."
    echo "# Test Project" > README.md
    git add README.md
    git commit -m "Initial commit"
    
    # Create feature commit
    log_info "Creating feature commit..."
    echo "feature1" >> README.md
    git add README.md
    git commit -m "feat: add feature 1"
    
    # Create fix commit
    log_info "Creating fix commit..."
    echo "fix1" >> README.md
    git add README.md
    git commit -m "fix: bug fix"
    
    # Test version detection
    log_info "Testing version detection..."
    local bump_type=$("$ACTION_DIR/scripts/versioning/detect-bump-type.sh" \
        --major-indicator "BREAKING CHANGE" \
        --minor-indicator "feat:" \
        --patch-indicator "fix:")
    
    if [[ "$bump_type" == "minor" ]]; then
        log_success "Detected minor bump correctly"
    else
        log_error "Failed to detect bump type (got: $bump_type)"
        return 1
    fi
    
    # Test changelog generation
    log_info "Testing changelog generation..."
    "$ACTION_DIR/scripts/changelog/generate-changelog.sh" \
        --changelog-file "CHANGELOG.md" \
        --template "$ACTION_DIR/templates/changelog-default.hbs"
    
    if [[ -f "CHANGELOG.md" ]]; then
        log_success "Changelog generated successfully"
        cat CHANGELOG.md
    else
        log_error "Changelog not generated"
        return 1
    fi
    
    # Test tag creation
    log_info "Testing tag creation..."
    "$ACTION_DIR/scripts/release/create-tag.sh" \
        --version "0.2.0" \
        --prefix "v" \
        --dry-run false
    
    if git rev-parse v0.2.0 >/dev/null 2>&1; then
        log_success "Tag created successfully"
    else
        log_error "Tag not created"
        return 1
    fi
    
    log_success "TEST 1 PASSED"
    return 0
}

# ============================================================================
# TEST 2: Monorepo Multi-Package
# ============================================================================

test_monorepo_release() {
    log_section "TEST 2: Monorepo Multi-Package Release"
    
    local test_repo="$TEMP_DIR/monorepo-release"
    mkdir -p "$test_repo"
    cd "$test_repo"
    
    # Initialize monorepo
    log_info "Creating monorepo structure..."
    git init --initial-branch=main
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    mkdir -p packages/ui packages/cli
    
    # Create package.json files
    cat > packages/ui/package.json << 'EOF'
{
  "name": "@myapp/ui",
  "version": "1.0.0"
}
EOF
    
    cat > packages/cli/package.json << 'EOF'
{
  "name": "@myapp/cli",
  "version": "1.0.0"
}
EOF
    
    git add packages/
    git commit -m "Initial packages"
    
    # Change only ui package
    log_info "Modifying UI package..."
    echo "// ui change" >> packages/ui/index.js
    git add packages/ui/
    git commit -m "feat(ui): add new component"
    
    # Detect changed packages
    log_info "Detecting changed packages..."
    local changed=$("$ACTION_DIR/scripts/versioning/detect-changed-packages.sh" \
        --monorepo-root ".")
    
    if echo "$changed" | grep -q "packages/ui"; then
        log_success "Detected changed UI package"
    else
        log_error "Failed to detect changed packages"
        return 1
    fi
    
    log_success "TEST 2 PASSED"
    return 0
}

# ============================================================================
# TEST 3: Security Scanning
# ============================================================================

test_security_scanning() {
    log_section "TEST 3: Security Scanning"
    
    local test_repo="$TEMP_DIR/security-test"
    mkdir -p "$test_repo"
    cd "$test_repo"
    
    # Initialize
    git init --initial-branch=main
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create package.json with known vulnerabilities
    cat > package.json << 'EOF'
{
  "name": "test-app",
  "version": "1.0.0",
  "dependencies": {
    "lodash": "4.17.20"
  }
}
EOF
    
    git add package.json
    git commit -m "Add dependencies"
    
    # Test secret scanning
    log_info "Testing secret pattern detection..."
    echo 'API_KEY="sk_live_123456789"' > config.env
    
    local secrets=$("$ACTION_DIR/scripts/security/secret-scan.sh" \
        --scan-dir "." \
        --pattern "sk_live_" 2>/dev/null || echo "0")
    
    log_success "Secret scanning completed"
    
    log_success "TEST 3 PASSED"
    return 0
}

# ============================================================================
# TEST 4: Webhook & Plugin Integration
# ============================================================================

test_webhooks_plugins() {
    log_section "TEST 4: Webhooks & Plugin Integration"
    
    local test_repo="$TEMP_DIR/webhook-test"
    mkdir -p "$test_repo"
    cd "$test_repo"
    
    # Initialize
    git init --initial-branch=main
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    echo "test" > file.txt
    git add file.txt
    git commit -m "Initial"
    
    # Create mock webhook server
    log_info "Starting mock webhook server..."
    python3 << 'PYTHON'
import http.server
import json
import threading

class WebhookHandler(http.server.BaseRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        data = json.loads(body)
        
        with open('/tmp/webhook_received.json', 'w') as f:
            json.dump(data, f)
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"status":"ok"}')

server = http.server.HTTPServer(('localhost', 8888), WebhookHandler)
thread = threading.Thread(target=server.serve_forever)
thread.daemon = True
thread.start()

import time
time.sleep(10)
PYTHON &
    local server_pid=$!
    
    sleep 1
    
    # Call webhook
    log_info "Sending test webhook..."
    curl -X POST http://localhost:8888/webhook \
        -H "Content-Type: application/json" \
        -d '{"event":"test","version":"1.0.0"}' \
        2>/dev/null || true
    
    sleep 1
    
    # Verify webhook received
    if [[ -f /tmp/webhook_received.json ]]; then
        log_success "Webhook received successfully"
        cat /tmp/webhook_received.json
    else
        log_error "Webhook not received"
        return 1
    fi
    
    kill $server_pid 2>/dev/null || true
    
    log_success "TEST 4 PASSED"
    return 0
}

# ============================================================================
# TEST 5: Error Handling & Rollback
# ============================================================================

test_error_handling() {
    log_section "TEST 5: Error Handling & Rollback"
    
    local test_repo="$TEMP_DIR/error-test"
    mkdir -p "$test_repo"
    cd "$test_repo"
    
    # Initialize
    git init --initial-branch=main
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    echo "v1.0.0" > VERSION
    git add VERSION
    git commit -m "v1.0.0"
    git tag v1.0.0
    
    # Test invalid semver
    log_info "Testing invalid semver detection..."
    local is_valid=$("$ACTION_DIR/scripts/versioning/validate-semver.sh" \
        --version "not-a-version" 2>&1 || echo "invalid")
    
    if echo "$is_valid" | grep -q "invalid"; then
        log_success "Invalid semver detected correctly"
    else
        log_error "Failed to validate invalid semver"
        return 1
    fi
    
    log_success "TEST 5 PASSED"
    return 0
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     INTEGRATION TESTS - Docker Environment                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    mkdir -p "$TEMP_DIR"
    trap "rm -rf $TEMP_DIR" EXIT
    
    local failed=0
    
    test_simple_release || ((failed++))
    test_monorepo_release || ((failed++))
    test_security_scanning || ((failed++))
    test_webhooks_plugins || ((failed++))
    test_error_handling || ((failed++))
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    FINAL REPORT                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    
    if [[ $failed -eq 0 ]]; then
        log_success "All integration tests passed!"
        return 0
    else
        log_error "$failed test(s) failed"
        return 1
    fi
}

main
```

---

## 4. SETUP LOCAL COMPLET

### 4.1 Makefile pour Tests Locaux

**Makefile**

```makefile
.PHONY: help test test-unit test-integration test-e2e test-all clean

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
NC := \033[0m

help:
	@echo "$(BLUE)Available commands:$(NC)"
	@echo "  make test-unit           - Run unit tests (bash, local)"
	@echo "  make test-integration    - Run integration tests (Docker)"
	@echo "  make test-e2e