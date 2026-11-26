#!/bin/bash
# ==========================================================
# pruebas/correr_todas.sh
# Corre todos los pruebas/probar_*.sh y muestra un resumen.
# Sale con código 1 si alguno falla (úsalo antes de cada pull request).
# Uso: ./pruebas/correr_todas.sh   (o con sudo para las pruebas que lo necesitan)
# ==========================================================

set -Eeuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fallaron=()

for prueba in "$DIR"/probar_*.sh; do
    [[ -f "$prueba" ]] || continue
    printf '\n######## %s ########\n' "$(basename "$prueba")"
    bash "$prueba" || fallaron+=("$(basename "$prueba")")
done

printf '\n==============================\n'
if (( ${#fallaron[@]} == 0 )); then
    printf 'Todas las pruebas pasaron.\n'
else
    printf 'Fallaron: %s\n' "${fallaron[*]}"
    exit 1
fi
