#!/bin/bash
# ==========================================================
# pruebas/lib_pruebas.sh
# Herramientas para las pruebas de cada módulo.
# Al cargarse: crea una carpeta temporal, apunta ahí todas las rutas
# de datos (DATOS_DIR, LOG_FILE, RESPALDOS_DIR, SRV_DIR, CRON_*),
# carga lib/comunes.sh y borra la carpeta al terminar.
# Así las pruebas NUNCA tocan los datos reales.
# Uso al inicio de pruebas/probar_<modulo>.sh:
#     source "$(dirname "$0")/lib_pruebas.sh"
# ==========================================================

PRUEBAS_OK=0
PRUEBAS_FALLA=0
PRUEBA_DIR="$(mktemp -d)"
trap 'rm -rf "$PRUEBA_DIR"' EXIT

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATOS_DIR="$PRUEBA_DIR/datos"
LOG_FILE="$PRUEBA_DIR/logs/bitacora.log"
RESPALDOS_DIR="$PRUEBA_DIR/respaldos"
SRV_DIR="$PRUEBA_DIR/srv"
CRON_FIJAS="$PRUEBA_DIR/cron.d/abarrotes"
CRON_USUARIO="$PRUEBA_DIR/cron.d/abarrotes_usuario"
mkdir -p "$DATOS_DIR" "$RESPALDOS_DIR" "$SRV_DIR" "$(dirname "$LOG_FILE")" "$(dirname "$CRON_FIJAS")"

source "$BASE_DIR/lib/comunes.sh"

# ------------------------------------------
# verificar
# Ejecuta un comando y cuenta OK si regresa 0.
# Recibe: $1 descripción, luego el comando y sus argumentos
# Regresa: 0
# ------------------------------------------
verificar() {
    local descripcion="$1"; shift
    if "$@" >/dev/null 2>&1; then
        PRUEBAS_OK=$((PRUEBAS_OK + 1)); printf '  OK     %s\n' "$descripcion"
    else
        PRUEBAS_FALLA=$((PRUEBAS_FALLA + 1)); printf '  FALLA  %s\n' "$descripcion"
    fi
}

# ------------------------------------------
# esperar_falla
# Ejecuta un comando y cuenta OK si regresa distinto de 0.
# Recibe: $1 descripción, luego el comando y sus argumentos
# Regresa: 0
# ------------------------------------------
esperar_falla() {
    local descripcion="$1"; shift
    if "$@" >/dev/null 2>&1; then
        PRUEBAS_FALLA=$((PRUEBAS_FALLA + 1)); printf '  FALLA  %s (debía fallar)\n' "$descripcion"
    else
        PRUEBAS_OK=$((PRUEBAS_OK + 1)); printf '  OK     %s\n' "$descripcion"
    fi
}

# ------------------------------------------
# verificar_igual
# Compara un valor obtenido con el esperado.
# Recibe: $1 descripción, $2 esperado, $3 obtenido
# Regresa: 0
# ------------------------------------------
verificar_igual() {
    local descripcion="$1" esperado="$2" obtenido="$3"
    if [[ "$esperado" == "$obtenido" ]]; then
        PRUEBAS_OK=$((PRUEBAS_OK + 1)); printf '  OK     %s\n' "$descripcion"
    else
        PRUEBAS_FALLA=$((PRUEBAS_FALLA + 1))
        printf '  FALLA  %s\n         esperado: [%s]\n         obtenido: [%s]\n' "$descripcion" "$esperado" "$obtenido"
    fi
}

# ------------------------------------------
# es_root
# Indica si las pruebas corren como root (algunas lo necesitan).
# Recibe: nada
# Regresa: 0 si es root, 1 si no
# ------------------------------------------
es_root() { [[ "$EUID" -eq 0 ]]; }

# ------------------------------------------
# resumen
# Imprime el total de pruebas y sale con 1 si hubo fallas.
# Recibe: nada
# Regresa: sale con 0 si todo pasó, 1 si algo falló
# ------------------------------------------
resumen() {
    printf '\n  Resultado: %d OK, %d FALLA\n' "$PRUEBAS_OK" "$PRUEBAS_FALLA"
    (( PRUEBAS_FALLA == 0 )) && exit 0
    exit 1
}
