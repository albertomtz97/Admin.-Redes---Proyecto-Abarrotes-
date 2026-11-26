#!/bin/bash
# ==========================================================
# PLANTILLA DE MÓDULO
# Copia este archivo a modulos/<tu-modulo>.sh y cambia "ejemplo"
# por el nombre de tu módulo (gestion, respaldo, tareas, seguridad).
#
# Reglas que ya cumple esta plantilla:
#   - Solo define funciones (no ejecuta nada al cargarse).
#   - Todas las funciones empiezan con el nombre del módulo.
#   - Variables dentro de funciones con "local".
#   - Pantallas solo con ui_* (nada de echo/read/clear).
#   - La LÓGICA (hace el trabajo, no pregunta nada) está separada
#     de la PANTALLA (pregunta y llama a la lógica). Así la lógica
#     se puede probar con un script de pruebas.
# ==========================================================

# ==========================================================
# modulos/ejemplo.sh
# Módulo de ejemplo: guarda notas en un CSV.
# Requiere: lib/comunes.sh cargado antes.
# ==========================================================

# ------------------------------------------
# menu_ejemplo
# Menú del módulo. menu.sh lo llama al elegir la opción.
# Recibe: nada
# Regresa: 0 al volver al menú principal
# ------------------------------------------
menu_ejemplo() {
    local opcion
    while true; do
        opcion=$(ui_menu "EJEMPLO" \
            agregar "Agregar nota" \
            ver "Ver notas") || return 0
        case "$opcion" in
            agregar) ejemplo_pantalla_agregar ;;
            ver) ui_tabla_csv "$DATOS_DIR/notas.csv" ;;
        esac
    done
}

# ------------------------------------------
# ejemplo_pantalla_agregar
# PANTALLA: pide los datos y llama a la lógica.
# Recibe: nada (pregunta los datos)
# Regresa: 0
# ------------------------------------------
ejemplo_pantalla_agregar() {
    local texto
    texto=$(ui_pedir "Texto de la nota") || return 0
    if ejemplo_agregar_nota "$texto"; then
        ui_mensaje "Nota guardada."
    else
        ui_error "La nota no puede tener comas ni estar vacía."
    fi
}

# ------------------------------------------
# ejemplo_agregar_nota
# LÓGICA: guarda una nota en datos/notas.csv. No pregunta nada,
# por eso se puede probar en pruebas/probar_ejemplo.sh.
# Recibe: $1 texto de la nota
# Regresa: 0 si la guardó, 1 si el texto no es válido
# ------------------------------------------
ejemplo_agregar_nota() {
    local texto="$1"
    validar_campo "$texto" || return 1
    csv_asegurar "$DATOS_DIR/notas.csv" "fecha,texto" || return 1
    csv_agregar "$DATOS_DIR/notas.csv" "$(date '+%F %T')" "$texto" || return 1
    registrar ejemplo "Nota agregada"
}
