#!/bin/bash
# ==========================================================
# menu.sh
# Punto de entrada del sistema: sudo ./menu.sh
# Carga la librería común y los módulos que existan, y muestra
# el menú principal. Si un módulo todavía no existe, su opción
# avisa "Módulo no disponible todavía" en lugar de fallar.
# Spec: docs/specs/0001-sistema-abarrotes/0002-base.md
# ==========================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/comunes.sh"

for modulo in gestion tareas respaldo seguridad; do
    if [[ -f "$DIR/modulos/$modulo.sh" ]]; then
        source "$DIR/modulos/$modulo.sh"
    fi
done
unset modulo

# ------------------------------------------
# base_abrir_modulo
# Abre el menú de un módulo si su función menu_<modulo> existe.
# Recibe: $1 nombre del módulo (gestion, tareas, respaldo, seguridad)
# Regresa: 0
# ------------------------------------------
base_abrir_modulo() {
    local modulo="$1"
    if declare -F "menu_$modulo" >/dev/null; then
        "menu_$modulo"
    else
        ui_mensaje "Módulo no disponible todavía."
    fi
    return 0
}

# ------------------------------------------
# base_ver_bitacora
# Muestra la bitácora completa o solo las líneas de un módulo.
# Recibe: nada (pregunta el filtro)
# Regresa: 0
# ------------------------------------------
base_ver_bitacora() {
    local filtro temporal
    if [[ ! -s "$LOG_FILE" ]]; then
        ui_mensaje "La bitácora está vacía."
        return 0
    fi
    filtro=$(ui_menu "VER BITÁCORA" \
        todo "Todo" \
        base "Base (instalación)" \
        gestion "Gestión" \
        tareas "Tareas" \
        respaldo "Respaldo" \
        seguridad "Seguridad") || return 0

    if [[ "$filtro" == todo ]]; then
        ui_archivo "$LOG_FILE"
        return 0
    fi
    temporal=$(mktemp) || return 0
    # Formato: fecha | usuario | modulo | mensaje  (el módulo es el campo 3)
    awk -F' [|] ' -v m="$filtro" '$3 == m' "$LOG_FILE" > "$temporal"
    if [[ -s "$temporal" ]]; then
        ui_archivo "$temporal"
    else
        ui_mensaje "No hay registros del módulo $filtro."
    fi
    rm -f "$temporal"
}

# ------------------------------------------
# base_principal
# Revisa root, prepara carpetas y archivos de datos, y muestra el
# menú principal hasta que el usuario elige Salir.
# Recibe: nada
# Regresa: 0 al salir
# ------------------------------------------
base_principal() {
    local opcion
    verificar_root
    mkdir -p "$DATOS_DIR" "$(dirname "$LOG_FILE")" "$RESPALDOS_DIR"
    chmod 700 "$RESPALDOS_DIR"
    csv_asegurar "$CSV_USUARIOS" "$ENC_USUARIOS"
    csv_asegurar "$CSV_GRUPOS" "$ENC_GRUPOS"
    csv_asegurar "$CSV_PAGOS" "$ENC_PAGOS"
    csv_asegurar "$CSV_RESPALDOS" "$ENC_RESPALDOS"

    while true; do
        opcion=$(UI_TEXTO_CERO="Salir" ui_menu "ADMINISTRACIÓN · TIENDA DE ABARROTES" \
            gestion "Gestión (usuarios y grupos)" \
            tareas "Tareas (cron y at)" \
            respaldo "Respaldo (tar gzip / bzip2, rsync)" \
            seguridad "Seguridad (Nagios, Wireshark, nmap)" \
            bitacora "Ver bitácora") || break
        case "$opcion" in
            bitacora) base_ver_bitacora ;;
            *) base_abrir_modulo "$opcion" ;;
        esac
    done
    printf 'Hasta luego.\n' >&2
}

base_principal
