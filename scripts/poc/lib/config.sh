#!/usr/bin/env bash

ir_default() {
  local name="$1"
  local default="$2"
  local val="${!name-}"

  if [ -n "$val" ]; then
    printf '%s' "$val"
  else
    printf '%s' "$default"
  fi
}

clean_csv() {
  echo "$1" | tr -d ' '
}

IR_TRIGGER_BRANCHES="$(clean_csv "$(ir_default IR_TRIGGER_BRANCHES 'main,develop')")"
IR_BREAKING_CHANGE_INDICATORS="$(clean_csv "$(ir_default IR_BREAKING_CHANGE_INDICATORS 'BREAKING CHANGE,!:,!:' )")"
IR_FEATURE_TYPES="$(clean_csv "$(ir_default IR_FEATURE_TYPES 'feat,feature')")"
IR_FIX_TYPES="$(clean_csv "$(ir_default IR_FIX_TYPES 'fix,bugfix')")"
IR_REFACTOR_TYPES="$(clean_csv "$(ir_default IR_REFACTOR_TYPES 'refactor,perf')")"

IR_GIT_USER_NAME="$(ir_default IR_GIT_USER_NAME 'github-actions[bot]')"
IR_GIT_USER_EMAIL="$(ir_default IR_GIT_USER_EMAIL 'github-actions[bot]@users.noreply.github.com')"

IR_INITIAL_VERSION="$(ir_default IR_INITIAL_VERSION 'v0.0.1')"
IR_GENERATE_CHANGELOG="$(ir_default IR_GENERATE_CHANGELOG 'true')"
IR_CHANGELOG_FILE="$(ir_default IR_CHANGELOG_FILE 'CHANGELOG.md')"
IR_AUTO_COMMIT="$(ir_default IR_AUTO_COMMIT 'true')"
IR_CREATE_TAGS="$(ir_default IR_CREATE_TAGS 'true')"
IR_CREATE_RELEASE="$(ir_default IR_CREATE_RELEASE 'false')"
IR_DEBUG="$(ir_default IR_DEBUG 'false')"
IR_STRICT_DRY_RUN="$(ir_default IR_STRICT_DRY_RUN 'false')"
IR_MISC_ENABLED="$(ir_default IR_MISC_ENABLED 'true')"

if [ -n "${IR_DRY_RUN-}" ]; then
  DRY_RUN="$IR_DRY_RUN"
else
  DRY_RUN="${DRY_RUN:-false}"
fi

if [ "$IR_STRICT_DRY_RUN" = "true" ]; then
  DRY_RUN="true"
fi

IR_BRANCH_PATTERN="${IR_TRIGGER_BRANCHES//,/|}"
IR_BREAKING_PATTERN="${IR_BREAKING_CHANGE_INDICATORS//,/|}"
IR_FEATURE_PATTERN="${IR_FEATURE_TYPES//,/|}"
IR_FIX_PATTERN="${IR_FIX_TYPES//,/|}"
IR_REFACTOR_PATTERN="${IR_REFACTOR_TYPES//,/|}"
