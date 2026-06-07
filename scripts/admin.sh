#!/usr/bin/env bash

set -euo pipefail

while true; do
  clear
  echo "Sentry Log - Menu de Administrador"
  echo "1) Preparar servidor"
  echo "2) Crear usuario"
  echo "3) Eliminar usuario"
  echo "4) Listar usuarios"
  echo "5) Aplicar permisos"
  echo "6) Ver intentos SSH fallidos"
  echo "7) Generar reporte"
  echo "8) Iniciar monitor"
  echo "9) Detener monitor"
  echo "10) Estado del monitor"
  echo "0) Salir"
  read -r -p "Opcion: " op

  case "$op" in
    1) sudo ./scripts/setup_server.sh ;;
    2) read -r -p "Usuario: " u; read -r -p "Grupo: " g; sudo ./scripts/users.sh crear "$u" "$g" ;;
    3) read -r -p "Usuario: " u; sudo ./scripts/users.sh eliminar "$u" ;;
    4) ./scripts/users.sh listar ;;
    5) sudo ./scripts/permissions.sh aplicar ;;
    6) ./scripts/ssh_audit.sh ;;
    7) ./scripts/log_analyzer.sh ;;
    8) ./scripts/monitor.sh start ;;
    9) ./scripts/monitor.sh stop ;;
    10) ./scripts/monitor.sh status ;;
    0) exit 0 ;;
    *) echo "Opcion invalida" ;;
  esac

  read -r -p "Presiona Enter para continuar..." _
done
