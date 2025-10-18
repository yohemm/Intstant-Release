#!/bin/bash

# ============================================================================
# PATHS CONFIGURATION - Centralized Path Management
# ============================================================================
# Ce fichier DOIT être sourcé en premier dans tous les scripts/tests
# source "${PATHS_CONFIG}"

# ============================================================================
# 1. CALCULATE PROJECT ROOT
# ============================================================================

# Méthode 1: Depuis variable d'environnement (fournie par Make)
if [[ -n "${PROJECT_ROOT}" ]]; then
    INSTANTRELEASE_ROOT="${PROJECT_ROOT}"
else
    # Méthode 2: Calculer depuis le chemin du script (secours)
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Monter 2 niveaux: scripts/lib/ → scripts/ → racine
    INSTANTRELEASE_ROOT="$(cd "$SCRIPT_PATH/../.." && pwd)"
fi

# Vérifier que le répertoire racine existe
if [[ ! -d "${INSTANTRELEASE_ROOT}" ]]; then
    echo "ERROR: Project root not found: ${INSTANTRELEASE_ROOT}" >&2
    exit 1
fi

# ============================================================================
# 2. DEFINE ALL PATHS
# ============================================================================

# === MAIN DIRECTORIES ===
export SCRIPTS_DIR="${INSTANTRELEASE_ROOT}/scripts"
export TESTS_DIR="${INSTANTRELEASE_ROOT}/tests"
export TEMPLATES_DIR="${INSTANTRELEASE_ROOT}/templates"
export FIXTURES_DIR="${INSTANTRELEASE_ROOT}/tests/fixtures"

# === SCRIPTS SUBDIRECTORIES ===
export LIB_DIR="${SCRIPTS_DIR}/lib"
export VERSIONING_SCRIPTS="${SCRIPTS_DIR}/versioning"
export CHANGELOG_SCRIPTS="${SCRIPTS_DIR}/changelog"
export RELEASE_SCRIPTS="${SCRIPTS_DIR}/release"
export SECURITY_SCRIPTS="${SCRIPTS_DIR}/security"

# === TESTS SUBDIRECTORIES ===
export UNIT_TESTS_DIR="${TESTS_DIR}/unit"
export INTEGRATION_TESTS_DIR="${TESTS_DIR}/integration"
export SCENARIOS_DIR="${TESTS_DIR}/integration/scenarios"

# === LIBRARY SCRIPTS (Pour sourcing) ===
export LOGGER_SCRIPT="${LIB_DIR}/logger.sh"
export VALIDATORS_SCRIPT="${LIB_DIR}/validators.sh"
export GIT_HELPERS_SCRIPT="${LIB_DIR}/git-helpers.sh"
export CONFIG_SCRIPT="${LIB_DIR}/config.sh"
export UTILS_SCRIPT="${LIB_DIR}/utils.sh"
export REGEX_PARSER_SCRIPT="${LIB_DIR}/regex_parser.sh"

# === VERSIONING SCRIPTS ===
export DETECT_BUMP_SCRIPT="${VERSIONING_SCRIPTS}/detect-bump-type.sh"
export CALCULATE_VERSION_SCRIPT="${VERSIONING_SCRIPTS}/calculate-version.sh"
export VALIDATE_SEMVER_SCRIPT="${VERSIONING_SCRIPTS}/validate-semver.sh"
export SYNC_VERSION_SCRIPT="${VERSIONING_SCRIPTS}/sync-version.sh"

# === CHANGELOG SCRIPTS ===
export GENERATE_CHANGELOG_SCRIPT="${CHANGELOG_SCRIPTS}/generate-changelog.sh"
export EXTRACT_CHANGELOG_SCRIPT="${CHANGELOG_SCRIPTS}/extract-changelog.sh"
export FORMAT_ENTRIES_SCRIPT="${CHANGELOG_SCRIPTS}/format-entries.sh"

# === RELEASE SCRIPTS ===
export CREATE_TAG_SCRIPT="${RELEASE_SCRIPTS}/create-tag.sh"
export VERIFY_TAG_SCRIPT="${RELEASE_SCRIPTS}/verify-tag.sh"
export AUTO_COMMIT_SCRIPT="${RELEASE_SCRIPTS}/auto-commit.sh"
export AUTO_PUSH_SCRIPT="${RELEASE_SCRIPTS}/auto-push.sh"

# === TEMPLATES ===
export CHANGELOG_TEMPLATE="${TEMPLATES_DIR}/changelog-default.hbs"

# === TEST HELPERS ===
export TEST_HELPERS="${UNIT_TESTS_DIR}/test_helpers.sh"

# === CONFIG FILE ===
export CONFIG_FILE="${INSTANTRELEASE_ROOT}/.instantrelease.yml"

# ============================================================================
# 3. VERIFICATION
# ============================================================================

# Fonction pour vérifier qu'un fichier existe
verify_path() {
    local path="$1"
    local name="$2"
    
    if [[ ! -e "$path" ]]; then
        echo "WARNING: $name not found: $path" >&2
        return 1
    fi
    return 0
}

# Optionnel: Vérifier les chemins critiques au démarrage
if [[ "${VERIFY_PATHS:-true}" == "true" ]]; then
    # Ne vérifier que si demandé explicitement (évite des warnings à chaque source)
    verify_path "$LOGGER_SCRIPT" "Logger script" || true
fi

# ============================================================================
# 4. DEBUG OUTPUT
# ============================================================================

if [[ "${DEBUG_PATHS:-false}" == "true" ]]; then
    echo "[DEBUG] Paths Configuration Loaded"
    echo "  INSTANTRELEASE_ROOT: $INSTANTRELEASE_ROOT"
    echo "  SCRIPTS_DIR: $SCRIPTS_DIR"
    echo "  TESTS_DIR: $TESTS_DIR"
    echo "  LOGGER_SCRIPT: $LOGGER_SCRIPT"
fi

# ============================================================================
# 5. EXPORT ALL VARIABLES
# ============================================================================

export INSTANTRELEASE_ROOT
export SCRIPTS_DIR
export TESTS_DIR
export TEMPLATES_DIR
export FIXTURES_DIR