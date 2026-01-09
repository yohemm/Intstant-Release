#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TEST_ROOT/integration/test_versioning_minor.sh"
bash "$TEST_ROOT/integration/test_versioning_major_tag.sh"
bash "$TEST_ROOT/integration/test_no_commits_since_tag.sh"
bash "$TEST_ROOT/integration/test_tag_push_with_remote.sh"

echo "All tests passed"
