#!/usr/bin/env bash

generate_changelog() {
  local last_tag="$1"
  local is_initial="$2"
  local new_version="$3"

  local file="$IR_CHANGELOG_FILE"
  local repo="${GITHUB_REPOSITORY:-local/repo}"
  local repo_url="https://github.com/${repo}"
  local version_title="## ${new_version}"
  local tmp_file="${file}.tmp"

  if [ -f "$file" ] && grep -q "^${version_title}" "$file"; then
    log_info "Changelog already contains ${version_title}, skip"
    echo "false"
    return 0
  fi

  local all_commits
  if [ "$is_initial" = "false" ]; then
    all_commits="$(git log "${last_tag}..HEAD" --pretty=format:"- %s ([commit %h](${repo_url}/commit/%H)) by %an" || true)"
  else
    all_commits="$(git log HEAD --pretty=format:"- %s ([commit %h](${repo_url}/commit/%H)) by %an" || true)"
  fi

  : > "$tmp_file"
  echo "${version_title} - $(date +'%Y-%m-%d')" >> "$tmp_file"
  echo "" >> "$tmp_file"

  local has_changes="false"

  add_section() {
    local title="$1"
    local content="$2"
    if [ -n "$content" ]; then
      echo "### ${title}" >> "$tmp_file"
      echo "$content" >> "$tmp_file"
      echo "" >> "$tmp_file"
      has_changes="true"
    fi
  }

  local breaking features fixes refactors misc merges

  breaking="$(echo "$all_commits" | grep -E "($IR_BREAKING_PATTERN)" || true)"
  features="$(echo "$all_commits" | grep -E "^- (${IR_FEATURE_PATTERN})" || true)"
  fixes="$(echo "$all_commits" | grep -E "^- (${IR_FIX_PATTERN})" || true)"
  refactors="$(echo "$all_commits" | grep -E "^- (${IR_REFACTOR_PATTERN})" || true)"
  merges="$(echo "$all_commits" | grep -E "^ - Merge|^- Merge" || true)"
  misc="$(echo "$all_commits" | grep -Ev "^- (${IR_FEATURE_PATTERN}|${IR_FIX_PATTERN}|${IR_REFACTOR_PATTERN})|(${IR_BREAKING_PATTERN})|Merge" || true)"

  add_section "Breaking Changes" "$breaking"
  add_section "Features" "$features"
  add_section "Fixes" "$fixes"
  add_section "Refactors" "$refactors"
  add_section "Other Changes" "$misc"
  add_section "Merges" "$merges"

  if [ "$has_changes" = "false" ]; then
    rm -f "$tmp_file"
    log_info "No changelog changes to add"
    echo "false"
    return 0
  fi

  if [ "$IR_STRICT_DRY_RUN" = "true" ]; then
    rm -f "$tmp_file"
    log_info "STRICT_DRY_RUN enabled, skip changelog write"
    echo "true"
    return 0
  fi

  if [ "$is_initial" = "false" ] && [ "$last_tag" != "$new_version" ]; then
    echo "Compare changes: [${last_tag}...${new_version}](${repo_url}/compare/${last_tag}...${new_version})" >> "$tmp_file"
    echo "" >> "$tmp_file"
  fi

  if [ -f "$file" ]; then
    cat "$tmp_file" "$file" > "${file}.new"
    mv "${file}.new" "$file"
    rm -f "$tmp_file"
  else
    mv "$tmp_file" "$file"
  fi

  log_info "Changelog updated at $file"
  echo "true"
}
