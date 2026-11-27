#!/bin/bash

# ============ MENÚ PRINCIPAL DE GESTIÓN ============
menu_gestion() {
    while true; do
        clear
        echo "--- GESTIÓN ---"
        echo "1) Usuarios"
        echo "2) Grupos"
        echo "3) Procesos"
        echo "4) Ver usuarios registrados"
        echo "5) Volver"
        read -rp "Opción: " op
        case $op in
            1) menu_usuarios ;;
            2) menu_grupos ;;
            3) procesos_usuarios ;;
            4) ver_usuarios_registrados ;;
            5) return ;;
            *) echo "Inválida"; pausa ;;
        esac
    done
}

# ============ USUARIOS ============
menu_usuarios() {
    while true; do
        clear
        echo "--- USUARIOS ---"
        echo "1) Alta de usuario"
        echo "2) Baja de usuario"
        echo "3) Consulta de usuarios"
        echo "4) Volver"
        read -rp "Opción: " op
        case $op in
            1) agregar_usuario ;;
            2) eliminar_usuario ;;
            3) consultar_usuarios ;;
            4) return ;;
            *) echo "Inválida"; pausa ;;
        esac
    done
}

agregar_usuario() {
    read -rp "Login del usuario: " user
    if [ -z "$user" ]; then
        echo "El nombre no puede estar vacío."; pausa; return
    fi
    if id "$user" &>/dev/null; then
        echo "El usuario ya existe."; pausa; return
    fi

    read -rp "Nombre completo: " nombre
    echo "Rol: 1) comprador (usuario)  2) proveedor (empresa)"
    read -rp "Opción: " r
    case $r in
        1) rol="comprador"; grupo="compradores" ;;
        2) rol="proveedor"; grupo="proveedores" ;;
        *) echo "Rol inválido."; pausa; return ;;
    esac

    read -rp "Teléfono: " tel
    empresa="N/A"
    correo="N/A"
    if [ "$rol" = "proveedor" ]; then
        read -rp "Empresa: " empresa
        read -rp "Correo: " correo
    fi

    getent group "$grupo" &>/dev/null || groupadd "$grupo"

    useradd -m -G "$grupo" -c "$nombre" "$user"
    passwd "$user"

    echo "$user,$rol,$tel,$empresa,$correo" >> "$CSV_USUARIOS"
    registrar "Usuario agregado: $user ($rol)"
    echo "Usuario $user creado como $rol."
    pausa
}

eliminar_usuario() {
	clear
    echo "--- BAJA DE USUARIO ---"
    listar_usuarios_tabla
    echo
    read -rp "Usuario a eliminar: " user
    if ! id "$user" &>/dev/null; then
        echo "El usuario no existe."; pausa; return
    fi
    if [ "$(id -u "$user")" -lt 1000 ]; then
        echo "No se permite eliminar usuarios del sistema."; pausa; return
    fi
    read -rp "¿Seguro que quieres eliminar a $user? (s/n): " r
    if [ "$r" = "s" ]; then
        userdel -r "$user"
        sed -i "/^$user,/d" "$CSV_USUARIOS"
        registrar "Usuario eliminado: $user"
        echo "Usuario eliminado."
    fi
    pausa
}

consultar_usuarios() {
    clear
    echo "--- CONSULTA DE USUARIOS ---"
    printf "%-14s %-7s %-22s %s\n" "LOGIN" "UID" "NOMBRE" "ROL"
    printf "%-14s %-7s %-22s %s\n" "-----" "---" "------" "---"

    while IFS=: read -r login uid nombre; do
        nombre=${nombre%%,*}
        rol=$(awk -F, -v u="$login" '$1==u {print $2}' "$CSV_USUARIOS")
        case $rol in
            comprador) tipo="usuario" ;;
            proveedor) tipo="empresa" ;;
            *)         tipo="N/A" ;;
        esac
        printf "%-14s %-7s %-22s %s\n" "$login" "$uid" "$nombre" "$tipo"
    done < <(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1":"$3":"$5}')

    echo
    read -rp "¿Ver detalle de un usuario? (s/n): " r
    if [ "$r" = "s" ]; then
        read -rp "Login del usuario: " u
        if id "$u" &>/dev/null; then
            echo
            echo "===== pinky ====="
            pinky -l "$u"
            echo
            echo "===== chage -l ====="
            chage -l "$u"
        else
            echo "El usuario no existe."
        fi
    fi
    pausa
}

# ============ GRUPOS ============
menu_grupos() {
    while true; do
        clear
        echo "--- GRUPOS ---"
        echo "1) Alta de grupo"
        echo "2) Baja de grupo"
        echo "3) Consultar grupos"
	echo "4) Administracion de miembros"
        echo "5) Volver"
        read -rp "Opción: " op
        case $op in
            1) alta_grupo ;;
            2) baja_grupo ;;
            3) consultar_grupos ;;
	    4) administracion_de_miembros;;
            5) return ;;
            *) echo "Inválida"; pausa ;;
        esac
    done
}

alta_grupo() {
    read -rp "Nombre del nuevo grupo: " g
    if [[ ! "$g" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "Nombre inválido (minúsculas, números, _ y -)."; pausa; return
    fi
    if getent group "$g" &>/dev/null; then
        echo "El grupo ya existe."; pausa; return
    fi
    groupadd "$g" && {
        registrar "Grupo creado: $g"
        echo "Grupo $g creado (GID $(getent group "$g" | cut -d: -f3))."
    }
    pausa
}

baja_grupo() {
    clear
    echo "--- GRUPOS DE USUARIOS ---"
    listar_grupos_tabla
    echo
    read -rp "Grupo a eliminar: " g
    if ! getent group "$g" &>/dev/null; then
        echo "El grupo no existe."; pausa; return
    fi
    gid=$(getent group "$g" | cut -d: -f3)
    if [ "$gid" -lt 1000 ]; then
        echo "No se permite eliminar grupos del sistema."; pausa; return
    fi
    # Un grupo no se puede borrar si es el grupo principal de un usuario
    dueno=$(getent passwd | awk -F: -v gid="$gid" '$4==gid {print $1}')
    if [ -n "$dueno" ]; then
        echo "No se puede: es el grupo principal de: $dueno"; pausa; return
    fi
    read -rp "¿Seguro que quieres eliminar el grupo $g? (s/n): " r
    if [ "$r" = "s" ]; then
        groupdel "$g" && {
            registrar "Grupo eliminado: $g"
            echo "Grupo eliminado."
        }
    fi
    pausa

}

administracion_de_miembros() {
    while true; do
        clear
        echo "--- ADMINISTRAR MIEMBROS ---"
        echo "1) Agregar usuario a un grupo"
        echo "2) Quitar usuario de un grupo"
        echo "3) Volver"
        read -rp "Opción: " op
        case $op in
            1) agregar_a_grupo ;;
            2) quitar_de_grupo ;;
            3) return ;;
            *) echo "Inválida"; pausa ;;
        esac
    done
}

agregar_a_grupo() {
    clear
    listar_usuarios_tabla
    echo
    read -rp "Usuario: " u
    if ! id "$u" &>/dev/null || [ "$(id -u "$u")" -lt 1000 ]; then
        echo "Usuario inválido."; pausa; return
    fi
    echo
    listar_grupos_tabla
    echo
    read -rp "Grupo al que agregarlo: " g
    gid=$(getent group "$g" | cut -d: -f3)
    if [ -z "$gid" ] || [ "$gid" -lt 1000 ]; then
        echo "Grupo inválido."; pausa; return
    fi
    usermod -aG "$g" "$u" && {
        registrar "Usuario $u agregado al grupo $g"
        echo "$u ahora pertenece a: $(id -nG "$u")"
    }
    pausa
}

quitar_de_grupo() {
    clear
    listar_usuarios_tabla
    echo
    read -rp "Usuario: " u
    if ! id "$u" &>/dev/null || [ "$(id -u "$u")" -lt 1000 ]; then
        echo "Usuario inválido."; pausa; return
    fi
    echo "Grupos actuales de $u: $(id -nG "$u")"
    read -rp "Grupo del que quitarlo: " g
    if [ "$g" = "$(id -gn "$u")" ]; then
        echo "Ese es su grupo principal; no se quita."; pausa; return
    fi
    if ! id -nG "$u" | tr ' ' '\n' | grep -qx "$g"; then
        echo "El usuario no pertenece a ese grupo."; pausa; return
    fi
    gpasswd -d "$u" "$g" && {
        registrar "Usuario $u quitado del grupo $g"
        echo "$u ahora pertenece a: $(id -nG "$u")"
    }
    pausa
}




# Muestra grupos normales (GID >= 1000) en tabla
listar_grupos_tabla() {
    printf "%-18s %-8s %s\n" "GRUPO" "GID" "MIEMBROS"
    printf "%-18s %-8s %s\n" "-----" "---" "--------"
    getent group | awk -F: '$3 >= 1000 && $3 < 65534 {printf "%-18s %-8s %s\n", $1, $3, $4}'
}

# Muestra usuarios normales con UID, GID principal y grupos
listar_usuarios_tabla() {
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

# ============ PROCESOS ============
procesos_usuarios() {
    clear
    echo "--- PROCESOS POR USUARIO ---"
    printf "%-14s %-10s %-10s %s\n" "USUARIO" "ESTADO" "PROCESOS" "CUENTA"
    printf "%-14s %-10s %-10s %s\n" "-------" "------" "--------" "------"

    inactivos=()
    while IFS= read -r u; do
        sesiones=$(who | awk -v u="$u" '$1==u' | wc -l)
        procs=$(ps -u "$u" --no-headers 2>/dev/null | wc -l)
        if [ "$sesiones" -gt 0 ] || [ "$procs" -gt 0 ]; then
            estado="Activo"
        else
            estado="Inactivo"
            inactivos+=("$u")
        fi
        c=$(passwd -S "$u" 2>/dev/null | awk '{print $2}')
        if [[ "$c" == L* ]]; then cuenta="Bloqueada"; else cuenta="Normal"; fi
        printf "%-14s %-10s %-10s %s\n" "$u" "$estado" "$procs" "$cuenta"
    done < <(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1}')

    echo
    if [ ${#inactivos[@]} -eq 0 ]; then
        echo "Todos los usuarios están activos."
        pausa; return
    fi

    read -rp "¿Quieres activar algún usuario inactivo? (s/n): " r
    if [ "$r" = "s" ]; then
        echo "Inactivos: ${inactivos[*]}"
        read -rp "¿Cuál usuario?: " u
        if [[ " ${inactivos[*]} " == *" $u "* ]]; then
            c=$(passwd -S "$u" 2>/dev/null | awk '{print $2}')
            if [[ "$c" == L* ]]; then
                usermod -U "$u" && echo "Cuenta de $u desbloqueada."
                registrar "Cuenta desbloqueada: $u"
            fi
            read -rp "¿Abrir una sesión como $u ahora? (s/n): " s
            if [ "$s" = "s" ]; then
                registrar "Sesión iniciada con su como: $u"
                echo "Escribe 'exit' para regresar al menú."
                su - "$u"
            fi
        else
            echo "Ese usuario no está en la lista de inactivos."
        fi
    fi
    pausa
}

# ============ CSV ============
ver_usuarios_registrados() {
    clear
    echo "--- USUARIOS REGISTRADOS ---"
    column -t -s, "$CSV_USUARIOS"
    pausa
}
