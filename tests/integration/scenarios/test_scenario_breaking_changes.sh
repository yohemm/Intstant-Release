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

log_section "SCENARIO 2: Breaking Changes Release"

# Setup
local repo=$(setup_temp_git_repo "scenario-breaking")

# Initial state
echo "v1" > version.txt
git add version.txt
git commit -m "Initial version"
git tag v1.0.0

# Multiple commits with breaking change
echo "fix" >> version.txt
git add version.txt
git commit -m "fix: resolve issue"

echo "breaking" >> version.txt
git add version.txt
git commit -m "refactor: redesign API

BREAKING CHANGE: removed deprecated methods"

# Detect bump type - should detect MAJOR
local bump_type=$(detect_bump_type \
    --major-indicator "BREAKING CHANGE" \
    --minor-indicator "feat:" \
    --patch-indicator "fix:")
log_info "Detected bump type: $bump_type"

# Calculate version - should be v2.0.0
local new_version=$(calculate_version "v1.0.0" "$bump_type")
log_info "Calculated version: $new_version"

# Assertions
assert_equals "major" "$bump_type" "Should detect major bump from BREAKING CHANGE"
assert_equals "v2.0.0" "$new_version" "Should bump to v2.0.0"

# Cleanup
teardown_temp_git_repo "$repo"

log_section "SCENARIO 2 COMPLETE"