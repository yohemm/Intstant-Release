#!/bin/bash

set -e


# 1️⃣ Charger paths
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"

# 2️⃣ Sourcer ce dont on a besoin
source "${TEST_HELPERS}"
source "${LOGGER_SCRIPT}"
source "${GIT_HELPERS_SCRIPT}"
source "${DETECT_BUMP_SCRIPT}"
source "${CALCULATE_VERSION_SCRIPT}"

log_section "SCENARIO 1: Simple Release Workflow"

# Setup
local repo=$(setup_temp_git_repo "scenario-simple")
log_info "Created test repository: $repo"

# Initial commit
echo "# Project" > README.md
git add README.md
git commit -m "Initial commit"
git tag v1.0.0
log_success "Initial commit with v1.0.0 tag"

# Feature commit
echo "## Feature" >> README.md
git add README.md
git commit -m "feat: add new feature"
log_info "Added feature commit"

# Detect bump type
local bump_type=$(detect_bump_type \
    --major-indicator "BREAKING CHANGE" \
    --minor-indicator "feat:" \
    --patch-indicator "fix:")
log_info "Detected bump type: $bump_type"

# Calculate new version
local new_version=$(calculate_version "v1.0.0" "$bump_type")
log_info "Calculated new version: $new_version"

# Verify results
assert_equals "minor" "$bump_type" "Should detect minor bump"
assert_equals "v1.1.0" "$new_version" "Should calculate v1.1.0"

# Tag the release
git_create_tag "$new_version" "Release $new_version"
log_success "Created tag $new_version"

# Verify tag exists
if git_tag_exists "$new_version"; then
    log_success "Tag $new_version verified"
else
    log_error "Tag $new_version not found"
    exit 1
fi

# Cleanup
teardown_temp_git_repo "$repo"
log_success "Test repository cleaned up"

log_section "SCENARIO 1 COMPLETE"