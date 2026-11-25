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

# Muestra grupos normales (GID >= 1000) en tabla
listar_grupos_tabla(){

	 printf "%-18s %-8s %s\n" "GRUPO" "GID" "MIEMBROS"
    printf "%-18s %-8s %s\n" "-----" "---" "--------"
    getent group | awk -F: '$3 >= 1000 && $3 < 65534 {printf "%-18s %-8s %s\n", $1, $3, $4}'
}

# Muestra usuarios normales con UID, GID principal y grupos
listar_usuarios_tabla(){

	printf "%-15s %-8s %-8s %s\n" "USUARIO" "UID" "GID" "GRUPOS"
    printf "%-15s %-8s %-8s %s\n" "-------" "---" "---" "------"
    getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3, $4}' | \
    while read -r u uid gid; do
        grupos=$(id -nG "$u" | tr ' ' ',')
        printf "%-15s %-8s %-8s %s\n" "$u" "$uid" "$gid" "$grupos"
    done

}
consultar_grupos() {
    while true; do
        clear
        echo "--- CONSULTAR GRUPOS ---"
        echo "1) Listar todos los grupos"
        echo "2) Ver grupos de un usuario"
        echo "3) Ver miembros de un grupo"
        echo "4) Volver"
        read -rp "Opción: " op
        case $op in
            1)
                clear
                echo "--- GRUPOS DE USUARIOS ---"
                listar_grupos_tabla
                echo
                read -rp "¿Ver también los grupos del sistema? (s/n): " r
                if [ "$r" = "s" ]; then
                    echo
                    cut -d: -f1 /etc/group | column -c 80
                fi
                pausa
                ;;
            2)
                clear
                echo "--- USUARIOS ---"
                listar_usuarios_tabla
                echo
                read -rp "¿De qué usuario quieres ver los grupos?: " u
                if id "$u" &>/dev/null; then
                    echo
                    echo "Grupo principal: $(id -gn "$u") (GID $(id -g "$u"))"
                    echo "Todos sus grupos: $(id -nG "$u")"
                else
                    echo "El usuario no existe."
                fi
                pausa
                ;;
            3)
                clear
                echo "--- GRUPOS DE USUARIOS ---"
                listar_grupos_tabla
                echo
                read -rp "¿Qué grupo quieres ver?: " g
                if getent group "$g" &>/dev/null; then
                    echo
                    echo "Miembros de $g:"
                    miembros=$(getent group "$g" | cut -d: -f4)
                    if [ -n "$miembros" ]; then
                        echo "$miembros" | tr ',' '\n' | sed 's/^/  - /'
                    else
                        echo "  (sin miembros agregados explícitamente)"
                    fi
                else
                    echo "El grupo no existe."
                fi
                pausa
                ;;
            4) return ;;
            *) echo "Inválida"; pausa ;;
        esac
    done
}

ver_usuarios_registrados() {
    clear
    echo "--- USUARIOS REGISTRADOS ---"
    column -t -s, "$CSV_USUARIOS"
    pausa
}
