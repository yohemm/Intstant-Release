#!/bin/bash

# ============================================================================
# CONFIG MANAGEMENT - Load and Parse Configuration
# ============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paths.sh"
source "${LOGGER_SCRIPT}"
source "${VALIDATORS_SCRIPT}"

# ============================================================================
# 1. DEFAULT VALUES
# ============================================================================

declare -A DEFAULT_CONFIG=(
    # GIT
    [git.user-name]="github-actions[bot]"
    [git.user-email]="github-actions[bot]@github.com"
    [git.auto-commit]="true"
    [git.auto-push]="true"
    [git.target-branch]="main"
    
    # VERSIONING
    [versioning.initial-version]="v0.1.0"
    [versioning.bump]="auto"
    [versioning.detect-bump]="true"
    [versioning.indicators.major]="BREAKING CHANGE"
    [versioning.indicators.minor]="feat:"
    [versioning.indicators.patch]="fix:"
    [versioning.version-prefix]="v"
    [versioning.verify-tag-exists]="true"
    
    # CHANGELOG
    [changelog.generate]="true"
    [changelog.file]="CHANGELOG.md"
    [changelog.template]="templates/changelog-default.hbs"
    [changelog.append-mode]="prepend"
    [changelog.include-contributors]="true"
    [changelog.include-stats]="true"
    
    # RELEASE
    [release.create-tag]="true"
    [release.create-release]="false"
    [release.release-draft]="false"
    [release.release-prerelease]="false"
    [release.prerelease-suffix]=""
    [release.tag-delete-on-failure]="true"
    
    # BUILD
    [build.enabled]="true"
    [build.command]="npm run build"
    [build.artifact-path]="dist"
    [build.upload-artifact]="false"
    
    # TESTS
    [tests.enabled]="true"
    [tests.unit-tests-command]="npm test"
    [tests.coverage-threshold]="80"
    [tests.lint-enabled]="true"
    [tests.lint-command]="npm run lint"
    
    # SECURITY
    [security.dependency-scan]="true"
    [security.secret-scan]="false"
    [security.commit-signature-check]="false"
    
    # DEPLOYMENT
    [deployment.enabled]="false"
    [deployment.environment]="staging"
    [deployment.command]=""
    [deployment.post-deploy-validation]="false"
    [deployment.post-deploy-check-url]=""
    
    # DEBUG
    [debug]="false"
    [dry-run]="false"
)

# Tableau pour stocker la config chargée
declare -A CURRENT_CONFIG

# ============================================================================
# 2. INITIALIZE CONFIG FROM DEFAULTS
# ============================================================================

init_config() {
    log_debug "Initializing configuration from defaults"
    
    # Copier les defaults
    for key in "${!DEFAULT_CONFIG[@]}"; do
        CURRENT_CONFIG["$key"]="${DEFAULT_CONFIG[$key]}"
    done
    
    log_debug "Configuration initialized with ${#CURRENT_CONFIG[@]} values"
}

# ============================================================================
# 3. LOAD CONFIG FROM FILE
# ============================================================================

load_config_file() {
    local config_file="${1:-.instantrelease.yml}"
    
    # Vérifier que le fichier existe
    if [[ ! -f "$config_file" ]]; then
        log_debug "Config file not found: $config_file (using defaults)"
        return 0
    fi
    
    # # log_info "Loading configuration from: $config_file"
    
    # Vérifier que yq est installé
    if ! command -v yq &> /dev/null; then
        log_warning "yq not found, cannot parse YAML config"
        return 1
    fi
    
    # Parser le fichier YAML et remplir la config
    # Note: Cette approche simple; pour du vrai on utiliserait yq
    
    # Exemple avec yq (si disponible)
    while IFS='=' read -r key value; do
        if [[ -n "$key" ]]; then
            # Nettoyer les espaces
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Ajouter à la config
            CURRENT_CONFIG["$key"]="$value"
            log_debug "Config: $key = $value"
        fi
    done < <(yq eval -o=csv "$config_file" 2>/dev/null || echo "")
    
    log_success "Configuration loaded from file"
    return 0
}

# ============================================================================
# 4. LOAD CONFIG FROM ENVIRONMENT VARIABLES
# ============================================================================

load_config_env() {
    log_debug "Loading configuration from environment variables"
    
    # Variables d'environnement formatées comme IR_KEY_SUBKEY
    # Exemple: IR_VERSIONING_BUMP=major
    
    for env_var in "${!IR_@}"; do
        # Convertir IR_KEY_SUBKEY en key.subkey
        local config_key=$(echo "${env_var#IR_}" | tr '_' '.' | tr '[:upper:]' '[:lower:]')
        local config_value="${!env_var}"
        
        CURRENT_CONFIG["$config_key"]="$config_value"
        log_debug "Env override: $config_key = $config_value"
    done
}

# ============================================================================
# 5. GET CONFIG VALUE
# ============================================================================

get_config() {
    local key="$1"
    local default="${2:-}"
    
    if [[ -n "${CURRENT_CONFIG[$key]:-}" ]]; then
        echo "${CURRENT_CONFIG[$key]}"
    elif [[ -n "$default" ]]; then
        echo "$default"
    else
        log_warning "Config key not found: $key"
        return 1
    fi
}

# ============================================================================
# 6. SET CONFIG VALUE (override)
# ============================================================================

set_config() {
    local key="$1"
    local value="$2"
    
    CURRENT_CONFIG["$key"]="$value"
    log_debug "Config override: $key = $value"
}

# ============================================================================
# 7. PARSE FUNCTION ARGUMENTS
# ============================================================================

parse_function_args() {
    local -n result_dict=$1
    shift
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --*)
                # Format: --key value
                local key="${1#--}"
                shift
                
                if [[ $# -eq 0 ]] || [[ "$1" == --* ]]; then
                    # No value provided or next is another flag
                    result_dict["$key"]="true"
                else
                    # Value provided
                    result_dict["$key"]="$1"
                    shift
                fi
                ;;
            *)
                shift
                ;;
        esac
    done
}

# ============================================================================
# 8. RESOLVE PARAMETER VALUE (Hierarchie)
# ============================================================================

resolve_param() {
    local param_name="$1"
    local fn_args_dict="$2"  # Associative array name
    local config_key="$3"     # Config key to lookup
    local default="${4:-}"
    
    # 1. Check function argument (highest priority)
    if [[ -n "${fn_args_dict}" ]]; then
        local -n args_array="$fn_args_dict"
        if [[ -n "${args_array[$param_name]:-}" ]]; then
            echo "${args_array[$param_name]}"
            log_debug "Using argument: $param_name = ${args_array[$param_name]}"
            return 0
        fi
    fi
    
    # 2. Check config file / env (medium priority)
    if [[ -n "${CURRENT_CONFIG[$config_key]:-}" ]]; then
        echo "${CURRENT_CONFIG[$config_key]}"
        log_debug "Using config: $config_key = ${CURRENT_CONFIG[$config_key]}"
        return 0
    fi
    
    # 3. Use default (lowest priority)
    if [[ -n "$default" ]]; then
        echo "$default"
        log_debug "Using default: $param_name = $default"
        return 0
    fi
    
    log_warning "No value found for parameter: $param_name"
    return 1
}

# ============================================================================
# 9. PRINT CONFIG (for debugging)
# ============================================================================

print_config() {
    log_section "Current Configuration"
    
    for key in $(echo "${!CURRENT_CONFIG[@]}" | tr ' ' '\n' | sort); do
        echo "$key = ${CURRENT_CONFIG[$key]}"
    done
}

# ============================================================================
# 10. EXPORT CONFIG AS ENVIRONMENT VARIABLES
# ============================================================================

export_config_env() {
    log_debug "Exporting configuration as environment variables"
    
    for key in "${!CURRENT_CONFIG[@]}"; do
        # Convertir key.subkey en IR_KEY_SUBKEY
        local env_var="IR_$(echo "$key" | tr '.' '_' | tr '[:lower:]' '[:upper:]')"
        export "$env_var=${CURRENT_CONFIG[$key]}"
    done
}