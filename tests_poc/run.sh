#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TEST_ROOT/integration/test_versioning_minor.sh"
bash "$TEST_ROOT/integration/test_versioning_major_tag.sh"
bash "$TEST_ROOT/integration/test_minor_over_fix.sh"
bash "$TEST_ROOT/integration/test_no_commits_since_tag.sh"
bash "$TEST_ROOT/integration/test_tag_push_with_remote.sh"
bash "$TEST_ROOT/integration/test_no_bump_nonconforming_commits.sh"
bash "$TEST_ROOT/integration/test_compare_link.sh"
bash "$TEST_ROOT/integration/test_changelog_sections.sh"
bash "$TEST_ROOT/integration/test_tag_exists_no_push.sh"
bash "$TEST_ROOT/integration/test_strict_dry_run_no_writes.sh"

echo "All tests passed"
