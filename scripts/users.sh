#!/usr/bin/env bash

set -euo pipefail

cmd="${1:-}"

uso() {
  echo "Uso: users.sh crear <usuario> <grupo> | eliminar <usuario> | listar | cargar-config"
}

crear_usuario() {
  local user="$1" group="$2"
  id "$user" > /dev/null 2>&1 && { echo "El usuario $user ya existe"; return; }
  getent group "$group" > /dev/null || { echo "No existe el grupo $group"; exit 1; }
  useradd -m -s /bin/bash -g "$group" "$user"
  echo "$user:$group" >> config/users.conf
  echo "Usuario creado: $user"
}

case "$cmd" in
  crear)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    crear_usuario "${2:-}" "${3:-}"
    ;;
  eliminar)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    userdel "${2:-}"
    sed -i "/^${2:-}:/d" config/users.conf
    echo "Usuario eliminado: ${2:-}"
    ;;
  listar)
    while IFS=: read -r user group; do
      [[ -z "${user:-}" || "$user" =~ ^# ]] && continue
      if id "$user" > /dev/null 2>&1; then estado="existe"; else estado="no existe"; fi
      echo "$user grupo=$group estado=$estado"
    done < config/users.conf
    ;;
  cargar-config)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    while IFS=: read -r user group; do
      [[ -z "${user:-}" || "$user" =~ ^# ]] && continue
      id "$user" > /dev/null 2>&1 || useradd -m -s /bin/bash -g "$group" "$user"
    done < config/users.conf
    ;;
  *) uso; exit 1 ;;
esac
