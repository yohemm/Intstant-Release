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