#!/bin/bash

menu_gestion() {
    while true; do
        clear
        echo "--- GESTIÓN DE USUARIOS ---"
        echo "1) Agregar usuario"
        echo "2) Eliminar usuario"
        echo "3) Consultar grupos"
        echo "4) Volver"
        read -rp "Opción: " op
        case $op in
            1) agregar_usuario ;;
            2) eliminar_usuario ;;
            3) consultar_grupos ;;
            4) return ;;
            *) echo "Inválida"; pausa ;;
        esac
    done
}

agregar_usuario() {
    read -rp "Nombre del nuevo usuario: " user
    if [ -z "$user" ]; then
        echo "El nombre no puede estar vacío."
    elif id "$user" &>/dev/null; then
        echo "El usuario ya existe."
    else
        useradd -m "$user" && passwd "$user"
        registrar "Usuario agregado: $user"
        echo "Usuario creado."
    fi
    pausa
}

eliminar_usuario() {
    read -rp "Usuario a eliminar: " user
    if id "$user" &>/dev/null; then
        read -rp "¿Seguro que quieres eliminar a $user? (s/n): " r
        if [ "$r" = "s" ]; then
            userdel -r "$user"
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
