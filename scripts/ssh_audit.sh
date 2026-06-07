#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf
mkdir -p "$LOG_DIR"

if [[ ! -r "$SSH_LOG" ]]; then
  echo "No se puede leer $SSH_LOG"
  exit 1
fi

matches="$(grep -E "Failed password|Invalid user" "$SSH_LOG" || true)"

if [[ -z "$matches" ]]; then
  echo "Sin intentos fallidos encontrados" | tee "$LOG_DIR/ssh_audit.log"
  exit 0
fi

printf '%s\n' "$matches" \
  | sed 's/  */ /g' \
  | awk '{print $1, $2, $3, "usuario=" $9, "ip=" $11}' \
  | tee "$LOG_DIR/ssh_audit.log"
