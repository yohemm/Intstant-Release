#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOUNT_DIR="$ROOT_DIR"

if command -v wslpath >/dev/null 2>&1; then
  MOUNT_DIR="$(wslpath -m "$ROOT_DIR")"
elif command -v cygpath >/dev/null 2>&1; then
  MOUNT_DIR="$(cygpath -m "$ROOT_DIR")"
fi

if [[ "$MOUNT_DIR" =~ ^([A-Za-z]): ]]; then
  drive="${BASH_REMATCH[1],,}"
  rest="${MOUNT_DIR:2}"
  rest="${rest//\\//}"
  MOUNT_DIR="/mnt/${drive}${rest}"
fi

IMAGE_NAME="instantrelease-poc-tests"
QUIET="false"

if [ "${1:-}" = "--quiet" ]; then
  QUIET="true"
fi

if [ "$QUIET" != "true" ]; then
  echo "Using mount path: $MOUNT_DIR"
fi

cd "$ROOT_DIR"

if [ "$QUIET" = "true" ]; then
  docker build -q -t "$IMAGE_NAME" -f tests_poc/Dockerfile .
else
  docker build -t "$IMAGE_NAME" -f tests_poc/Dockerfile .
fi

docker run --rm \
  -v "$MOUNT_DIR:/repo" \
  -w /repo \
  "$IMAGE_NAME"
