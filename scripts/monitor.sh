#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf

mkdir -p "$LOG_DIR" "$STATE_DIR" runtime/pids

guardar_checksums() {
  > "$CHECKSUM_DB"
  while read -r file; do
    [[ -z "$file" || "$file" =~ ^# || ! -r "$file" ]] && continue
    "$CHECKSUM_BIN" "$file" >> "$CHECKSUM_DB"
  done < config/monitored_files.conf
}

vigilar() {
  trap 'echo "Monitor detenido" >> data/logs/security.log; exit 0' INT TERM
  [[ -f "$CHECKSUM_DB" ]] || guardar_checksums

  while true; do
    tmp="$(mktemp)"
    while read -r file; do
      [[ -z "$file" || "$file" =~ ^# || ! -r "$file" ]] && continue
      "$CHECKSUM_BIN" "$file" >> "$tmp"
    done < config/monitored_files.conf

    if ! diff -q "$CHECKSUM_DB" "$tmp" > /dev/null; then
      echo "$(date '+%F %T') ALERTA: cambio detectado en archivos vigilados" >> "$LOG_DIR/security.log"
      mv "$tmp" "$CHECKSUM_DB"
    else
      rm -f "$tmp"
    fi
    sleep "$MONITOR_INTERVAL"
  done
}

case "${1:-status}" in
  init) guardar_checksums; echo "Checksums iniciales guardados" ;;
  start) nohup "$0" run > /dev/null 2>&1 & echo $! > "$PID_FILE"; echo "Monitor iniciado" ;;
  run) vigilar ;;
  stop) [[ -f "$PID_FILE" ]] && kill "$(cat "$PID_FILE")" && rm -f "$PID_FILE" || echo "Monitor no iniciado" ;;
  status) [[ -f "$PID_FILE" ]] && echo "Monitor activo PID $(cat "$PID_FILE")" || echo "Monitor detenido" ;;
  *) echo "Uso: monitor.sh init | start | stop | status"; exit 1 ;;
esac
