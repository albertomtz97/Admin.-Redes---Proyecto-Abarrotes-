#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$BASE_DIR/logs/bitacora.log"

registrar() {
    echo "$(date '+%F %T') | ${SUDO_USER:-$USER} | $1" >> "$LOG_FILE"
}

pausa() {
    read -rp "Presiona Enter para continuar..."
}

verificar_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Este script debe ejecutarse como root (usa sudo)."
        exit 1
    fi
}
