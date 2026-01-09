#!/usr/bin/env bash

create_tag() {
  local tag="$1"
  local created="false"

  if git rev-parse "$tag" >/dev/null 2>&1; then
    log_info "Tag already exists: $tag"
  else
    if [ "$IR_STRICT_DRY_RUN" = "true" ]; then
      log_info "STRICT_DRY_RUN enabled, skip tag creation"
      echo "false"
      return 0
    fi

    git tag "$tag"
    created="true"
    if [ "$DRY_RUN" = "true" ]; then
      log_info "DRY_RUN enabled, skip push for tag $tag"
    else
      if git remote get-url origin >/dev/null 2>&1; then
        git push origin "$tag"
      else
        log_warn "No git remote found, skip tag push"
      fi
    fi
  fi

  echo "$created"
}
