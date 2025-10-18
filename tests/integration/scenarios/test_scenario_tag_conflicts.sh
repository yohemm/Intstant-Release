#!/bin/bash

set -e


# 1️⃣ Charger paths
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../scripts/lib/paths.sh"

# 2️⃣ Sourcer ce dont on a besoin
source "${TEST_HELPERS}"
source "${LOGGER_SCRIPT}"
source "${GIT_HELPERS_SCRIPT}"

log_section "SCENARIO 3: Tag Conflict Handling"

local repo=$(setup_temp_git_repo "scenario-tag-conflict")

# Create initial commit and tag
echo "v1" > file.txt
git add file.txt
git commit -m "Initial"
git tag v1.0.0

# Try to create same tag at different commit
echo "v2" > file.txt
git add file.txt
git commit -m "Change"

# Attempt to create conflicting tag
if git_tag_exists "v1.0.0"; then
    log_info "Tag v1.0.0 already exists - handling conflict"
    
    # Strategy: delete old tag and create new one
    git tag -d v1.0.0
    git tag v1.0.0
    log_success "Tag conflict resolved"
else
    log_error "Tag check failed"
fi

teardown_temp_git_repo "$repo"

log_section "SCENARIO 3 COMPLETE"