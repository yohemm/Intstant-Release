#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$TEST_DIR/../.." && pwd)"

# shellcheck source=../lib/assert.sh
. "$TEST_DIR/../lib/assert.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"

git init -q

git config user.name "Test"
git config user.email "test@example.com"

echo "a" > file.txt
git add file.txt
git commit -q -m "chore: init"

git tag v0.1.0

echo "b" > file.txt
git commit -q -am "feat: add feature"

OUTPUT_FILE="$TMP_DIR/out.txt"
CHANGELOG_FILE="$TMP_DIR/CHANGELOG.md"

IR_INITIAL_VERSION="v0.0.1" \
IR_GENERATE_CHANGELOG="true" \
IR_CHANGELOG_FILE="$CHANGELOG_FILE" \
IR_AUTO_COMMIT="false" \
IR_CREATE_TAGS="false" \
IR_DEBUG="false" \
DRY_RUN="true" \
GITHUB_REPOSITORY="local/test" \
GITHUB_OUTPUT="$OUTPUT_FILE" \
bash "$ROOT_DIR/scripts/poc/main.sh" > /dev/null

CHANGELOG_CONTENT="$(cat "$CHANGELOG_FILE")"
assert_contains "$CHANGELOG_CONTENT" "Compare changes: [v0.1.0...v0.2.0](https://github.com/local/test/compare/v0.1.0...v0.2.0)"

echo "ok - compare link generated"
