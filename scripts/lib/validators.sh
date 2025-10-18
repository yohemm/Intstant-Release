#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paths.sh"
source "${LOGGER_SCRIPT}"

# ============================================================================
# VALIDATORS
# ============================================================================

validate_semver() {
    local version="$1"
    
    # Regex for semantic versioning: v1.2.3
    local semver_regex='^v?[0-9]+\.[0-9]+\.[0-9]+$'
    
    if [[ $version =~ $semver_regex ]]; then
        log_debug "Version '$version' is valid semver"
        return 0
    else
        log_error "Version '$version' is not valid semver"
        return 1
    fi
}

validate_yaml() {
    local file="$1"
    
    if ! command -v yq &> /dev/null; then
        log_warning "yq not available, skipping YAML validation"
        return 0
    fi
    
    if yq eval . "$file" > /dev/null 2>&1; then
        log_debug "YAML file '$file' is valid"
        return 0
    else
        log_error "YAML file '$file' is invalid"
        return 1
    fi
}

validate_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not a git repository"
        return 1
    fi
    
    log_debug "Git repository is valid"
    return 0
}