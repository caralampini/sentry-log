#!/usr/bin/env bash

set -uo pipefail

mostrar_grupos() {
  echo "Grupos de la empresa configurados:"
  while IFS=: read -r dept group path mode; do
    [[ -z "${dept:-}" || "$dept" =~ ^# ]] && continue
    echo "  $group ($dept)"
  done < config/departments.conf
  echo
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
  echo "Sentry Log - Menu de Administrador"
  echo "1) Preparar servidor"
  echo "2) Crear usuario"
  echo "3) Eliminar usuario"
  echo "4) Listar usuarios"
  echo "5) Crear grupo"
  echo "6) Eliminar grupo"
  echo "7) Agregar usuario a grupo"
  echo "8) Listar grupos"
  echo "9) Aplicar permisos"
  echo "10) Cambiar permisos de una ruta"
  echo "11) Ver intentos SSH fallidos"
  echo "12) Generar reporte"
  echo "13) Iniciar monitor"
  echo "14) Detener monitor"
  echo "15) Estado del monitor"
  echo "0) Salir"
  read -r -p "Opcion: " op

  case "$op" in
    1) sudo ./scripts/setup_server.sh ;;
    2) crear_usuario ;;
    3) read -r -p "Usuario: " u; sudo ./scripts/users.sh eliminar "$u" || true ;;
    4) ./scripts/users.sh listar ;;
    5) read -r -p "Grupo: " g; sudo ./scripts/users.sh grupo-crear "$g" || true ;;
    6) read -r -p "Grupo: " g; sudo ./scripts/users.sh grupo-eliminar "$g" || true ;;
    7) read -r -p "Usuario: " u; mostrar_grupos; read -r -p "Grupo: " g; sudo ./scripts/users.sh grupo-agregar "$u" "$g" || true ;;
    8) ./scripts/users.sh grupos ;;
    9) sudo ./scripts/permissions.sh aplicar ;;
    10) read -r -p "Ruta: " r; read -r -p "Grupo: " g; read -r -p "Modo: " m; sudo ./scripts/permissions.sh ruta "$r" "$g" "$m" ;;
    11) ./scripts/ssh_audit.sh ;;
    12) ./scripts/log_analyzer.sh ;;
    13) ./scripts/monitor.sh start ;;
    14) ./scripts/monitor.sh stop ;;
    15) ./scripts/monitor.sh status ;;
    0) exit 0 ;;
    *) echo "Opcion invalida" ;;
  esac

  read -r -p "Presiona Enter para continuar..." _
done
