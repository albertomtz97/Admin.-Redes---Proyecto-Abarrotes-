# Sistema de Administración — Tienda de Abarrotes

Proyecto de **Administración de Redes**: menú en Bash para AlmaLinux 9. **Tenemos 1 semana.**

## Qué lee cada quien

1. [docs/requisitos.md](docs/requisitos.md): qué pide el proyecto (todos).
2. [docs/guia-maquina-virtual.md](docs/guia-maquina-virtual.md): preparar tu VM (todos).
3. [equipo/GUIA.md](equipo/GUIA.md): cómo trabajar y dónde encontrar cada cosa (todos).
4. Tu archivo (tabla de abajo).

Diseño detallado, solo de consulta: [docs/specs/](docs/specs/0001-sistema-abarrotes/index.md).


| Persona | Módulo | Instrucción | Rama |
|---|---|---|---|
| Beto | Gestión | [beto-gestion.md](equipo/beto-gestion.md) | `beto/gestion` |
| Diego | Respaldo | [diego-respaldo.md](equipo/diego-respaldo.md) | `diego/respaldo` |
| Brian | Tareas | [brian-tareas.md](equipo/brian-tareas.md) | `brian/tareas` |
| Gonzalo | Seguridad | [gonzalo-seguridad.md](equipo/gonzalo-seguridad.md) | `gonzalo/seguridad` |

Erick: menú, instalador y unión de las partes.

## Requisitos

| Módulo | Obligatorio |
|---|---|
| Actividades de gestión | Usuarios y grupos: alta, baja, consulta. Procesos: por usuario activo y del sistema |
| Automatización de tareas | cron y at: ejemplos y programar nuevas preguntando tarea y fecha |
| Respaldo | tar + gzip, tar + bzip2, rsync; preguntar carpeta y destino |
| Seguridad | Monitoreo: Nagios, Wireshark y nmap |

Enunciado oficial y decisiones: [docs/requisitos.md](docs/requisitos.md).

## Uso

```bash
sudo ./instalar.sh   # una vez
sudo ./menu.sh
```
