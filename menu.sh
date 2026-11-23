#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DIR/lib/comunes.sh"
source "$DIR/modulos/gestion.sh"

verificar_root
mkdir -p "$DIR/logs" "$DIR/respaldos" "$DIR/Datos_de_Usuarios"

while true; do
    clear
    echo "=============================="
    echo "   ADMINISTRACIÓN DEL SISTEMA"
    echo "=============================="
    echo "1) Gestión (usuarios y grupos)"
    echo "2) Tareas (cron y at)"
    echo "3) Respaldo (tar gzip / bzip2)"
    echo "4) Seguridad"
    echo "5) Salir"
    echo "=============================="
    read -rp "Elige una opción: " op

    case $op in
        1)  "menu_gestion";pausa ;;
        2) echo "Aquí irá Tareas"; pausa ;;
        3) echo "Aquí irá Respaldo"; pausa ;;
        4) echo "Aquí irá Seguridad"; pausa ;;
        5) echo "Hasta luego"; exit 0 ;;
        *) echo "Opción inválida"; pausa ;;
    esac
done
