#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/paths.sh"
source "${LOGGER_SCRIPT}"
source "${GIT_HELPERS_SCRIPT}"
source "${CONFIG_SCRIPT}"
source "${REGEX_PARSER_SCRIPT}"

# ============================================================================
# FUNCTION: Detect Bump Type
# ============================================================================

detect_bump_type() {
    # 1. Parser les arguments
    declare -A fn_args
    parse_function_args fn_args "$@"
    
    # 2. Charger la config (si pas déjà fait)
    if [[ "${SKIP_CONFIG:-false}" != "true" ]]; then
        if [[ -z "${CURRENT_CONFIG[versioning.indicators.major]:-}" ]]; then
            init_config
            load_config_file "${CONFIG_FILE}"
        fi
    fi
    
    # 3. Résoudre les paramètres (argument > config > default)
    local major_indicator=$(resolve_param \
        "major-indicator" \
        fn_args \
        "versioning.indicators.major" \
        "BREAKING CHANGE")
    
    local minor_indicator=$(resolve_param \
        "minor-indicator" \
        fn_args \
        "versioning.indicators.minor" \
        "feat:")
    
    local patch_indicator=$(resolve_param \
        "patch-indicator" \
        fn_args \
        "versioning.indicators.patch" \
        "fix:")
    
    log_debug "Using indicators:"
    log_debug "  Major: $major_indicator"
    log_debug "  Minor: $minor_indicator"
    log_debug "  Patch: $patch_indicator"
    
    # 4. Implementation
    local last_tag
    last_tag=$(git_get_last_tag) || last_tag=""
    
    local commits
    commits=$(git_get_commits_since_tag "$last_tag")
    
    
    if [[ -z "$commits" ]]; then
        echo "none"
        return 0
    fi
    
    # Detect bump type (priority: major > minor > patch)
    major_indicator=$(escape_regex_parts "$major_indicator")
    minor_indicator=$(escape_regex_parts "$minor_indicator")
    patch_indicator=$(escape_regex_parts "$patch_indicator")
    # commits=$(escape_regex_parts "$commits")
    log_debug "debug for custom"
    log_debug "${commits}"
    log_debug "${minor_indicator}"

    
    log_debug "  commits:"
    if echo "$commits" | grep -Eq "${major_indicator}" > /dev/null 2>&1; then
        echo "major"
        return 0
    fi
    
    if echo "$commits" | grep -Eq "^${minor_indicator}" > /dev/null 2>&1; then
        echo "minor"
        return 0
    fi
    
    if echo "$commits" | grep -Eq "^${patch_indicator}" > /dev/null 2>&1; then
        echo "patch"
        return 0
    fi
    
    echo "none"
    return 0
}

# ============================================================================
# EXECUTION
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_bump_type "$@"
fi