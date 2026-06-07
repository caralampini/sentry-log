#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf
mkdir -p "$REPORT_DIR"

report="$REPORT_DIR/reporte_general.txt"

{
  echo "Reporte Sentry Log - $(date)"
  echo
  echo "Usuarios configurados:"
  ./scripts/users.sh listar
  echo
  echo "Permisos configurados:"
  ./scripts/permissions.sh listar
  echo
  echo "Ultimas alertas de seguridad:"
  [[ -f "$LOG_DIR/security.log" ]] && tail -n 10 "$LOG_DIR/security.log" || echo "Sin alertas"
  echo
  echo "Intentos SSH registrados:"
  [[ -f "$LOG_DIR/ssh_audit.log" ]] && tail -n 10 "$LOG_DIR/ssh_audit.log" || echo "Sin auditoria SSH"
} > "$report"

echo "Reporte generado: $report"
