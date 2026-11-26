# Sistema de Administración — Tienda de Abarrotes

Proyecto de **Administración de Redes**: menú en Bash para AlmaLinux 9. **Tenemos 1 semana.**

## Qué lee cada quien

1. [equipo/GUIA.md](equipo/GUIA.md) (todos).
2. Tu archivo:

| Persona | Módulo | Instrucción | Rama |
|---|---|---|---|
| Beto | Gestión | [beto-gestion.md](equipo/beto-gestion.md) | `beto/gestion` |
| Diego | Respaldo | [diego-respaldo.md](equipo/diego-respaldo.md) | `diego/respaldo` |
| Brian | Tareas | [brian-tareas.md](equipo/brian-tareas.md) | `brian/tareas` |
| Gonzalo | Seguridad | [gonzalo-seguridad.md](equipo/gonzalo-seguridad.md) | `gonzalo/seguridad` |

Erick: menú, instalador y unión de las partes.

## Requisitos

| Módulo | Obligatorio | Extra (solo si sobra tiempo) |
|---|---|---|
| Gestión | Usuarios y grupos: agregar, borrar, consultar | |
| Tareas | cron y at: tareas ya programadas y programar nuevas desde el menú. Pago a distribuidores como tarea fija | |
| Respaldo | tar + gzip, tar + bzip2 | rsync, xfsdump/xfsrestore de `/boot` |
| Seguridad | Submenú, Nagios (abre navegador), Wireshark (abre ventana) | nmap con 5 opciones |

## Uso

```bash
sudo ./instalar.sh   # una vez
sudo ./menu.sh
```
