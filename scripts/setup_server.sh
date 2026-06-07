#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf

if [[ "$EUID" -ne 0 ]]; then
  echo "Ejecuta este script con sudo"
  exit 1
fi

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$STATE_DIR" runtime/pids "$EMPRESA_DIR"

while IFS=: read -r dept group path mode; do
  [[ -z "${dept:-}" || "$dept" =~ ^# ]] && continue

  getent group "$group" > /dev/null || groupadd "$group"
  mkdir -p "$path"
  chown root:"$group" "$path"
  chmod "$mode" "$path"
  echo "OK: $dept -> $path ($group, $mode)"
done < config/departments.conf

echo "Servidor empresarial preparado en $EMPRESA_DIR"
