#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf
mkdir -p "$LOG_DIR"

if [[ ! -r "$SSH_LOG" ]]; then
  echo "No se puede leer $SSH_LOG"
  exit 1
fi

grep -E "Failed password|Invalid user" "$SSH_LOG" \
  | sed 's/  */ /g' \
  | awk '{print $1, $2, $3, "usuario=" $9, "ip=" $11}' \
  | tee "$LOG_DIR/ssh_audit.log"
