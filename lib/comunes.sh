#!/bin/bash
# ==========================================================
# lib/comunes.sh
# Librería común del sistema: rutas, bitácora, pantallas (ui_*),
# validaciones, manejo de CSV y apertura de programas gráficos.
# La cargan con `source` menu.sh, instalar.sh, tareas/ y pruebas/.
# Solo define variables y funciones; no ejecuta nada al cargarse.
# Spec: docs/specs/0001-sistema-abarrotes/0002-base.md
# ==========================================================

# ----------------------------------------------------------
# Rutas. Cada una se puede definir ANTES de cargar este archivo
# (así las pruebas usan una carpeta temporal y no tocan datos reales).
# ----------------------------------------------------------
: "${BASE_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
: "${DATOS_DIR:=$BASE_DIR/datos}"
: "${LOG_FILE:=$BASE_DIR/logs/bitacora.log}"
: "${RESPALDOS_DIR:=$BASE_DIR/respaldos}"
: "${SRV_DIR:=/srv/abarrotes}"
: "${CRON_FIJAS:=/etc/cron.d/abarrotes}"
: "${CRON_USUARIO:=/etc/cron.d/abarrotes_usuario}"

# Archivos de datos y su encabezado (formato fijo, ver spec 0001)
CSV_USUARIOS="$DATOS_DIR/usuarios.csv"
CSV_GRUPOS="$DATOS_DIR/grupos.csv"
CSV_PAGOS="$DATOS_DIR/pagos.csv"
CSV_RESPALDOS="$DATOS_DIR/respaldos.csv"
ENC_USUARIOS="usuario,rol,telefono,correo,empresa,monto"
ENC_GRUPOS="grupo,descripcion,fecha"
ENC_PAGOS="fecha,proveedor,empresa,monto,tipo"
ENC_RESPALDOS="fecha,archivo,origen,formato,tamano,estado"

# Texto de la opción 0 en ui_menu ("Salir" en el menú principal)
: "${UI_TEXTO_CERO:=Volver}"

# ==========================================================
# Sistema y bitácora
# ==========================================================

# ------------------------------------------
# verificar_root
# Termina el programa si no se ejecuta como root (con sudo).
# Recibe: nada
# Regresa: 0 si es root; si no, sale con código 1
# ------------------------------------------
verificar_root() {
    if [[ "$EUID" -ne 0 ]]; then
        printf 'Este sistema debe ejecutarse con sudo (ejemplo: sudo ./menu.sh)\n' >&2
        exit 1
    fi
}

# ------------------------------------------
# registrar
# Agrega una línea a la bitácora con el formato
# "fecha | usuario | modulo | mensaje".
# Cambia "|" por "/" y saltos de línea por espacios en el mensaje
# para no romper el formato.
# Recibe: $1 módulo (base, gestion, respaldo, tareas, seguridad)
#         $2 mensaje
# Regresa: 0 si escribió, 1 si no pudo escribir
# ------------------------------------------
registrar() {
    local modulo="$1" mensaje="${2-}" usuario
    usuario="${SUDO_USER:-${USER:-$(id -un)}}"
    mensaje="${mensaje//'|'/'/'}"
    mensaje="${mensaje//$'\n'/ }"
    mkdir -p "$(dirname "$LOG_FILE")" || return 1
    printf '%s | %s | %s | %s\n' "$(date '+%F %T')" "$usuario" "$modulo" "$mensaje" >> "$LOG_FILE"
}

# ------------------------------------------
# requiere
# Revisa que exista un comando; si falta, avisa qué paquete instalar.
# Recibe: $1 comando, $2 paquete que lo trae
# Regresa: 0 si existe, 1 si falta
# ------------------------------------------
requiere() {
    local comando="$1" paquete="$2"
    if ! command -v "$comando" >/dev/null 2>&1; then
        ui_error "Falta el paquete $paquete. Ejecuta: sudo ./instalar.sh"
        return 1
    fi
}

# ------------------------------------------
# abrir_como_usuario
# Abre un programa gráfico (navegador, Wireshark) como el usuario
# real ($SUDO_USER) y no como root, porque las ventanas de root no
# se muestran en el escritorio de AlmaLinux. Corre en segundo plano;
# su salida queda en logs/gui.log para revisar si algo no abrió.
# Recibe: el comando y sus argumentos (ej. xdg-open http://localhost)
# Regresa: 0 si lo lanzó; 1 si no hay $SUDO_USER o no hay escritorio
# ------------------------------------------
abrir_como_usuario() {
    local usuario="${SUDO_USER-}" uid runtime xauth archivo gui_log
    [[ -n "$usuario" && "$usuario" != root ]] || return 1
    uid=$(id -u "$usuario" 2>/dev/null) || return 1
    runtime="/run/user/$uid"
    [[ -S "$runtime/wayland-0" || -S /tmp/.X11-unix/X0 ]] || return 1

    # Las apps Qt5 (Wireshark) usan X11 sobre Xwayland y necesitan XAUTHORITY
    xauth="${XAUTHORITY-}"
    if [[ -z "$xauth" ]]; then
        for archivo in "$runtime"/.mutter-Xwaylandauth.*; do
            [[ -f "$archivo" ]] && { xauth="$archivo"; break; }
        done
    fi

    gui_log="$(dirname "$LOG_FILE")/gui.log"
    mkdir -p "$(dirname "$gui_log")"
    # runuser vuelve a leer los grupos del usuario (ej. wireshark) sin cerrar sesión
    runuser -u "$usuario" -- env \
        DISPLAY="${DISPLAY:-:0}" \
        XAUTHORITY="$xauth" \
        WAYLAND_DISPLAY=wayland-0 \
        XDG_RUNTIME_DIR="$runtime" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
        setsid "$@" >> "$gui_log" 2>&1 < /dev/null &
    return 0
}

# ==========================================================
# Pantallas (modo texto). Regla: lo que se dibuja va a la
# terminal (stderr); solo la respuesta va a stdout, para poder
# capturarla con $(...). En la fase 2 (interfaz gráfica) solo
# cambia esta sección; los módulos no se tocan.
# ==========================================================

# ------------------------------------------
# ui_pausa
# Espera a que el usuario presione Enter.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
ui_pausa() {
    local _
    read -rp "Presiona Enter para continuar..." _ || true
}

# ------------------------------------------
# ui_menu
# Muestra un menú numerado y devuelve la etiqueta elegida.
# Si la opción es inválida, vuelve a preguntar.
# Recibe: $1 título, luego pares: etiqueta "texto" etiqueta "texto" ...
#         (opcional) variable UI_TEXTO_CERO para el texto de la opción 0
# Regresa: imprime la etiqueta elegida y regresa 0;
#          regresa 1 si elige 0 (volver) o se acaba la entrada
# ------------------------------------------
ui_menu() {
    local titulo="$1"; shift
    local -a etiquetas=() textos=()
    local i opcion
    while (( $# >= 2 )); do
        etiquetas+=("$1"); textos+=("$2"); shift 2
    done
    [[ -t 2 ]] && clear >&2
    while true; do
        printf '\n==============================\n %s\n==============================\n' "$titulo" >&2
        for i in "${!etiquetas[@]}"; do
            printf ' %d) %s\n' "$((i + 1))" "${textos[i]}" >&2
        done
        printf ' 0) %s\n' "$UI_TEXTO_CERO" >&2
        read -rp "Elige una opción: " opcion || return 1
        [[ "$opcion" == 0 ]] && return 1
        if [[ "$opcion" =~ ^[0-9]+$ ]] && (( opcion >= 1 && opcion <= ${#etiquetas[@]} )); then
            printf '%s\n' "${etiquetas[opcion - 1]}"
            return 0
        fi
        printf 'Opción inválida, intenta de nuevo.\n' >&2
    done
}

# ------------------------------------------
# ui_pedir
# Pide un dato. Si hay valor inicial y el usuario solo da Enter,
# se usa el inicial. Escribir "q" cancela.
# Recibe: $1 etiqueta, $2 (opcional) valor inicial
# Regresa: imprime el valor y regresa 0; 1 si cancela o queda vacío
# ------------------------------------------
ui_pedir() {
    local etiqueta="$1" inicial="${2-}" valor
    if [[ -n "$inicial" ]]; then
        read -rp "$etiqueta [$inicial] (q = cancelar): " valor || return 1
        [[ -z "$valor" ]] && valor="$inicial"
    else
        read -rp "$etiqueta (q = cancelar): " valor || return 1
    fi
    [[ -z "$valor" || "$valor" == q ]] && return 1
    printf '%s\n' "$valor"
}

# ------------------------------------------
# ui_password
# Pide una contraseña sin mostrarla en pantalla.
# Recibe: $1 etiqueta
# Regresa: imprime la contraseña y regresa 0; 1 si queda vacía o es "q"
# ------------------------------------------
ui_password() {
    local valor
    read -rsp "$1 (q = cancelar): " valor || { printf '\n' >&2; return 1; }
    printf '\n' >&2
    [[ -z "$valor" || "$valor" == q ]] && return 1
    printf '%s\n' "$valor"
}

# ------------------------------------------
# ui_confirmar
# Pregunta sí o no.
# Recibe: $1 pregunta
# Regresa: 0 si responde s/S, 1 en cualquier otro caso
# ------------------------------------------
ui_confirmar() {
    local respuesta
    read -rp "$1 (s/n): " respuesta || return 1
    [[ "$respuesta" == [sS] ]]
}

# ------------------------------------------
# ui_mensaje
# Muestra un aviso y espera Enter.
# Recibe: $1 texto
# Regresa: 0
# ------------------------------------------
ui_mensaje() {
    printf '\n%s\n' "$1" >&2
    ui_pausa
}

# ------------------------------------------
# ui_error
# Muestra un error y espera Enter.
# Recibe: $1 texto
# Regresa: 0
# ------------------------------------------
ui_error() {
    printf '\nERROR: %s\n' "$1" >&2
    ui_pausa
}

# ------------------------------------------
# ui_archivo
# Muestra un archivo con scroll (less) o completo si no hay less.
# Recibe: $1 ruta
# Regresa: 0 si lo mostró, 1 si no existe
# ------------------------------------------
ui_archivo() {
    local ruta="$1"
    if [[ ! -f "$ruta" ]]; then
        ui_error "No existe el archivo $ruta"
        return 1
    fi
    if command -v less >/dev/null 2>&1 && [[ -t 1 ]]; then
        less -- "$ruta"
    else
        cat -- "$ruta" >&2
        ui_pausa
    fi
}

# ------------------------------------------
# ui_tabla_csv
# Muestra un CSV como tabla alineada.
# Recibe: $1 ruta del CSV
# Regresa: 0 si lo mostró, 1 si no existe
# ------------------------------------------
ui_tabla_csv() {
    local ruta="$1"
    if [[ ! -f "$ruta" ]]; then
        ui_error "No existe el archivo $ruta"
        return 1
    fi
    printf '\n' >&2
    column -t -s, -- "$ruta" >&2
    ui_pausa
}

# ------------------------------------------
# ui_comando
# Ejecuta un comando, muestra su salida y espera Enter.
# Recibe: el comando y sus argumentos
# Regresa: el código de salida del comando
# ------------------------------------------
ui_comando() {
    local codigo=0
    printf '\n' >&2
    "$@" >&2 || codigo=$?
    ui_pausa
    return "$codigo"
}

# ==========================================================
# Validaciones (regresan 0 si el valor es válido)
# ==========================================================

# ------------------------------------------
# validar_campo
# Texto no vacío, sin comas ni saltos de línea (protege los CSV).
# Recibe: $1 valor
# Regresa: 0 si es válido, 1 si no
# ------------------------------------------
validar_campo() {
    [[ -n "${1-}" && "$1" != *,* && "$1" != *$'\n'* && "$1" != *$'\r'* ]]
}

# ------------------------------------------
# validar_usuario
# Nombre de usuario o grupo de Linux: minúsculas, números, _ y -,
# empieza con letra o _, máximo 32 caracteres.
# Recibe: $1 nombre
# Regresa: 0 si es válido, 1 si no
# ------------------------------------------
validar_usuario() {
    [[ "${1-}" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]
}

# ------------------------------------------
# validar_telefono
# Exactamente 10 dígitos.
# Recibe: $1 teléfono
# Regresa: 0 si es válido, 1 si no
# ------------------------------------------
validar_telefono() {
    [[ "${1-}" =~ ^[0-9]{10}$ ]]
}

# ------------------------------------------
# validar_correo
# Forma algo@dominio.ext, sin espacios ni comas.
# Recibe: $1 correo
# Regresa: 0 si es válido, 1 si no
# ------------------------------------------
validar_correo() {
    local patron='^[^@[:space:],]+@[^@[:space:],]+\.[^@[:space:],.]+$'
    [[ "${1-}" =~ $patron ]]
}

# ------------------------------------------
# validar_monto
# Número mayor a 0 con hasta 2 decimales (ej. 1500 o 1500.50).
# Recibe: $1 monto
# Regresa: 0 si es válido, 1 si no
# ------------------------------------------
validar_monto() {
    [[ "${1-}" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]] && [[ ! "$1" =~ ^0+(\.0+)?$ ]]
}

# ==========================================================
# CSV. Las columnas se indican por número (la primera es 1).
# Las que modifican escriben a un temporal en la misma carpeta
# y luego lo mueven: el archivo nunca queda a medias.
# ==========================================================

# ------------------------------------------
# csv_asegurar
# Crea el CSV con su encabezado si no existe o está vacío.
# Recibe: $1 ruta, $2 encabezado
# Regresa: 0 si existe o se creó, 1 si no se pudo crear
# ------------------------------------------
csv_asegurar() {
    local archivo="$1" encabezado="$2"
    [[ -s "$archivo" ]] && return 0
    mkdir -p "$(dirname "$archivo")" && printf '%s\n' "$encabezado" > "$archivo"
}

# ------------------------------------------
# csv_agregar
# Agrega una fila al final del CSV.
# Recibe: $1 ruta, luego cada campo como argumento
# Regresa: 0 si la agregó; 1 si algún campo no pasa validar_campo
# ------------------------------------------
csv_agregar() {
    local archivo="$1" campo linea
    shift
    for campo in "$@"; do
        validar_campo "$campo" || return 1
    done
    linea=$(IFS=,; printf '%s' "$*")
    printf '%s\n' "$linea" >> "$archivo"
}

# ------------------------------------------
# csv_existe
# Revisa si alguna fila tiene exactamente ese valor en esa columna.
# Recibe: $1 ruta, $2 número de columna, $3 valor
# Regresa: 0 si existe, 1 si no (o si no existe el archivo)
# ------------------------------------------
csv_existe() {
    local archivo="$1" columna="$2" valor="$3"
    [[ -f "$archivo" ]] || return 1
    VALOR="$valor" awk -F, -v c="$columna" \
        'NR > 1 && $c == ENVIRON["VALOR"] { hay = 1; exit } END { exit !hay }' "$archivo"
}

# ------------------------------------------
# csv_quitar
# Borra las filas cuyo campo es exactamente el valor dado.
# El encabezado nunca se borra.
# Recibe: $1 ruta, $2 número de columna, $3 valor
# Regresa: 0 si terminó bien, 1 si el archivo no existe o falló
# ------------------------------------------
csv_quitar() {
    local archivo="$1" columna="$2" valor="$3" temporal
    [[ -f "$archivo" ]] || return 1
    temporal=$(mktemp "$(dirname "$archivo")/.csv.XXXXXX") || return 1
    if VALOR="$valor" awk -F, -v c="$columna" \
        'NR == 1 || $c != ENVIRON["VALOR"]' "$archivo" > "$temporal"; then
        chmod --reference="$archivo" "$temporal" 2>/dev/null || true
        mv -f "$temporal" "$archivo"
    else
        rm -f "$temporal"
        return 1
    fi
}

# ------------------------------------------
# csv_actualizar
# Cambia un campo de las filas que coinciden con una clave.
# Recibe: $1 ruta, $2 columna clave, $3 valor clave,
#         $4 columna a cambiar, $5 valor nuevo
# Regresa: 0 si cambió; 1 si no hay fila, el valor nuevo no es válido
#          o el archivo no existe
# ------------------------------------------
csv_actualizar() {
    local archivo="$1" col_clave="$2" clave="$3" columna="$4" nuevo="$5" temporal
    [[ -f "$archivo" ]] || return 1
    validar_campo "$nuevo" || return 1
    temporal=$(mktemp "$(dirname "$archivo")/.csv.XXXXXX") || return 1
    if CLAVE="$clave" NUEVO="$nuevo" awk -F, -v OFS=, -v ck="$col_clave" -v c="$columna" \
        'NR > 1 && $ck == ENVIRON["CLAVE"] { $c = ENVIRON["NUEVO"]; hubo = 1 }
         { print }
         END { exit !hubo }' "$archivo" > "$temporal"; then
        chmod --reference="$archivo" "$temporal" 2>/dev/null || true
        mv -f "$temporal" "$archivo"
    else
        rm -f "$temporal"
        return 1
    fi
}
