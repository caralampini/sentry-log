#!/usr/bin/env bash

set -euo pipefail

cmd="${1:-}"

uso() {
  echo "Uso: users.sh crear <usuario> <grupo> | eliminar <usuario> | listar | cargar-config"
  echo "     users.sh grupo-crear <grupo> | grupo-eliminar <grupo> | grupo-agregar <usuario> <grupo> | grupos"
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
  grupo-crear)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    group="${2:-}"
    [[ -n "$group" ]] || { echo "Falta el grupo"; exit 1; }
    getent group "$group" > /dev/null && { echo "El grupo $group ya existe"; exit 0; }
    groupadd "$group"
    echo "Grupo creado: $group"
    ;;
  grupo-eliminar)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    [[ -n "${2:-}" ]] || { echo "Falta el grupo"; exit 1; }
    groupdel "${2:-}"
    echo "Grupo eliminado: ${2:-}"
    ;;
  grupo-agregar)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    user="${2:-}"; group="${3:-}"
    [[ -n "$user" && -n "$group" ]] || { echo "Falta usuario o grupo"; exit 1; }
    id "$user" > /dev/null 2>&1 || { echo "No existe el usuario $user"; exit 1; }
    getent group "$group" > /dev/null || { echo "No existe el grupo $group"; exit 1; }
    usermod -aG "$group" "$user"
    echo "Usuario $user agregado al grupo $group"
    ;;
  grupos)
    cut -d: -f1 /etc/group
    ;;
  *) uso; exit 1 ;;
esac
