#!/bin/bash

# ============================================================================
# LOGGER - Centralized logging with audit trail
# ============================================================================

# Enable/disable debug
DEBUG="${DEBUG:-false}"
DRY_RUN="${DRY_RUN:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
NC='\033[0m'

# Audit log file
AUDIT_LOG="${AUDIT_LOG:-./.audit.log}"

# ============================================================================
# LOG FUNCTIONS
# ============================================================================

log_info() {
    local message="$1"
    echo -e "${BLUE}ℹ${NC} $message" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $message" >> "$AUDIT_LOG"
}

log_debug() {
    local message="$1"
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${GRAY}🔍 [DEBUG]${NC} $message" >&2
    fi
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $message" >> "$AUDIT_LOG"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $message" >> "$AUDIT_LOG"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠${NC} $message" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $message" >> "$AUDIT_LOG"
}

log_error() {
    local message="$1"
    echo -e "${RED}✗${NC} $message" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $message" >> "$AUDIT_LOG"
}

log_dryrun() {
    local message="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $message" >&2
    fi
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] DRY-RUN: $message" >> "$AUDIT_LOG"
}

log_section() {
    local title="$1"
    echo "" >&2
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}" >&2
    echo -e "${BLUE}║${NC}  $title" >&2
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SECTION: $title" >> "$AUDIT_LOG"
}