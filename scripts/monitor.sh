#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf

mkdir -p "$LOG_DIR" "$STATE_DIR" runtime/pids

generar_checksums() {
  while read -r item; do
    [[ -z "$item" || "$item" =~ ^# ]] && continue

    if [[ -d "$item" ]]; then
      find "$item" -type f -readable | sort | while read -r file; do
        "$CHECKSUM_BIN" "$file"
      done
    elif [[ -r "$item" ]]; then
      "$CHECKSUM_BIN" "$item"
    fi
  done < config/monitored_files.conf
}

guardar_checksums() {
  > "$CHECKSUM_DB"
  generar_checksums >> "$CHECKSUM_DB"
  echo "$(date '+%F %T') Checksums iniciales guardados" >> "$LOG_DIR/security.log"
}

vigilar() {
  trap 'echo "Monitor detenido" >> data/logs/security.log; exit 0' INT TERM
  [[ -f "$CHECKSUM_DB" ]] || guardar_checksums

  while true; do
    tmp="$(mktemp)"
    generar_checksums >> "$tmp"

    if ! diff -q "$CHECKSUM_DB" "$tmp" > /dev/null; then
      awk '
        NR == FNR { old[$2] = $1; next }
        !($2 in old) { print "NUEVO", $2; next }
        old[$2] != $1 { print "MODIFICADO", $2 }
        { seen[$2] = 1 }
        END {
          for (file in old) {
            if (!(file in seen)) {
              print "ELIMINADO", file
            }
          }
        }
      ' "$CHECKSUM_DB" "$tmp" | while read -r event file; do
        echo "$(date '+%F %T') ALERTA: $event $file" >> "$LOG_DIR/security.log"
      done
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
  log) [[ -f "$LOG_DIR/security.log" ]] && tail -n 20 "$LOG_DIR/security.log" || echo "Sin eventos del monitor" ;;
  *) echo "Uso: monitor.sh init | start | stop | status | log"; exit 1 ;;
esac
