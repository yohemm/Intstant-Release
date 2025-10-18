#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paths.sh"
source "${LOGGER_SCRIPT}"

# ============================================================================
# GIT HELPERS
# ============================================================================

git_config_user() {
    local user_name="$1"
    local user_email="$2"
    
    log_info "Configuring git user: $user_name <$user_email>"
    
    git config user.name "$user_name"
    git config user.email "$user_email"
    
    log_debug "Git user configured"
}

git_get_commits_since_tag() {
    local last_tag="$1"
    
    if [[ -z "$last_tag" ]]; then
        log_debug "No last tag, getting all commits"
        git log --pretty=format:"%s%n%b" --all
    else
        log_debug "Getting commits since $last_tag"
        git log --pretty=format:"%s%n%b" "${last_tag}..HEAD"
    fi
}

git_get_last_tag() {
    local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -z "$last_tag" ]]; then
        log_debug "No previous tags found"
        return 1
    fi
    
    echo "$last_tag"
    log_debug "Last tag: $last_tag"
    return 0
}

git_tag_exists() {
    local tag="$1"
    
    if git rev-parse "$tag" >/dev/null 2>&1; then
        log_debug "Tag '$tag' exists"
        return 0
    else
        log_debug "Tag '$tag' does not exist"
        return 1
    fi
}

git_create_tag() {
    local tag="$1"
    local message="$2"
    local sign="${3:-false}"
    
    log_info "Creating tag: $tag"
    
    if [[ "$sign" == "true" ]]; then
        git tag -s "$tag" -m "$message"
    else
        git tag "$tag" -m "$message"
    fi
    
    log_debug "Tag '$tag' created"
}

git_push_tag() {
    local tag="$1"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dryrun "git push origin '$tag'"
        return 0
    fi
    
    log_info "Pushing tag: $tag"
    git push origin "$tag"
    log_success "Tag '$tag' pushed"
}

git_auto_commit() {
    local message="$1"
    local files="${2:-.}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dryrun "git add $files && git commit -m '$message'"
        return 0
    fi
    
    log_info "Auto-committing: $message"
    
    git add $files
    
    if git diff --cached --quiet; then
        log_warning "No changes to commit"
        return 0
    fi
    
    git commit -m "$message"
    log_success "Commit created"
}

git_auto_push() {
    local branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dryrun "git push origin $branch"
        return 0
    fi
    
    log_info "Pushing branch: $branch"
    git push origin "$branch"
    log_success "Branch '$branch' pushed"
}

git_get_commit_count() {
    local last_tag="$1"
    
    if [[ -z "$last_tag" ]]; then
        git rev-list --count HEAD
    else
        git rev-list --count "${last_tag}..HEAD"
    fi
}

git_get_changed_files() {
    local last_tag="$1"
    
    if [[ -z "$last_tag" ]]; then
        git diff --name-only --diff-filter=ACMTUXB | sort -u
    else
        git diff "${last_tag}..HEAD" --name-only --diff-filter=ACMTUXB | sort -u
    fi
}

git_get_contributors() {
    local last_tag="$1"
    
    if [[ -z "$last_tag" ]]; then
        git log --pretty=format:"%an" | sort -u
    else
        git log "${last_tag}..HEAD" --pretty=format:"%an" | sort -u
    fi
}