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
git commit -q -am "fix: bug"

BARE_DIR="$TMP_DIR/remote.git"
git init -q --bare "$BARE_DIR"

git remote add origin "$BARE_DIR"

git push -q origin HEAD

git push -q origin v0.1.0

# Run once to create v0.1.1
OUTPUT_FILE_1="$TMP_DIR/out1.txt"

IR_INITIAL_VERSION="v0.0.1" \
IR_GENERATE_CHANGELOG="false" \
IR_AUTO_COMMIT="false" \
IR_CREATE_TAGS="true" \
IR_DEBUG="false" \
DRY_RUN="false" \
GITHUB_OUTPUT="$OUTPUT_FILE_1" \
bash "$ROOT_DIR/scripts/poc/main.sh" > /dev/null

TAG_CREATED_1="$(grep '^tag-created=' "$OUTPUT_FILE_1" | cut -d= -f2-)"
assert_eq "$TAG_CREATED_1" "true"

REMOTE_TAGS_AFTER_1="$(git --git-dir "$BARE_DIR" tag -l)"
assert_contains "$REMOTE_TAGS_AFTER_1" "v0.1.1"

# Run again with no new commits, tag should exist
OUTPUT_FILE_2="$TMP_DIR/out2.txt"

IR_INITIAL_VERSION="v0.0.1" \
IR_GENERATE_CHANGELOG="false" \
IR_AUTO_COMMIT="false" \
IR_CREATE_TAGS="true" \
IR_DEBUG="false" \
DRY_RUN="false" \
GITHUB_OUTPUT="$OUTPUT_FILE_2" \
bash "$ROOT_DIR/scripts/poc/main.sh" > /dev/null

TAG_CREATED_2="$(grep '^tag-created=' "$OUTPUT_FILE_2" | cut -d= -f2-)"
assert_eq "$TAG_CREATED_2" "false"

REMOTE_TAGS_AFTER_2="$(git --git-dir "$BARE_DIR" tag -l)"
assert_contains "$REMOTE_TAGS_AFTER_2" "v0.1.1"

echo "ok - tag exists no push"
