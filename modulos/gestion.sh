#!/bin/bash
# ==========================================================
# modulos/gestion.sh
# Módulo 1: usuarios y grupos de la tienda.
# VERSIÓN DE TRANSICIÓN: es el código anterior adaptado lo mínimo
# para funcionar con la nueva base. Se reescribe completo (ver equipo/beto-gestion.md).
# Requiere: lib/comunes.sh cargado antes.
# ==========================================================

# ------------------------------------------
# menu_gestion
# Menú del módulo de gestión.
# Recibe: nada
# Regresa: 0 al volver al menú principal
# ------------------------------------------
menu_gestion() {
    local op
    while true; do
        clear
        echo "--- GESTIÓN DE USUARIOS ---"
        echo "1) Agregar usuario"
        echo "2) Eliminar usuario"
        echo "3) Consultar grupos"
        echo "4) Ver usuarios registrados"
        echo "5) Volver"

        read -rp "Opción: " op
        case $op in
            1) agregar_usuario ;;
            2) eliminar_usuario ;;
            3) consultar_grupos ;;
            4) ver_usuarios_registrados ;;
            5) return 0 ;;
            *) echo "Inválida"; ui_pausa ;;
        esac
    done
}

# ------------------------------------------
# agregar_usuario
# Crea un usuario comprador o proveedor, lo mete a su grupo
# y lo guarda en el CSV (formato de 6 columnas).
# Recibe: nada (pregunta los datos)
# Regresa: 0
# ------------------------------------------
agregar_usuario() {
    local user r rol grupo tel correo="N/A" empresa="N/A" monto="N/A"
    read -rp "Nombre del usuario: " user
    if [ -z "$user" ]; then
        echo "El nombre no puede estar vacío."; ui_pausa; return 0
    fi
    if id "$user" &>/dev/null; then
        echo "El usuario ya existe."; ui_pausa; return 0
    fi

    echo "Rol: 1) comprador  2) proveedor"
    read -rp "Opción: " r
    case $r in
        1) rol="comprador"; grupo="compradores" ;;
        2) rol="proveedor"; grupo="proveedores" ;;
        *) echo "Rol inválido."; ui_pausa; return 0 ;;
    esac

    read -rp "Teléfono: " tel
    if [ "$rol" = "proveedor" ]; then
        read -rp "Empresa: " empresa
        read -rp "Correo: " correo
        read -rp "Monto de pago semanal: " monto
    fi

    # El grupo se crea solo si no existe
    getent group "$grupo" &>/dev/null || groupadd "$grupo"

    # -G agrega al grupo extra, -c guarda un comentario
    if ! useradd -m -G "$grupo" -c "$rol" "$user"; then
        echo "No se pudo crear el usuario."; ui_pausa; return 0
    fi
    passwd "$user"

    if csv_agregar "$CSV_USUARIOS" "$user" "$rol" "$tel" "$correo" "$empresa" "$monto"; then
        registrar gestion "Usuario agregado: $user ($rol)"
        echo "Usuario $user creado como $rol."
    else
        echo "Usuario creado, pero algún dato tiene comas o está vacío: no se guardó en el CSV."
    fi
    ui_pausa
}

# ------------------------------------------
# eliminar_usuario
# Elimina un usuario registrado en el CSV (nunca root ni tu cuenta),
# con su carpeta personal, y quita su fila del CSV.
# Recibe: nada (pregunta el usuario)
# Regresa: 0
# ------------------------------------------
eliminar_usuario() {
    local user r
    read -rp "Usuario a eliminar: " user
    if ! csv_existe "$CSV_USUARIOS" 1 "$user"; then
        echo "Solo se pueden eliminar usuarios creados desde este sistema."
    elif [[ "$user" == root || "$user" == "${SUDO_USER-}" ]]; then
        echo "No se puede eliminar ese usuario."
    else
        read -rp "¿Seguro que quieres eliminar a $user? (s/n): " r
        if [ "$r" = "s" ]; then
            if userdel -r "$user"; then
                csv_quitar "$CSV_USUARIOS" 1 "$user"
                registrar gestion "Usuario eliminado: $user"
                echo "Usuario eliminado."
            else
                echo "No se pudo eliminar el usuario."
            fi
        fi
    fi
    ui_pausa
}

# ------------------------------------------
# consultar_grupos
# Lista grupos del sistema, los grupos de un usuario o los
# miembros de un grupo.
# Recibe: nada (pregunta la opción)
# Regresa: 0
# ------------------------------------------
consultar_grupos() {
    local op u g
    clear
    echo "--- GRUPOS DE USUARIOS ---"
    echo "1) Listar todos los grupos"
    echo "2) Ver grupos de un usuario"
    echo "3) Ver miembros de un grupo"
    read -rp "Opción: " op
    case $op in
        1) cut -d: -f1 /etc/group ;;
        2) read -rp "Usuario: " u; groups "$u" ;;
        3) read -rp "Grupo: " g; getent group "$g" ;;
    esac
    ui_pausa
}

# ------------------------------------------
# ver_usuarios_registrados
# Muestra el CSV de usuarios como tabla.
# Recibe: nada
# Regresa: 0
# ------------------------------------------
ver_usuarios_registrados() {
    clear
    echo "--- USUARIOS REGISTRADOS ---"
    ui_tabla_csv "$CSV_USUARIOS"
}
