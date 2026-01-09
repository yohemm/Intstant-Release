#!/usr/bin/env bash

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*" >&2
}

log_debug() {
  if [ "${IR_DEBUG:-false}" = "true" ]; then
    echo "[DEBUG] $*"
  fi
}
