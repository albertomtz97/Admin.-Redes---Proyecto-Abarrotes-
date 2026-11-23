#!/bin/bash

menu_gestion() {
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
            5) return ;;
            *) echo "Inválida"; pausa ;;
        esac
    done
}

agregar_usuario() {
    read -rp "Nombre del usuario: " user
    if [ -z "$user" ]; then
        echo "El nombre no puede estar vacío."; pausa; return
    fi
    if id "$user" &>/dev/null; then
        echo "El usuario ya existe."; pausa; return
    fi

    echo "Rol: 1) comprador  2) proveedor"
    read -rp "Opción: " r
    case $r in
        1) rol="comprador"; grupo="compradores" ;;
        2) rol="proveedor"; grupo="proveedores" ;;
        *) echo "Rol inválido."; pausa; return ;;
    esac

    read -rp "Teléfono: " tel
    empresa="N/A"
    if [ "$rol" = "proveedor" ]; then
        read -rp "Empresa: " empresa
	read -rp "Correo: " correo
    fi

    # El grupo se crea solo si no existe
    getent group "$grupo" &>/dev/null || groupadd "$grupo"

    # -G agrega al grupo extra, -c guarda un comentario
    useradd -m -G "$grupo" -c "$rol" "$user"
    passwd "$user"

    echo "$user,$rol,$tel,$empresa,$correo" >> "$CSV_USUARIOS"
    registrar "Usuario agregado: $user ($rol)"
    echo "Usuario $user creado como $rol."
    
    pausa
}

eliminar_usuario() {
    read -rp "Usuario a eliminar: " user
    if id "$user" &>/dev/null; then
        read -rp "¿Seguro que quieres eliminar a $user? (s/n): " r
        if [ "$r" = "s" ]; then
            userdel -r "$user"
	    sed -i "/^$user,/d" "$CSV_USUARIOS"
            registrar "Usuario eliminado: $user"
            echo "Usuario eliminado."
        fi
    else
        echo "El usuario no existe."
    fi
    pausa
}

consultar_grupos() {
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
    pausa
}

ver_usuarios_registrados() {
    clear
    echo "--- USUARIOS REGISTRADOS ---"
    column -t -s, "$CSV_USUARIOS"
    pausa
}
