#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf
mkdir -p "$LOG_DIR"

if [[ ! -r "$SSH_LOG" ]]; then
  SSH_LOG="$LOG_DIR/ssh_demo.log"
  if [[ ! -f "$SSH_LOG" ]]; then
    cat > "$SSH_LOG" <<'EOF'
Jun 09 10:12:01 hermes sshd[101]: Failed password for ana from 192.168.1.20 port 55231 ssh2
Jun 09 10:15:44 hermes sshd[102]: Invalid user hacker from 192.168.1.88 port 40122
Jun 09 10:18:09 hermes sshd[103]: Failed password for carlos from 192.168.1.33 port 60010 ssh2
EOF
  fi
  echo "Aviso: usando bitacora simulada $SSH_LOG"
fi

matches="$(grep -E "Failed password|Invalid user" "$SSH_LOG" || true)"

if [[ -z "$matches" ]]; then
  echo "Sin intentos fallidos encontrados" | tee "$LOG_DIR/ssh_audit.log"
  exit 0
fi

printf '%s\n' "$matches" \
  | sed 's/  */ /g' \
  | awk '/Failed password/ {print $1, $2, $3, "usuario=" $9, "ip=" $11} /Invalid user/ {print $1, $2, $3, "usuario=" $8, "ip=" $10}' \
  | tee "$LOG_DIR/ssh_audit.log"
