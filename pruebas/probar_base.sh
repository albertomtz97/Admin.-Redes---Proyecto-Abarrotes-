#!/bin/bash
# ==========================================================
# pruebas/probar_base.sh
# Pruebas del módulo Base: sintaxis de todos los scripts,
# validaciones, bitácora, funciones CSV y pantallas ui_* en modo texto.
# No necesita root (no cambia nada del sistema).
# Uso: ./pruebas/probar_base.sh
# ==========================================================

set -Eeuo pipefail
source "$(dirname "$0")/lib_pruebas.sh"

printf '== Sintaxis (bash -n) ==\n'
for script in "$BASE_DIR"/menu.sh "$BASE_DIR"/instalar.sh "$BASE_DIR"/lib/*.sh \
              "$BASE_DIR"/modulos/*.sh "$BASE_DIR"/tareas/*.sh "$BASE_DIR"/pruebas/*.sh; do
    [[ -f "$script" ]] || continue
    verificar "sintaxis de ${script#"$BASE_DIR"/}" bash -n "$script"
done

printf '\n== Validaciones ==\n'
verificar     "campo normal"                 validar_campo "Abarrotes Lupita"
esperar_falla "campo vacío"                  validar_campo ""
esperar_falla "campo con coma"               validar_campo "uno,dos"
esperar_falla "campo con salto de línea"     validar_campo $'uno\ndos'
verificar     "usuario jose_12"              validar_usuario "jose_12"
verificar     "usuario _servicio"            validar_usuario "_servicio"
esperar_falla "usuario con mayúsculas"       validar_usuario "Jose"
esperar_falla "usuario con espacio"          validar_usuario "jose perez"
esperar_falla "usuario empieza con número"   validar_usuario "1jose"
esperar_falla "usuario de 33 caracteres"     validar_usuario "abcdefghijklmnopqrstuvwxyzabcdefg"
verificar     "teléfono 10 dígitos"          validar_telefono "5512345678"
esperar_falla "teléfono 11 dígitos"          validar_telefono "29384758874"
esperar_falla "teléfono con letras"          validar_telefono "55123abc78"
esperar_falla "teléfono con espacios"        validar_telefono "55 1234 5678"
verificar     "correo normal"                validar_correo "ventas@soriana.com"
verificar     "correo con subdominio"        validar_correo "a.b@correo.unam.mx"
esperar_falla "correo sin @"                 validar_correo "ventas.soriana.com"
esperar_falla "correo sin punto en dominio"  validar_correo "ventas@soriana"
esperar_falla "correo con espacio"           validar_correo "ven tas@soriana.com"
verificar     "monto entero"                 validar_monto "1500"
verificar     "monto con 2 decimales"        validar_monto "1500.50"
esperar_falla "monto cero"                   validar_monto "0"
esperar_falla "monto 0.00"                   validar_monto "0.00"
esperar_falla "monto negativo"               validar_monto "-5"
esperar_falla "monto con 3 decimales"        validar_monto "1.505"
esperar_falla "monto con letras"             validar_monto "mil"

printf '\n== Bitácora ==\n'
registrar pruebas "mensaje con | barra"
linea=$(tail -n 1 "$LOG_FILE")
verificar "formato fecha | usuario | modulo | mensaje" \
    grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8} \| [^|]+ \| pruebas \| mensaje con / barra$' "$LOG_FILE"
verificar_igual "la barra | se cambia por /" "mensaje con / barra" "${linea##* | }"

printf '\n== CSV ==\n'
csv="$DATOS_DIR/prueba.csv"
csv_asegurar "$csv" "nombre,edad"
csv_asegurar "$csv" "nombre,edad"
verificar_igual "csv_asegurar crea encabezado una sola vez" "1" "$(wc -l < "$csv" | tr -d ' ')"
verificar      "csv_agregar fila válida"      csv_agregar "$csv" "ana" "30"
verificar      "csv_agregar otra fila"        csv_agregar "$csv" "anabel" "25"
esperar_falla  "csv_agregar rechaza comas"    csv_agregar "$csv" "luis,x" "40"
esperar_falla  "csv_agregar rechaza vacío"    csv_agregar "$csv" "" "40"
verificar      "csv_existe encuentra ana"     csv_existe "$csv" 1 "ana"
esperar_falla  "csv_existe no confunde 'an'"  csv_existe "$csv" 1 "an"
esperar_falla  "csv_existe ignora encabezado" csv_existe "$csv" 1 "nombre"
verificar      "csv_actualizar edad de ana"   csv_actualizar "$csv" 1 "ana" 2 "31"
verificar_igual "ana ahora tiene 31" "ana,31" "$(grep '^ana,' "$csv")"
esperar_falla  "csv_actualizar sin fila"      csv_actualizar "$csv" 1 "pedro" 2 "50"
esperar_falla  "csv_actualizar valor con coma" csv_actualizar "$csv" 1 "ana" 2 "3,1"
verificar      "csv_quitar ana"               csv_quitar "$csv" 1 "ana"
esperar_falla  "ana ya no existe"             csv_existe "$csv" 1 "ana"
verificar      "anabel sigue (coincidencia exacta)" csv_existe "$csv" 1 "anabel"
verificar_igual "el encabezado sigue" "nombre,edad" "$(head -n 1 "$csv")"

printf '\n== Pantallas (modo texto) ==\n'
verificar_igual "ui_pedir devuelve lo escrito" "hola" "$(ui_pedir "Dato" <<< "hola" 2>/dev/null)"
verificar_igual "ui_pedir usa el valor inicial con Enter" "5" "$(ui_pedir "Dato" "5" <<< "" 2>/dev/null)"
esperar_falla   "ui_pedir con q cancela" ui_pedir "Dato" <<< "q"
esperar_falla   "ui_pedir vacío sin inicial cancela" ui_pedir "Dato" <<< ""
verificar_igual "ui_pedir acepta 0 como valor" "0" "$(ui_pedir "Minuto" <<< "0" 2>/dev/null)"
verificar_igual "ui_menu devuelve la etiqueta" "dos" \
    "$(ui_menu "Prueba" uno "Uno" dos "Dos" <<< "2" 2>/dev/null)"
verificar_igual "ui_menu repite si la opción es inválida" "uno" \
    "$(printf '9\nx\n1\n' | ui_menu "Prueba" uno "Uno" dos "Dos" 2>/dev/null)"
esperar_falla   "ui_menu con 0 regresa 1" ui_menu "Prueba" uno "Uno" <<< "0"
esperar_falla   "ui_menu sin entrada regresa 1" ui_menu "Prueba" uno "Uno" < /dev/null
verificar       "ui_confirmar con s" ui_confirmar "¿Seguro?" <<< "s"
esperar_falla   "ui_confirmar con n" ui_confirmar "¿Seguro?" <<< "n"

printf '\n== Menú principal ==\n'
if es_root; then
    printf '  (se omite la prueba "sin sudo" porque estás como root)\n'
else
    salida=$(bash "$BASE_DIR/menu.sh" < /dev/null 2>&1) && codigo=0 || codigo=$?
    verificar_igual "menu.sh sin sudo sale con código 1" "1" "$codigo"
    verificar "menu.sh sin sudo explica que use sudo" grep -q "sudo" <<< "$salida"
fi

resumen
