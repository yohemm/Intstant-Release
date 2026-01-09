#!/usr/bin/env bash

get_last_tag() {
  git describe --tags --abbrev=0 2>/dev/null || echo ""
}

collect_commits() {
  local last_tag="$1"
  local is_initial="$2"

  if [ "$is_initial" = "false" ]; then
    git log "${last_tag}..HEAD" --pretty=format:"%s%n%b"
  else
    git log HEAD --pretty=format:"%s%n%b"
  fi
}

parse_semver() {
  local tag="$1"
  local clean
  clean="$(echo "$tag" | sed 's/[^0-9.]*//g')"

  local major minor patch
  IFS='.' read -r major minor patch <<EOF
$clean
EOF

  echo "${major:-0} ${minor:-0} ${patch:-0}"
}

determine_bump() {
  local last_tag="$1"
  local commits="$2"

  local bump_type="none"
  local new_version="$last_tag"

  read -r major minor patch <<< "$(parse_semver "$last_tag")"

  if echo "$commits" | grep -E -q "($IR_BREAKING_PATTERN)"; then
    bump_type="major"
    major=$((major + 1))
    minor=0
    patch=0
  elif echo "$commits" | grep -E -q "^($IR_FEATURE_PATTERN)"; then
    bump_type="minor"
    minor=$((minor + 1))
    patch=0
  elif echo "$commits" | grep -E -q "^(${IR_FIX_PATTERN}|${IR_REFACTOR_PATTERN})"; then
    bump_type="patch"
    patch=$((patch + 1))
  fi

  new_version="v${major}.${minor}.${patch}"

  echo "$bump_type" "$new_version"
}
