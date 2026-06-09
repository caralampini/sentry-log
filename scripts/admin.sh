#!/usr/bin/env bash

set -uo pipefail

mostrar_grupos() {
  echo "Grupos de la empresa configurados:"
  while IFS=: read -r dept group path mode; do
    [[ -z "${dept:-}" || "$dept" =~ ^# ]] && continue
    echo "  $group ($dept) ruta=$path modo=$mode"
  done < config/departments.conf
  echo
}

ver_checksum() {
  echo "Generando checksums de archivos vigilados..."
  sudo ./scripts/monitor.sh init
  echo
  echo "Checksums actuales de archivos del sistema, configuracion y /empresa:"
  sudo cat runtime/state/checksums.db
}

crear_usuario() {
  local u g crear

  read -r -p "Usuario: " u
  mostrar_grupos
  read -r -p "Grupo: " g

  if ! getent group "$g" > /dev/null; then
    echo "El grupo '$g' no existe."
    read -r -p "Quieres crearlo ahora? [s/N]: " crear
    case "$crear" in
      s|S|si|SI)
        sudo ./scripts/users.sh grupo-crear "$g" || return
        ;;
      *)
        echo "Usuario no creado. Primero crea o elige un grupo existente."
        return
        ;;
    esac
  fi

  sudo ./scripts/users.sh crear "$u" "$g"
}

while true; do
  clear
  cat <<'EOF'
   _____ ______ _   _ _______ _______     __   _____ ____  _____  _____  
  / ____|  ____| \ | |__   __|  __ \ \   / /  / ____/ __ \|  __ \|  __ \ 
 | (___ | |__  |  \| |  | |  | |__) \ \_/ /  | |   | |  | | |__) | |__) |
  \___ \|  __| | . ` |  | |  |  _  / \   /   | |   | |  | |  _  /|  ___/ 
  ____) | |____| |\  |  | |  | | \ \  | |    | |___| |__| | | \ \| |     
 |_____/|______|_| \_|  |_|  |_|  \_\ |_|     \_____\____/|_|  \_\_|     

EOF
  echo "Sentry Log - Menu de Administrador"
  echo "1) Agregar usuario"
  echo "2) Eliminar usuario"
  echo "3) Agregar grupo"
  echo "4) Eliminar grupo"
  echo "5) Listar Usuarios"
  echo "6) Listar Grupos"
  echo "7) Ver intentos fallidos de acceso SSH"
  echo "8) Ver checksums de archivos vigilados"
  echo "9) Iniciar monitor en segundo plano"
  echo "10) Detener monitor"
  echo "11) Ver estado del monitor"
  echo "12) Ver bitacora del monitor"
  echo "13) Acceder a terminal"
  echo "14) Cerrar sesion"
  read -r -p "Opcion: " op

  case "$op" in
    1) crear_usuario ;;
    2) ./scripts/users.sh listar; read -r -p "Usuario a eliminar: " u; sudo ./scripts/users.sh eliminar "$u" || true ;;
    3) read -r -p "Grupo: " g; read -r -p "Ruta asignada (ej. /empresa/nuevo): " r; sudo ./scripts/users.sh grupo-crear "$g" "$r" || true ;;
    4) ./scripts/users.sh grupos; read -r -p "Grupo a eliminar: " g; sudo ./scripts/users.sh grupo-eliminar "$g" || true ;;
    5) ./scripts/users.sh listar ;;
    6) ./scripts/users.sh grupos ;;
    7) sudo ./scripts/ssh_audit.sh ;;
    8) ver_checksum ;;
    9) sudo ./scripts/monitor.sh start ;;
    10) sudo ./scripts/monitor.sh stop ;;
    11) sudo ./scripts/monitor.sh status ;;
    12) sudo ./scripts/monitor.sh log ;;
    13) bash ;;
    14) exit 0 ;;
    *) echo "Opcion invalida" ;;
  esac

  read -r -p "Presiona Enter para continuar..." _
done
