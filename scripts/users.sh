#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

cmd="${1:-}"
DEFAULT_PASSWORD="password123"
PASSWORDS_FILE="config/passwords.conf"

uso() {
  echo "Uso: users.sh crear <usuario> <grupo> | eliminar <usuario> | listar | cargar-config"
  echo "     users.sh grupo-crear <grupo> | grupo-eliminar <grupo> | grupo-agregar <usuario> <grupo> | grupos"
}

permitir_cambio_contrasena() {
  local user="$1"
  local sudoers_file="/etc/sudoers.d/sentry-passwords"
  local rule="$user ALL=(root) NOPASSWD: /app/scripts/users.sh cambiar-contrasena $user"

  touch "$sudoers_file"
  grep -qxF "$rule" "$sudoers_file" || echo "$rule" >> "$sudoers_file"
  chmod 0440 "$sudoers_file"
}

guardar_hash_contrasena() {
  local user="$1" hash tmp

  hash="$(getent shadow "$user" | cut -d: -f2)"
  [[ -n "$hash" ]] || return

  touch "$PASSWORDS_FILE"
  chmod 0600 "$PASSWORDS_FILE"
  tmp="$(mktemp)"
  grep -vE "^${user}:" "$PASSWORDS_FILE" > "$tmp" || true
  printf '%s:%s\n' "$user" "$hash" >> "$tmp"
  cp "$tmp" "$PASSWORDS_FILE"
  rm -f "$tmp"
}

restaurar_hash_contrasena() {
  local user="$1" hash

  [[ -f "$PASSWORDS_FILE" ]] || return 1
  hash="$(grep -E "^${user}:" "$PASSWORDS_FILE" | tail -n 1 | cut -d: -f2-)"
  [[ -n "$hash" ]] || return 1
  usermod -p "$hash" "$user"
}

aplicar_contrasena_usuario() {
  local user="$1"

  if ! restaurar_hash_contrasena "$user"; then
    echo "$user:$DEFAULT_PASSWORD" | chpasswd
    guardar_hash_contrasena "$user"
  fi
}

cambiar_contrasena() {
  local user="$1" pass1 pass2

  [[ "$EUID" -eq 0 ]] || { echo "Este cambio requiere permisos de administrador"; exit 1; }
  [[ -n "$user" ]] || { echo "Falta el usuario"; exit 1; }
  id "$user" > /dev/null 2>&1 || { echo "No existe el usuario $user"; exit 1; }

  read -r -s -p "Nueva contrasena: " pass1
  echo
  read -r -s -p "Repite la nueva contrasena: " pass2
  echo

  [[ -n "$pass1" ]] || { echo "La contrasena no puede estar vacia"; exit 1; }
  [[ "$pass1" == "$pass2" ]] || { echo "Las contrasenas no coinciden"; exit 1; }

  echo "$user:$pass1" | chpasswd
  guardar_hash_contrasena "$user"
  echo "Contrasena actualizada para $user"
}

crear_usuario() {
  local user="$1" group="$2"
  [[ -n "$user" && -n "$group" ]] || { echo "Falta usuario o grupo"; exit 1; }
  [[ "$user" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "Usuario invalido: $user"; exit 1; }
  [[ "$group" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "Grupo invalido: $group"; exit 1; }
  id "$user" > /dev/null 2>&1 && { echo "El usuario $user ya existe"; return; }
  getent group "$group" > /dev/null || { echo "No existe el grupo $group"; exit 1; }
  useradd -m -s /bin/bash -g "$group" "$user"
  aplicar_contrasena_usuario "$user"
  configurar_terminal_usuario "$user"
  echo "$user:$group" >> config/users.conf
  echo "Usuario creado: $user contrasena=$DEFAULT_PASSWORD"
}

configurar_terminal_usuario() {
  local user="$1" home grupos_usuario dept group path mode link

  home="$(getent passwd "$user" | cut -d: -f6)"
  [[ -n "$home" && -d "$home" ]] || return

  grupos_usuario=" $(id -nG "$user") "
  while IFS=: read -r dept group path mode; do
    [[ -z "${dept:-}" || "$dept" =~ ^# ]] && continue
    link="$home/$dept"

    [[ -L "$link" ]] && rm -f "$link"
    case "$grupos_usuario" in
      *" $group "*)
        [[ -d "$path" ]] && ln -s "$path" "$link"
        [[ -L "$link" ]] && chown -h "$user:$(id -gn "$user")" "$link"
        ;;
    esac
  done < config/departments.conf

  cat > "$home/.bash_profile" <<'PROFILE'
case "$-" in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

export PS1='\u [$(id -gn)] \w$ '

mostrar_ascii_grupo() {
  grupo_actual="$(id -gn)"
  case "$grupo_actual" in
    ventas)
      cat <<'EOF'
 __      ________ _   _ _______       _____ 
 \ \    / /  ____| \ | |__   __|/\   / ____|
  \ \  / /| |__  |  \| |  | |  /  \ | (___  
   \ \/ / |  __| | . ` |  | | / /\ \ \___ \ 
    \  /  | |____| |\  |  | |/ ____ \____) |
     \/   |______|_| \_|  |_/_/    \_\_____/ 
EOF
      ;;
    rh)
      cat <<'EOF'
  _____  _    _ 
 |  __ \| |  | |
 | |__) | |__| |
 |  _  /|  __  |
 | | \ \| |  | |
 |_|  \_\_|  |_|
EOF
      ;;
    ti)
      cat <<'EOF'
  _______ _____ 
 |__   __|_   _|
    | |    | |  
    | |    | |  
    | |   _| |_ 
    |_|  |_____|
EOF
      ;;
    finanzas)
      cat <<'EOF'
  ______ _____ _   _          _   _ ______          _____ 
 |  ____|_   _| \ | |   /\   | \ | |___  /   /\   / ____|
 | |__    | | |  \| |  /  \  |  \| |  / /   /  \ | (___  
 |  __|   | | | . ` | / /\ \ | . ` | / /   / /\ \ \___ \ 
 | |     _| |_| |\  |/ ____ \| |\  |/ /__ / ____ \____) |
 |_|    |_____|_| \_/_/    \_\_| \_/_____/_/    \_\_____/ 
EOF
      ;;
    direccion)
      cat <<'EOF'
  _____ _____ _____  ______ _____ _____ _____ ____  _   _ 
 |  __ \_   _|  __ \|  ____/ ____/ ____|_   _/ __ \| \ | |
 | |  | || | | |__) | |__ | |   | |      | || |  | |  \| |
 | |  | || | |  _  /|  __|| |   | |      | || |  | | . ` |
 | |__| || |_| | \ \| |___| |___| |____ _| || |__| | |\  |
 |_____/_____|_|  \_\______\_____\_____|_____\____/|_| \_|
EOF
      ;;
    *)
      echo "SENTRY.CORP - $grupo_actual"
      ;;
  esac
}

mostrar_rutas() {
  grupos_usuario=" $(id -nG) "
  echo "Rutas disponibles segun tus grupos:"
  while IFS=: read -r dept group path mode; do
    [ -z "$dept" ] && continue
    case "$dept" in \#*) continue ;; esac
    case "$grupos_usuario" in
      *" $group "*)
        echo "- $dept: $path"
        find "$path" -maxdepth 2 -type f 2>/dev/null | sed 's/^/    /'
        ;;
    esac
  done < /app/config/departments.conf
}

while true; do
  [ -n "${TERM:-}" ] && clear
  mostrar_ascii_grupo
  echo
  echo "Sentry.corp - Menu de Usuario"
  echo "Usuario: $USER | Grupos: $(id -nG)"
  echo "1) Ver mis rutas y archivos"
  echo "2) Cambiar mi contrasena"
  echo "3) Entrar a terminal"
  echo "4) Cerrar sesion"
  read -r -p "Opcion: " opcion

  case "$opcion" in
    1) mostrar_rutas; echo; echo "Consejo: ejecuta 'ls' en tu carpeta personal para ver accesos directos."; read -r -p "Presiona Enter para continuar..." _ ;;
    2) sudo /app/scripts/users.sh cambiar-contrasena "$USER"; read -r -p "Presiona Enter para continuar..." _ ;;
    3) [ -n "${TERM:-}" ] && clear; mostrar_rutas; echo; break ;;
    4) exit 0 ;;
    *) echo "Opcion invalida"; read -r -p "Presiona Enter para continuar..." _ ;;
  esac
done
PROFILE
  chown "$user:$(id -gn "$user")" "$home/.bash_profile"
  permitir_cambio_contrasena "$user"
}

crear_o_actualizar_grupo() {
  local group="$1" path="${2:-}" mode="${3:-2770}"

  [[ -n "$group" ]] || { echo "Falta el grupo"; exit 1; }
  [[ "$group" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "Grupo invalido: $group"; exit 1; }
  [[ -n "$path" ]] || path="/empresa/$group"
  getent group "$group" > /dev/null || groupadd "$group"

  mkdir -p "$path"
  chown root:"$group" "$path"
  chmod "$mode" "$path"
  if ! grep -qE "^[^:]+:${group}:" config/departments.conf; then
    printf '%s:%s:%s:%s\n' "$group" "$group" "$path" "$mode" >> config/departments.conf
  fi
  echo "Grupo creado: $group ruta=$path"
}

case "$cmd" in
  crear)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    crear_usuario "${2:-}" "${3:-}"
    ;;
  eliminar)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    userdel -r "${2:-}" 2>/dev/null || userdel "${2:-}"
    sed -i "/^${2:-}:/d" config/users.conf
    [[ -f "$PASSWORDS_FILE" ]] && sed -i "/^${2:-}:/d" "$PASSWORDS_FILE"
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
      aplicar_contrasena_usuario "$user"
      configurar_terminal_usuario "$user"
    done < config/users.conf
    ;;
  grupo-crear)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    crear_o_actualizar_grupo "${2:-}" "${3:-}" "${4:-2770}"
    ;;
  grupo-eliminar)
    [[ "$EUID" -eq 0 ]] || { echo "Usa sudo"; exit 1; }
    [[ -n "${2:-}" ]] || { echo "Falta el grupo"; exit 1; }
    sed -i "/^[^:]*:${2:-}:/d" config/departments.conf
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
    configurar_terminal_usuario "$user"
    echo "Usuario $user agregado al grupo $group"
    ;;
  grupos)
    while IFS=: read -r dept group path mode; do
      [[ -z "${dept:-}" || "$dept" =~ ^# ]] && continue
      if getent group "$group" > /dev/null; then estado="existe"; else estado="no existe"; fi
      echo "$group ruta=$path modo=$mode estado=$estado"
    done < config/departments.conf
    ;;
  cambiar-contrasena)
    cambiar_contrasena "${2:-}"
    ;;
  *) uso; exit 1 ;;
esac
