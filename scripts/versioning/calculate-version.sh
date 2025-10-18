#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/paths.sh"
source "${LOGGER_SCRIPT}"
source "${GIT_HELPERS_SCRIPT}"
source "${CONFIG_SCRIPT}"


# ============================================================================
# CALCULATE VERSION
# ============================================================================

calculate_version() {
    local current_version="$1"
    local bump_type="$2"
    local prerelease_suffix="${3:-}"
    
    log_debug "Calculating version: $current_version + $bump_type"
    
    # Validate current version
    if ! validate_semver "$current_version"; then
        log_error "Invalid version format: $current_version"
        return 1
    fi
    
    # Handle no bump
    if [[ "$bump_type" == "none" ]]; then
        echo "$current_version"
        return 0
    fi
    
    # Extract prefix (v or empty)
    local prefix=""
    if [[ "$current_version" =~ ^v ]]; then
        prefix="v"
        current_version="${current_version:1}"
    fi
    
    # Parse version numbers
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current_version"
    
    # Remove any prerelease or build metadata
    patch="${patch%%-*}"
    patch="${patch%%+*}"
    
    # Calculate new version
    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            log_error "Unknown bump type: $bump_type"
            return 1
            ;;
    esac
    
    # Build new version
    local new_version="${prefix}${major}.${minor}.${patch}"
    
    # Add prerelease suffix if provided
    if [[ -n "$prerelease_suffix" ]]; then
        new_version="${new_version}-${prerelease_suffix}.$(date +%s)"
    fi
    
    log_debug "New version: $new_version"
    echo "$new_version"
    return 0
}

# ============================================================================
# EXECUTION
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_bump_type "$@"
fi