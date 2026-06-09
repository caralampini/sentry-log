#!/usr/bin/env bash

set -euo pipefail

source config/sentrylog.conf

if [[ "$EUID" -ne 0 ]]; then
  echo "Ejecuta este script con sudo"
  exit 1
fi

mkdir -p "$LOG_DIR" "$STATE_DIR" runtime/pids "$EMPRESA_DIR"

crear_archivos_demo() {
  local dept="$1" path="$2"

  case "$dept" in
    ventas)
      mkdir -p "$path/clientes" "$path/cotizaciones" "$path/metas"
      [[ -f "$path/clientes/clientes.txt" ]] || printf '%s\n' "Clientes activos del segundo trimestre" "Abarrotes del Centro" "Comercial del Norte" "Servicios Integrales SA" > "$path/clientes/clientes.txt"
      [[ -f "$path/cotizaciones/cotizaciones.txt" ]] || printf '%s\n' "Cotizacion Abarrotes del Centro: 45000" "Cotizacion Comercial del Norte: 38000" > "$path/cotizaciones/cotizaciones.txt"
      [[ -f "$path/metas/metas.txt" ]] || printf '%s\n' "Meta mensual: 120000" "Responsables: ana, carlos" > "$path/metas/metas.txt"
      ;;
    rh)
      mkdir -p "$path/empleados" "$path/nomina" "$path/politicas"
      [[ -f "$path/empleados/empleados.txt" ]] || printf '%s\n' "Empleados activos" "ana" "carlos" "maria" "sofia" > "$path/empleados/empleados.txt"
      [[ -f "$path/nomina/nomina.txt" ]] || printf '%s\n' "Nomina simulada" "maria: 18000" "sofia: 17500" > "$path/nomina/nomina.txt"
      [[ -f "$path/politicas/vacaciones.txt" ]] || printf '%s\n' "Politica de vacaciones" "Maximo 12 dias continuos" > "$path/politicas/vacaciones.txt"
      ;;
    ti)
      mkdir -p "$path/infraestructura" "$path/backups" "$path/incidentes"
      [[ -f "$path/infraestructura/servidores.txt" ]] || printf '%s\n' "Servidores internos" "app01 10.10.0.20" "db01 10.10.0.30" > "$path/infraestructura/servidores.txt"
      [[ -f "$path/backups/plan_backups.txt" ]] || printf '%s\n' "Respaldo diario: 02:00" "Respaldo semanal: domingo" > "$path/backups/plan_backups.txt"
      [[ -f "$path/incidentes/tareas.txt" ]] || printf '%s\n' "Pendiente: rotar llaves SSH" > "$path/incidentes/tareas.txt"
      ;;
    finanzas)
      mkdir -p "$path/presupuestos" "$path/facturas" "$path/reportes"
      [[ -f "$path/presupuestos/presupuesto.txt" ]] || printf '%s\n' "Presupuesto anual" "Infraestructura: 45000" "Capacitacion: 12000" > "$path/presupuestos/presupuesto.txt"
      [[ -f "$path/facturas/facturas.txt" ]] || printf '%s\n' "Facturas por revisar" "F-2026-001" "F-2026-002" > "$path/facturas/facturas.txt"
      [[ -f "$path/reportes/mensual.txt" ]] || printf '%s\n' "Reporte mensual" "Ingresos: 250000" "Egresos: 162000" > "$path/reportes/mensual.txt"
      ;;
    direccion)
      mkdir -p "$path/estrategia" "$path/reuniones" "$path/auditorias"
      [[ -f "$path/estrategia/plan.txt" ]] || printf '%s\n' "Plan estrategico" "Expansion regional" "Auditoria trimestral" > "$path/estrategia/plan.txt"
      [[ -f "$path/reuniones/agenda.txt" ]] || printf '%s\n' "Comite lunes 09:00" "Revision mensual viernes 12:00" > "$path/reuniones/agenda.txt"
      [[ -f "$path/auditorias/pendientes.txt" ]] || printf '%s\n' "Auditoria interna pendiente" > "$path/auditorias/pendientes.txt"
      ;;
    publico)
      mkdir -p "$path/avisos" "$path/compartido"
      [[ -f "$path/README.txt" ]] || printf '%s\n' "Bienvenido al servidor empresarial simulado." > "$path/README.txt"
      [[ -f "$path/avisos/permisos.txt" ]] || printf '%s\n' "Este directorio usa sticky bit: todos escriben, pero no borran archivos ajenos." > "$path/avisos/permisos.txt"
      ;;
    *)
      mkdir -p "$path/documentos"
      [[ -f "$path/documentos/README.txt" ]] || printf '%s\n' "Carpeta asignada al grupo $dept" > "$path/documentos/README.txt"
      ;;
  esac
}

while IFS=: read -r dept group path mode; do
  [[ -z "${dept:-}" || "$dept" =~ ^# ]] && continue

  getent group "$group" > /dev/null || groupadd "$group"
  mkdir -p "$path"
  crear_archivos_demo "$dept" "$path"
  chown root:"$group" "$path"
  chown -R root:"$group" "$path"
  chmod "$mode" "$path"
  chmod -R g+rwX "$path"
  find "$path" -type d -exec chmod g+s {} \;
  echo "Listo: $dept -> $path ($group, $mode)"
done < config/departments.conf

echo "Servidor empresarial preparado en $EMPRESA_DIR"
