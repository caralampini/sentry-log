#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="config/sentrylog.conf"
DEPARTMENTS_FILE="config/departments.conf"
PERMISSIONS_FILE="config/permissions.conf"

usage() {
  cat <<'EOF'
Uso: provision_departments.sh <comando>

Comandos:
  list    Muestra los departamentos configurados
  check   Valida grupos, directorios y permisos sin modificar el sistema
  apply   Crea grupos/directorios y aplica permisos configurados
  help    Muestra esta ayuda
EOF
}

load_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    printf 'Error: no existe %s\n' "$CONFIG_FILE" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    printf 'Error: el comando apply debe ejecutarse como root\n' >&2
    exit 1
  fi
}

ensure_runtime_dirs() {
  mkdir -p "$LOG_DIR" "$REPORT_DIR" "$PID_DIR" "$STATE_DIR"
}

log_action() {
  local message="$1"

  ensure_runtime_dirs
  printf '%s provision_departments: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$ADMIN_LOG"
}

is_config_line() {
  local line="$1"

  [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]
}

validate_group_name() {
  local group="$1"

  if [[ ! "$group" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    printf 'Error: nombre de grupo invalido: %s\n' "$group" >&2
    exit 1
  fi
}

ensure_group() {
  local group="$1"

  validate_group_name "$group"

  if getent group "$group" > /dev/null; then
    printf '[OK] Grupo %s ya existe\n' "$group"
    return 0
  fi

  groupadd "$group"
  printf '[OK] Grupo %s creado\n' "$group"
  log_action "grupo creado: $group"
}

ensure_directory() {
  local path="$1"

  if [[ -d "$path" ]]; then
    printf '[OK] Directorio %s ya existe\n' "$path"
    return 0
  fi

  mkdir -p "$path"
  printf '[OK] Directorio %s creado\n' "$path"
  log_action "directorio creado: $path"
}

apply_permission_rule() {
  local path="$1"
  local owner="$2"
  local group="$3"
  local mode="$4"
  local flag="$5"

  if [[ ! -d "$path" && ! -f "$path" ]]; then
    printf '[WARN] No existe %s; se omiten permisos\n' "$path" >&2
    return 0
  fi

  validate_group_name "$group"
  chown "$owner:$group" "$path"
  chmod "$mode" "$path"

  case "$flag" in
    normal|sgid|sticky)
      ;;
    *)
      printf '[WARN] Bandera desconocida para %s: %s\n' "$path" "$flag" >&2
      ;;
  esac

  printf '[OK] Permisos %s %s:%s aplicados a %s\n' "$mode" "$owner" "$group" "$path"
  log_action "permisos aplicados: $path $owner:$group $mode $flag"
}

list_departments() {
  local line department group path description

  printf 'Departamentos configurados:\n'

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r department group path description <<< "$line"
    printf '  %-16s grupo=%-16s ruta=%s\n' "$department" "$group" "$path"
  done < "$DEPARTMENTS_FILE"
}

check_departments() {
  local line department group path description
  local missing=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r department group path description <<< "$line"

    if getent group "$group" > /dev/null; then
      printf '[OK] Grupo %s existe\n' "$group"
    else
      printf '[FAIL] Grupo %s no existe\n' "$group"
      missing=1
    fi

    if [[ -d "$path" ]]; then
      printf '[OK] Directorio %s existe\n' "$path"
    else
      printf '[FAIL] Directorio %s no existe\n' "$path"
      missing=1
    fi
  done < "$DEPARTMENTS_FILE"

  return "$missing"
}

check_permissions() {
  local line path owner group mode flag description
  local current_owner current_group current_mode
  local missing=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r path owner group mode flag description <<< "$line"

    if [[ ! -e "$path" ]]; then
      printf '[FAIL] No existe %s para validar permisos\n' "$path"
      missing=1
      continue
    fi

    current_owner="$(stat -c '%U' "$path")"
    current_group="$(stat -c '%G' "$path")"
    current_mode="$(stat -c '%a' "$path")"

    if [[ "$current_owner" == "$owner" && "$current_group" == "$group" && "$current_mode" == "${mode#0}" ]]; then
      printf '[OK] %s tiene permisos esperados %s %s:%s\n' "$path" "$mode" "$owner" "$group"
    else
      printf '[FAIL] %s esperado=%s %s:%s actual=%s %s:%s\n' \
        "$path" "$mode" "$owner" "$group" "$current_mode" "$current_owner" "$current_group"
      missing=1
    fi
  done < "$PERMISSIONS_FILE"

  return "$missing"
}

apply_departments() {
  local line department group path description

  ensure_runtime_dirs

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r department group path description <<< "$line"
    ensure_group "$group"
    ensure_directory "$path"
  done < "$DEPARTMENTS_FILE"
}

apply_permissions() {
  local line path owner group mode flag description

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r path owner group mode flag description <<< "$line"
    apply_permission_rule "$path" "$owner" "$group" "$mode" "$flag"
  done < "$PERMISSIONS_FILE"
}

main() {
  local command="${1:-help}"
  local status=0

  load_config

  case "$command" in
    list)
      list_departments
      ;;
    check)
      check_departments || status=1
      check_permissions || status=1
      return "$status"
      ;;
    apply)
      require_root
      apply_departments
      apply_permissions
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      printf 'Error: comando desconocido: %s\n' "$command" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
