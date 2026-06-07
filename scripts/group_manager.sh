#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="config/sentrylog.conf"
DEPARTMENTS_FILE="config/departments.conf"

usage() {
  cat <<'EOF'
Uso: group_manager.sh <comando> [argumentos]

Comandos:
  list
      Muestra departamentos configurados y estado del grupo Linux.

  exists <grupo>
      Verifica si un grupo existe en el sistema.

  create <departamento> [grupo] [ruta] [descripcion]
      Crea un grupo/departamento y lo registra en config/departments.conf.

  delete <departamento|grupo>
      Elimina un grupo Linux y remueve su registro de config/departments.conf.

  add-user <usuario> <grupo>
      Agrega un usuario existente a un grupo existente.

  remove-user <usuario> <grupo>
      Quita un usuario de un grupo.

  apply-config
      Crea los grupos definidos en config/departments.conf que aun no existan.

  help
      Muestra esta ayuda.
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
    printf 'Error: este comando debe ejecutarse como root\n' >&2
    exit 1
  fi
}

ensure_runtime_dirs() {
  mkdir -p "$LOG_DIR" "$REPORT_DIR" "$PID_DIR" "$STATE_DIR"
}

log_action() {
  local message="$1"

  ensure_runtime_dirs
  printf '%s group_manager: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$ADMIN_LOG"
}

is_config_line() {
  local line="$1"

  [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]
}

validate_name() {
  local kind="$1"
  local value="$2"

  if [[ ! "$value" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    printf 'Error: nombre de %s invalido: %s\n' "$kind" "$value" >&2
    exit 1
  fi
}

group_exists() {
  local group="$1"

  getent group "$group" > /dev/null
}

user_exists() {
  local username="$1"

  id "$username" > /dev/null 2>&1
}

department_config_exists() {
  local department="$1"
  local group="$2"
  local line configured_department configured_group

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue
    IFS=':' read -r configured_department configured_group _ <<< "$line"

    if [[ "$configured_department" == "$department" || "$configured_group" == "$group" ]]; then
      return 0
    fi
  done < "$DEPARTMENTS_FILE"

  return 1
}

append_department_config() {
  local department="$1"
  local group="$2"
  local path="$3"
  local description="$4"

  if department_config_exists "$department" "$group"; then
    printf '[OK] Departamento/grupo %s ya existe en %s\n' "$department" "$DEPARTMENTS_FILE"
    return 0
  fi

  printf '%s:%s:%s:%s\n' "$department" "$group" "$path" "$description" >> "$DEPARTMENTS_FILE"
  printf '[OK] Departamento %s registrado en %s\n' "$department" "$DEPARTMENTS_FILE"
  log_action "departamento registrado en config: $department grupo=$group ruta=$path"
}

remove_department_config() {
  local name="$1"
  local line configured_department configured_group
  local removed=0
  local tmp_file

  tmp_file="$(mktemp)"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if ! is_config_line "$line"; then
      printf '%s\n' "$line" >> "$tmp_file"
      continue
    fi

    IFS=':' read -r configured_department configured_group _ <<< "$line"
    if [[ "$configured_department" == "$name" || "$configured_group" == "$name" ]]; then
      removed=1
      continue
    fi

    printf '%s\n' "$line" >> "$tmp_file"
  done < "$DEPARTMENTS_FILE"

  mv "$tmp_file" "$DEPARTMENTS_FILE"

  if [[ "$removed" -eq 1 ]]; then
    printf '[OK] %s removido de %s\n' "$name" "$DEPARTMENTS_FILE"
    log_action "departamento removido de config: $name"
  else
    printf '[OK] %s no estaba registrado en %s\n' "$name" "$DEPARTMENTS_FILE"
  fi
}

create_system_group() {
  local group="$1"

  validate_name "grupo" "$group"

  if group_exists "$group"; then
    printf '[OK] Grupo %s ya existe\n' "$group"
    return 0
  fi

  groupadd "$group"
  printf '[OK] Grupo %s creado\n' "$group"
  log_action "grupo creado: $group"
}

list_groups() {
  local line department group path description status members

  printf 'Departamentos configurados:\n'

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r department group path description <<< "$line"

    if group_exists "$group"; then
      status="existe"
      members="$(getent group "$group" | cut -d ':' -f 4)"
      [[ -z "$members" ]] && members="-"
    else
      status="no existe"
      members="-"
    fi

    printf '  %-16s grupo=%-16s ruta=%-28s estado=%-9s miembros=%s\n' \
      "$department" "$group" "$path" "$status" "$members"
  done < "$DEPARTMENTS_FILE"
}

exists_command() {
  local group="${1:-}"

  if [[ -z "$group" ]]; then
    printf 'Error: falta grupo\n' >&2
    usage >&2
    exit 1
  fi

  validate_name "grupo" "$group"

  if group_exists "$group"; then
    printf '[OK] Grupo %s existe\n' "$group"
    return 0
  fi

  printf '[FAIL] Grupo %s no existe\n' "$group"
  return 1
}

create_command() {
  local department="${1:-}"
  local group="${2:-}"
  local path="${3:-}"
  local description="${4:-Departamento creado por el administrador}"

  if [[ -z "$department" ]]; then
    printf 'Error: create requiere departamento\n' >&2
    usage >&2
    exit 1
  fi

  require_root
  validate_name "departamento" "$department"

  [[ -z "$group" ]] && group="$department"
  [[ -z "$path" ]] && path="$COMPANY_ROOT/$department"

  validate_name "grupo" "$group"
  create_system_group "$group"
  append_department_config "$department" "$group" "$path" "$description"
}

delete_command() {
  local name="${1:-}"

  if [[ -z "$name" ]]; then
    printf 'Error: delete requiere departamento o grupo\n' >&2
    usage >&2
    exit 1
  fi

  require_root
  validate_name "grupo" "$name"

  if group_exists "$name"; then
    groupdel "$name"
    printf '[OK] Grupo %s eliminado\n' "$name"
    log_action "grupo eliminado: $name"
  else
    printf '[OK] Grupo %s no existe\n' "$name"
  fi

  remove_department_config "$name"
}

add_user_command() {
  local username="${1:-}"
  local group="${2:-}"

  if [[ -z "$username" || -z "$group" ]]; then
    printf 'Error: add-user requiere usuario y grupo\n' >&2
    usage >&2
    exit 1
  fi

  require_root
  validate_name "usuario" "$username"
  validate_name "grupo" "$group"

  if ! user_exists "$username"; then
    printf 'Error: el usuario %s no existe\n' "$username" >&2
    exit 1
  fi

  if ! group_exists "$group"; then
    printf 'Error: el grupo %s no existe\n' "$group" >&2
    exit 1
  fi

  usermod -aG "$group" "$username"
  printf '[OK] Usuario %s agregado al grupo %s\n' "$username" "$group"
  log_action "usuario agregado a grupo: $username -> $group"
}

remove_user_command() {
  local username="${1:-}"
  local group="${2:-}"

  if [[ -z "$username" || -z "$group" ]]; then
    printf 'Error: remove-user requiere usuario y grupo\n' >&2
    usage >&2
    exit 1
  fi

  require_root
  validate_name "usuario" "$username"
  validate_name "grupo" "$group"

  if ! user_exists "$username"; then
    printf 'Error: el usuario %s no existe\n' "$username" >&2
    exit 1
  fi

  if ! group_exists "$group"; then
    printf 'Error: el grupo %s no existe\n' "$group" >&2
    exit 1
  fi

  gpasswd -d "$username" "$group" > /dev/null
  printf '[OK] Usuario %s removido del grupo %s\n' "$username" "$group"
  log_action "usuario removido de grupo: $username -> $group"
}

apply_config() {
  local line department group path description

  require_root

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r department group path description <<< "$line"
    create_system_group "$group"
  done < "$DEPARTMENTS_FILE"
}

main() {
  local command="${1:-help}"

  load_config

  case "$command" in
    list)
      list_groups
      ;;
    exists)
      exists_command "${2:-}"
      ;;
    create)
      create_command "${2:-}" "${3:-}" "${4:-}" "${5:-Departamento creado por el administrador}"
      ;;
    delete)
      delete_command "${2:-}"
      ;;
    add-user)
      add_user_command "${2:-}" "${3:-}"
      ;;
    remove-user)
      remove_user_command "${2:-}" "${3:-}"
      ;;
    apply-config)
      apply_config
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
