#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/log.sh
. "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/config.sh
. "$SCRIPT_DIR/lib/config.sh"
# shellcheck source=lib/git.sh
. "$SCRIPT_DIR/lib/git.sh"
# shellcheck source=lib/versioning.sh
. "$SCRIPT_DIR/lib/versioning.sh"
# shellcheck source=lib/changelog.sh
. "$SCRIPT_DIR/lib/changelog.sh"
# shellcheck source=lib/tag.sh
. "$SCRIPT_DIR/lib/tag.sh"
# shellcheck source=lib/gh.sh
. "$SCRIPT_DIR/lib/gh.sh"

log_info "InstantRelease POC start"
log_debug "Branch pattern: $IR_BRANCH_PATTERN"
log_debug "Breaking pattern: $IR_BREAKING_PATTERN"
log_debug "Feature pattern: $IR_FEATURE_PATTERN"
log_debug "Fix pattern: $IR_FIX_PATTERN"
log_debug "Refactor pattern: $IR_REFACTOR_PATTERN"
log_debug "DRY_RUN: $DRY_RUN"
log_debug "STRICT_DRY_RUN: $IR_STRICT_DRY_RUN"

setup_git

last_tag="$(get_last_tag)"
if [ -z "$last_tag" ]; then
  last_tag="$IR_INITIAL_VERSION"
  is_initial="true"
else
  is_initial="false"
fi

log_debug "Last tag: $last_tag (initial: $is_initial)"

commits="$(collect_commits "$last_tag" "$is_initial")"
log_debug "Commits collected"

if [ "$is_initial" = "true" ]; then
  bump_type="initial"
  new_version="$IR_INITIAL_VERSION"
else
  read -r bump_type new_version <<< "$(determine_bump "$last_tag" "$commits")"
fi

log_info "Version: $new_version (bump: $bump_type)"

has_changelog="false"
if [ "$IR_GENERATE_CHANGELOG" = "true" ]; then
  has_changelog="$(generate_changelog "$last_tag" "$is_initial" "$new_version" | tail -n 1)"
fi

if [ "$IR_AUTO_COMMIT" = "true" ]; then
  commit_changes "$IR_CHANGELOG_FILE" "docs(changelog): update for $new_version"
fi

tag_created="false"
if [ "$IR_CREATE_TAGS" = "true" ]; then
  tag_created="$(create_tag "$new_version" | tail -n 1)"
fi

set_output "current-version" "$new_version"
set_output "version-bump" "$bump_type"
set_output "changelog-generated" "$has_changelog"
set_output "tag-created" "$tag_created"

log_info "Summary"
log_info "version=$new_version"
log_info "bump=$bump_type"
log_info "changelog=$has_changelog"
log_info "tag-created=$tag_created"
