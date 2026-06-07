#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="config/sentrylog.conf"
USERS_FILE="config/users.conf"

usage() {
  cat <<'EOF'
Uso: user_manager.sh <comando> [argumentos]

Comandos:
  list
      Muestra usuarios configurados y si existen en el sistema.

  exists <usuario>
      Verifica si un usuario existe en el sistema.

  create <usuario> <grupo_principal> [grupos_extra] [rol]
      Crea un usuario Linux y lo registra en config/users.conf.
      Use '-' para omitir grupos extra.

  delete <usuario> [--remove-home]
      Elimina un usuario Linux. No borra su home salvo con --remove-home.

  apply-config
      Crea los usuarios definidos en config/users.conf que aun no existan.

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
  printf '%s user_manager: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$ADMIN_LOG"
}

is_config_line() {
  local line="$1"

  [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]
}

validate_username() {
  local username="$1"

  if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    printf 'Error: nombre de usuario invalido: %s\n' "$username" >&2
    exit 1
  fi
}

validate_group_name() {
  local group="$1"

  if [[ ! "$group" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    printf 'Error: nombre de grupo invalido: %s\n' "$group" >&2
    exit 1
  fi
}

require_group_exists() {
  local group="$1"

  validate_group_name "$group"

  if ! getent group "$group" > /dev/null; then
    printf 'Error: el grupo %s no existe\n' "$group" >&2
    exit 1
  fi
}

require_extra_groups_exist() {
  local groups="$1"
  local group

  [[ "$groups" == "-" || -z "$groups" ]] && return 0

  IFS=',' read -ra group_list <<< "$groups"
  for group in "${group_list[@]}"; do
    require_group_exists "$group"
  done
}

user_exists() {
  local username="$1"

  id "$username" > /dev/null 2>&1
}

config_user_exists() {
  local username="$1"
  local line configured_user

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue
    IFS=':' read -r configured_user _ <<< "$line"

    if [[ "$configured_user" == "$username" ]]; then
      return 0
    fi
  done < "$USERS_FILE"

  return 1
}

append_user_config() {
  local username="$1"
  local primary_group="$2"
  local extra_groups="$3"
  local home_dir="$4"
  local shell="$5"
  local role="$6"

  if config_user_exists "$username"; then
    printf '[OK] Usuario %s ya existe en %s\n' "$username" "$USERS_FILE"
    return 0
  fi

  printf '%s:%s:%s:%s:%s:%s\n' \
    "$username" "$primary_group" "$extra_groups" "$home_dir" "$shell" "$role" >> "$USERS_FILE"
  printf '[OK] Usuario %s registrado en %s\n' "$username" "$USERS_FILE"
  log_action "usuario registrado en config: $username"
}

remove_user_config() {
  local username="$1"
  local line configured_user
  local removed=0
  local tmp_file

  tmp_file="$(mktemp)"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if ! is_config_line "$line"; then
      printf '%s\n' "$line" >> "$tmp_file"
      continue
    fi

    IFS=':' read -r configured_user _ <<< "$line"
    if [[ "$configured_user" == "$username" ]]; then
      removed=1
      continue
    fi

    printf '%s\n' "$line" >> "$tmp_file"
  done < "$USERS_FILE"

  mv "$tmp_file" "$USERS_FILE"

  if [[ "$removed" -eq 1 ]]; then
    printf '[OK] Usuario %s removido de %s\n' "$username" "$USERS_FILE"
    log_action "usuario removido de config: $username"
  else
    printf '[OK] Usuario %s no estaba registrado en %s\n' "$username" "$USERS_FILE"
  fi
}

create_system_user() {
  local username="$1"
  local primary_group="$2"
  local extra_groups="$3"
  local home_dir="$4"
  local shell="$5"

  validate_username "$username"
  require_group_exists "$primary_group"
  require_extra_groups_exist "$extra_groups"

  if user_exists "$username"; then
    printf '[OK] Usuario %s ya existe\n' "$username"
    return 0
  fi

  if [[ "$extra_groups" == "-" || -z "$extra_groups" ]]; then
    useradd -m -d "$home_dir" -s "$shell" -g "$primary_group" "$username"
  else
    useradd -m -d "$home_dir" -s "$shell" -g "$primary_group" -G "$extra_groups" "$username"
  fi

  printf '[OK] Usuario %s creado\n' "$username"
  log_action "usuario creado: $username grupo=$primary_group extras=$extra_groups home=$home_dir shell=$shell"
}

list_users() {
  local line username primary_group extra_groups home_dir shell role status

  printf 'Usuarios configurados:\n'

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r username primary_group extra_groups home_dir shell role <<< "$line"

    if user_exists "$username"; then
      status="existe"
    else
      status="no existe"
    fi

    printf '  %-12s grupo=%-16s extras=%-18s rol=%-16s estado=%s\n' \
      "$username" "$primary_group" "$extra_groups" "$role" "$status"
  done < "$USERS_FILE"
}

exists_command() {
  local username="${1:-}"

  if [[ -z "$username" ]]; then
    printf 'Error: falta usuario\n' >&2
    usage >&2
    exit 1
  fi

  validate_username "$username"

  if user_exists "$username"; then
    printf '[OK] Usuario %s existe\n' "$username"
    return 0
  fi

  printf '[FAIL] Usuario %s no existe\n' "$username"
  return 1
}

create_command() {
  local username="${1:-}"
  local primary_group="${2:-}"
  local extra_groups="${3:-empresa}"
  local role="${4:-usuario}"
  local home_dir shell

  if [[ -z "$username" || -z "$primary_group" ]]; then
    printf 'Error: create requiere usuario y grupo_principal\n' >&2
    usage >&2
    exit 1
  fi

  require_root
  home_dir="/home/$username"
  shell="/bin/bash"

  create_system_user "$username" "$primary_group" "$extra_groups" "$home_dir" "$shell"
  append_user_config "$username" "$primary_group" "$extra_groups" "$home_dir" "$shell" "$role"
}

delete_command() {
  local username="${1:-}"
  local remove_home="${2:-}"

  if [[ -z "$username" ]]; then
    printf 'Error: delete requiere usuario\n' >&2
    usage >&2
    exit 1
  fi

  require_root
  validate_username "$username"

  if [[ "$username" == "root" || "$username" == "$(id -un)" ]]; then
    printf 'Error: no se permite eliminar el usuario %s\n' "$username" >&2
    exit 1
  fi

  if ! user_exists "$username"; then
    printf '[OK] Usuario %s no existe\n' "$username"
    remove_user_config "$username"
    return 0
  fi

  case "$remove_home" in
    --remove-home)
      userdel -r "$username"
      log_action "usuario eliminado con home: $username"
      ;;
    "")
      userdel "$username"
      log_action "usuario eliminado sin borrar home: $username"
      ;;
    *)
      printf 'Error: opcion desconocida para delete: %s\n' "$remove_home" >&2
      exit 1
      ;;
  esac

  printf '[OK] Usuario %s eliminado\n' "$username"
  remove_user_config "$username"
}

apply_config() {
  local line username primary_group extra_groups home_dir shell role

  require_root

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_config_line "$line" || continue

    IFS=':' read -r username primary_group extra_groups home_dir shell role <<< "$line"
    create_system_user "$username" "$primary_group" "$extra_groups" "$home_dir" "$shell"
  done < "$USERS_FILE"
}

main() {
  local command="${1:-help}"

  load_config

  case "$command" in
    list)
      list_users
      ;;
    exists)
      exists_command "${2:-}"
      ;;
    create)
      create_command "${2:-}" "${3:-}" "${4:-empresa}" "${5:-usuario}"
      ;;
    delete)
      delete_command "${2:-}" "${3:-}"
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
