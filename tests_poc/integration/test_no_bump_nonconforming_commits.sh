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
git commit -q -am "docs update"

OUTPUT_FILE="$TMP_DIR/out.txt"
CHANGELOG_FILE="$TMP_DIR/CHANGELOG.md"

IR_INITIAL_VERSION="v0.0.1" \
IR_GENERATE_CHANGELOG="true" \
IR_CHANGELOG_FILE="$CHANGELOG_FILE" \
IR_AUTO_COMMIT="false" \
IR_CREATE_TAGS="false" \
IR_DEBUG="false" \
IR_MISC_ENABLED="false" \
IR_STRICT_DRY_RUN="false" \
GITHUB_REPOSITORY="local/test" \
GITHUB_OUTPUT="$OUTPUT_FILE" \
bash "$ROOT_DIR/scripts/poc/main.sh" > /dev/null

VERSION="$(grep '^current-version=' "$OUTPUT_FILE" | cut -d= -f2-)"
BUMP="$(grep '^version-bump=' "$OUTPUT_FILE" | cut -d= -f2-)"
CHANGELOG_GENERATED="$(grep '^changelog-generated=' "$OUTPUT_FILE" | cut -d= -f2-)"

assert_eq "$VERSION" "v0.1.0"
assert_eq "$BUMP" "none"
assert_eq "$CHANGELOG_GENERATED" "false"

if [ -f "$CHANGELOG_FILE" ]; then
  fail "Changelog should not be written when misc is disabled"
fi

echo "ok - no bump and changelog unchanged"
