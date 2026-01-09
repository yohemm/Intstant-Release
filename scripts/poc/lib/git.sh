#!/usr/bin/env bash

setup_git() {
  git config --global user.name "$IR_GIT_USER_NAME"
  git config --global user.email "$IR_GIT_USER_EMAIL"

  if git remote get-url origin >/dev/null 2>&1; then
    git fetch --tags --all
  else
    log_debug "No git remote found, skip fetch"
  fi
}

commit_changes() {
  local file="$1"
  local message="$2"

  if [ ! -f "$file" ]; then
    log_debug "Changelog file not found: $file"
    return 0
  fi

  git add "$file"

  if git diff --cached --quiet; then
    log_info "No changes to commit"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "DRY_RUN enabled, skip commit"
    git reset -q
    return 0
  fi

  if [ "$IR_STRICT_DRY_RUN" = "true" ]; then
    log_info "STRICT_DRY_RUN enabled, skip commit"
    git reset -q
    return 0
  fi

  git commit -m "$message"

  if git remote get-url origin >/dev/null 2>&1; then
    git push origin HEAD
  else
    log_warn "No git remote found, skip push"
  fi
}
