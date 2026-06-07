#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf

cmd="${1:-aplicar}"

aplicar_base() {
  while IFS=: read -r dept group path mode; do
    [[ -z "${dept:-}" || "$dept" =~ ^# ]] && continue
    chown root:"$group" "$path"
    chmod "$mode" "$path"
    ls -ld "$path"
  done < config/departments.conf
}

case "$cmd" in
  aplicar)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    aplicar_base
    ;;
  ruta)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    path="${2:-}"; group="${3:-}"; mode="${4:-}"
    chown root:"$group" "$path"
    chmod "$mode" "$path"
    ls -ld "$path"
    ;;
  listar)
    while IFS=: read -r dept group path mode; do
      [[ -z "${dept:-}" || "$dept" =~ ^# ]] && continue
      echo "$dept $path grupo=$group modo=$mode"
    done < config/departments.conf
    ;;
  *) echo "Uso: permissions.sh aplicar | ruta <ruta> <grupo> <modo> | listar"; exit 1 ;;
esac
