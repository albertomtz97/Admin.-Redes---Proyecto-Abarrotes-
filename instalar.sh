#!/bin/bash
# ==========================================================
# instalar.sh
# Deja una AlmaLinux 9 lista para el sistema: repositorios,
# paquetes, servicios, carpetas, datos, cron fijas, Nagios,
# Wireshark y migración del CSV viejo.
# Se puede correr varias veces: lo que ya está hecho lo salta.
# Uso: sudo ./instalar.sh
# ==========================================================

set -Eeuo pipefail
shopt -s nullglob

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/lib/comunes.sh"

PAQUETES=(
    cronie at tar gzip bzip2 rsync xfsdump nmap wireshark
    httpd php-fpm httpd-tools xdg-utils nagios
    nagios-plugins-ping nagios-plugins-disk nagios-plugins-users
    nagios-plugins-procs nagios-plugins-load nagios-plugins-swap
    nagios-plugins-ssh nagios-plugins-http
)
SERVICIOS=(crond atd httpd php-fpm nagios)
GRUPOS_ROL=(compradores proveedores empleados)

HECHO=()
YA_ESTABA=()

trap 'printf "\nERROR: instalar.sh falló en la línea %s. Revisa el mensaje de arriba.\n" "$LINENO" >&2; registrar base "ERROR: instalar.sh falló en la línea $LINENO" || true' ERR

# ------------------------------------------
# instalar_hecho / instalar_ya
# Anotan un paso para el resumen final y lo muestran en pantalla.
# Recibe: $1 descripción del paso
# Regresa: 0
# ------------------------------------------
instalar_hecho() { HECHO+=("$1"); printf '  [hecho]      %s\n' "$1"; }
instalar_ya() { YA_ESTABA+=("$1"); printf '  [ya estaba]  %s\n' "$1"; }

# ------------------------------------------
# instalar_verificar
# Revisa que se corra con sudo desde un usuario normal, que la ruta
# no tenga espacios y que ningún script tenga fin de línea CRLF.
# Recibe: nada
# Regresa: 0 si todo está bien; si no, sale con código 1
# ------------------------------------------
instalar_verificar() {
    local crlf
    verificar_root
    if [[ -z "${SUDO_USER-}" || "$SUDO_USER" == root ]]; then
        printf 'Ejecuta con sudo desde tu usuario normal (no entres como root).\n' >&2
        exit 1
    fi
    if [[ "$BASE_DIR" == *" "* ]]; then
        printf 'La ruta del proyecto tiene espacios: %s\nMuévelo a una ruta sin espacios.\n' "$BASE_DIR" >&2
        exit 1
    fi
    crlf=$(grep -rlI $'\r' --include='*.sh' --include='*.cron' --exclude-dir=.git "$BASE_DIR" || true)
    if [[ -n "$crlf" ]]; then
        printf 'Estos archivos tienen fin de línea de Windows (CRLF):\n%s\n' "$crlf" >&2
        printf 'Corrígelos con: sed -i '\''s/\\r$//'\'' <archivo>\n' >&2
        exit 1
    fi
}

# ------------------------------------------
# instalar_repositorios
# Activa CRB y EPEL (Nagios y sus plugins vienen de EPEL).
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_repositorios() {
    printf '\n== Repositorios ==\n'
    if ! rpm -q dnf-plugins-core >/dev/null 2>&1; then
        dnf install -y dnf-plugins-core
    fi
    if dnf repolist --enabled 2>/dev/null | grep -q '^crb'; then
        instalar_ya "repositorio CRB"
    else
        dnf config-manager --set-enabled crb
        instalar_hecho "repositorio CRB"
    fi
    if rpm -q epel-release >/dev/null 2>&1; then
        instalar_ya "repositorio EPEL"
    else
        dnf install -y epel-release
        instalar_hecho "repositorio EPEL"
    fi
}

# ------------------------------------------
# instalar_paquetes
# Instala solo los paquetes que falten.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_paquetes() {
    local paquete
    local -a faltan=()
    printf '\n== Paquetes ==\n'
    for paquete in "${PAQUETES[@]}"; do
        rpm -q "$paquete" >/dev/null 2>&1 || faltan+=("$paquete")
    done
    if (( ${#faltan[@]} == 0 )); then
        instalar_ya "todos los paquetes"
    else
        dnf install -y "${faltan[@]}"
        instalar_hecho "paquetes: ${faltan[*]}"
    fi
}

# ------------------------------------------
# instalar_servicios
# Habilita y arranca los servicios que necesita el sistema.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_servicios() {
    local servicio
    printf '\n== Servicios ==\n'
    for servicio in "${SERVICIOS[@]}"; do
        if systemctl is-enabled --quiet "$servicio" && systemctl is-active --quiet "$servicio"; then
            instalar_ya "servicio $servicio"
        else
            systemctl enable --now "$servicio"
            instalar_hecho "servicio $servicio"
        fi
    done
}

# ------------------------------------------
# instalar_carpetas
# Crea carpetas de datos, respaldos y bitácora, y los CSV con su
# encabezado. respaldos/ queda solo para root.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_carpetas() {
    printf '\n== Carpetas y datos ==\n'
    mkdir -p "$DATOS_DIR/nmap" "$RESPALDOS_DIR" "$(dirname "$LOG_FILE")"
    chmod 700 "$RESPALDOS_DIR"
    csv_asegurar "$CSV_USUARIOS" "$ENC_USUARIOS"
    csv_asegurar "$CSV_GRUPOS" "$ENC_GRUPOS"
    csv_asegurar "$CSV_PAGOS" "$ENC_PAGOS"
    csv_asegurar "$CSV_RESPALDOS" "$ENC_RESPALDOS"
    instalar_hecho "carpetas datos/, respaldos/, logs/ y archivos CSV"
}

# ------------------------------------------
# instalar_grupos_rol
# Crea los 3 grupos de rol con su carpeta compartida usando
# gestion_crear_grupo (módulo Gestión). Si ese módulo todavía no
# tiene la función, se salta con aviso.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_grupos_rol() {
    local grupo
    printf '\n== Grupos de rol ==\n'
    if [[ -f "$BASE_DIR/modulos/gestion.sh" ]]; then
        source "$BASE_DIR/modulos/gestion.sh"
    fi
    if ! declare -F gestion_crear_grupo >/dev/null; then
        printf '  [pendiente]  se activa cuando el módulo Gestión tenga gestion_crear_grupo\n'
        return 0
    fi
    for grupo in "${GRUPOS_ROL[@]}"; do
        gestion_crear_grupo "$grupo" "Grupo de rol $grupo"
    done
    instalar_hecho "grupos de rol: ${GRUPOS_ROL[*]}"
}

# ------------------------------------------
# instalar_cron
# Genera las cron fijas desde la plantilla (siempre se regeneran)
# y crea el archivo de cron de usuario si no existe (nunca lo toca
# si ya existe). El temporal se crea dentro de /etc/cron.d con
# nombre que empieza con punto (cron lo ignora) para que SELinux
# le dé la etiqueta correcta.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_cron() {
    local temporal
    printf '\n== Tareas cron ==\n'
    temporal="$(dirname "$CRON_FIJAS")/.abarrotes.tmp"
    sed "s|@BASE_DIR@|$BASE_DIR|g" "$BASE_DIR/config/abarrotes.cron" > "$temporal"
    chmod 644 "$temporal"
    mv -f "$temporal" "$CRON_FIJAS"
    command -v restorecon >/dev/null && restorecon "$CRON_FIJAS"
    instalar_hecho "cron fijas en $CRON_FIJAS"

    if [[ -f "$CRON_USUARIO" ]]; then
        instalar_ya "archivo de tareas de usuario $CRON_USUARIO"
    else
        printf '%s\n' \
            "# Tareas creadas desde el menú (módulo Tareas). instalar.sh no modifica este archivo." \
            "SHELL=/bin/bash" \
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin" \
            'MAILTO=""' > "$CRON_USUARIO"
        chmod 644 "$CRON_USUARIO"
        command -v restorecon >/dev/null && restorecon "$CRON_USUARIO"
        instalar_hecho "archivo de tareas de usuario $CRON_USUARIO"
    fi
}

# ------------------------------------------
# instalar_nagios
# Crea o cambia la contraseña web de nagiosadmin.
# Recibe: nada (pregunta si cambiarla)
# Regresa: 0
# ------------------------------------------
instalar_nagios() {
    local archivo=/etc/nagios/passwd respuesta=""
    printf '\n== Nagios ==\n'
    if [[ ! -f "$archivo" ]]; then
        printf 'Escribe la contraseña para entrar a Nagios (usuario nagiosadmin):\n'
        htpasswd -c "$archivo" nagiosadmin
        instalar_hecho "contraseña de nagiosadmin"
        return 0
    fi
    read -rp "¿Quieres cambiar la contraseña de nagiosadmin? (s/n): " respuesta || respuesta=n
    if [[ "$respuesta" == [sS] ]]; then
        htpasswd "$archivo" nagiosadmin
        instalar_hecho "contraseña de nagiosadmin cambiada"
    else
        instalar_ya "contraseña de nagiosadmin"
    fi
}

# ------------------------------------------
# instalar_wireshark
# Agrega al usuario real al grupo wireshark para capturar sin root.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_wireshark() {
    printf '\n== Wireshark ==\n'
    if ! getent group wireshark >/dev/null; then
        printf '  [aviso]      no existe el grupo wireshark; revisa que el paquete se instaló\n'
        return 0
    fi
    if id -nG "$SUDO_USER" | tr ' ' '\n' | grep -qx wireshark; then
        instalar_ya "$SUDO_USER en el grupo wireshark"
    else
        usermod -aG wireshark "$SUDO_USER"
        instalar_hecho "$SUDO_USER agregado al grupo wireshark"
    fi
}

# ------------------------------------------
# instalar_migrar
# Convierte Datos_de_Usuarios/usuarios.csv (formato viejo
# usuario,rol,telefono,empresa,correo) al formato nuevo de 6 columnas.
# Filas inválidas van a datos/migracion_rechazados.csv tal cual.
# Al final renombra la carpeta vieja a Datos_de_Usuarios.migrado.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_migrar() {
    local viejo="$BASE_DIR/Datos_de_Usuarios/usuarios.csv"
    local rechazados="$DATOS_DIR/migracion_rechazados.csv"
    local linea columnas usuario rol telefono empresa correo monto motivo
    local migrados=0 rechazadas=0
    [[ -f "$viejo" ]] || return 0

    printf '\n== Migración de Datos_de_Usuarios ==\n'
    csv_asegurar "$rechazados" "usuario,rol,telefono,empresa,correo"
    while IFS= read -r linea || [[ -n "$linea" ]]; do
        linea="${linea%$'\r'}"
        [[ -z "$linea" ]] && continue
        columnas=$(awk -F, '{ print NF }' <<< "$linea")
        IFS=, read -r usuario rol telefono empresa correo <<< "$linea"
        correo="${correo:-N/A}"
        motivo=""
        if (( columnas != 5 )); then
            motivo="tiene $columnas columnas en vez de 5"
        elif ! validar_usuario "$usuario"; then
            motivo="nombre de usuario inválido"
        elif [[ "$rol" != comprador && "$rol" != proveedor && "$rol" != empleado ]]; then
            motivo="rol inválido ($rol)"
        elif ! validar_telefono "$telefono"; then
            motivo="teléfono inválido ($telefono)"
        elif [[ "$correo" != N/A ]] && ! validar_correo "$correo"; then
            motivo="correo inválido ($correo)"
        elif ! id "$usuario" >/dev/null 2>&1; then
            motivo="la cuenta no existe en este sistema"
        fi

        if [[ -n "$motivo" ]]; then
            printf '%s\n' "$linea" >> "$rechazados"
            printf '  [rechazada]  %s: %s\n' "${usuario:-?}" "$motivo"
            rechazadas=$((rechazadas + 1))
            continue
        fi
        if csv_existe "$CSV_USUARIOS" 1 "$usuario"; then
            continue
        fi
        if [[ "$rol" == proveedor ]]; then
            empresa="${empresa:-N/A}"
            monto=0
        else
            empresa="N/A"
            monto="N/A"
        fi
        csv_agregar "$CSV_USUARIOS" "$usuario" "$rol" "$telefono" "$correo" "$empresa" "$monto"
        migrados=$((migrados + 1))
    done < <(tail -n +2 "$viejo")

    mv "$BASE_DIR/Datos_de_Usuarios" "$BASE_DIR/Datos_de_Usuarios.migrado"
    instalar_hecho "migración: $migrados filas migradas, $rechazadas rechazadas"
    if (( rechazadas > 0 )); then
        printf '  [aviso]      las filas rechazadas quedaron en %s\n' "$rechazados"
    fi
    if (( migrados > 0 )); then
        printf '  [aviso]      los proveedores migrados tienen monto 0: captúralo con "modificar usuario"\n'
    fi
}

# ------------------------------------------
# instalar_permisos
# Da permiso de ejecución a los scripts del proyecto.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_permisos() {
    local -a scripts=("$BASE_DIR"/menu.sh "$BASE_DIR"/instalar.sh "$BASE_DIR"/tareas/*.sh "$BASE_DIR"/pruebas/*.sh)
    chmod +x "${scripts[@]}"
    instalar_hecho "permisos de ejecución en los scripts"
}

# ------------------------------------------
# instalar_resumen
# Muestra qué se hizo y qué ya estaba, y lo anota en la bitácora.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
instalar_resumen() {
    printf '\n== Resumen ==\n'
    printf 'Hecho ahora: %d pasos. Ya estaba: %d pasos.\n' "${#HECHO[@]}" "${#YA_ESTABA[@]}"
    printf 'Listo. Abre el sistema con: sudo ./menu.sh\n'
    registrar base "instalar.sh terminó: ${#HECHO[@]} pasos hechos, ${#YA_ESTABA[@]} ya estaban"
}

instalar_verificar
instalar_repositorios
instalar_paquetes
instalar_servicios
instalar_carpetas
instalar_grupos_rol
instalar_cron
instalar_nagios
instalar_wireshark
instalar_migrar
instalar_permisos
instalar_resumen
