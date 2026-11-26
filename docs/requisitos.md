# Requisitos del proyecto

Sistema para una **tienda de abarrotes**, materia Administración de Redes.
Plataforma obligatoria: **AlmaLinux**. Menú principal con 4 opciones: Gestión, Tareas, Respaldo, Seguridad.

| # | Módulo | Requisito | Tipo |
|---|---|---|---|
| 1 | Gestión | Usuarios: agregar, borrar, consultar | Obligatorio |
| 1 | Gestión | Grupos: agregar, borrar, consultar | Obligatorio |
| 2 | Tareas | **cron**: tareas ya programadas + opción de programar nuevas desde el panel | Obligatorio |
| 2 | Tareas | **at**: tareas ya programadas + opción de programar nuevas desde el panel | Obligatorio |
| 2 | Tareas | Ejemplo del profesor: pago automático a distribuidores | Obligatorio (como tarea fija) |
| 3 | Respaldo | tar + **gzip** | Obligatorio |
| 3 | Respaldo | tar + **bzip2** | Obligatorio |
| 3 | Respaldo | rsync | Opcional (extra, solo si sobra tiempo) |
| 3 | Respaldo | dump/restore | Opcional (extra, solo si sobra tiempo): xfsdump/xfsrestore de `/boot` |
| 4 | Seguridad | Submenú (segunda pantalla) | Obligatorio |
| 4 | Seguridad | **Nagios**: abre el navegador automáticamente | Obligatorio |
| 4 | Seguridad | **Wireshark**: abre su ventana automáticamente | Obligatorio |
| 4 | Seguridad | nmap: 5 opciones (SO, puertos abiertos, versiones, …) | Opcional (extra, solo si sobra tiempo) |
| 4 | Seguridad | Cacti: abre el navegador | Opcional — **no se hará** (ver nota) |

## Cómo leer la documentación

1. Este archivo: **qué pide el proyecto**.
2. [equipo/GUIA.md](../equipo/GUIA.md) y tu instrucción en `equipo/`: **qué tienes que hacer** y cómo.
3. [specs/](specs/0001-sistema-abarrotes/index.md): **diseño detallado, de consulta**. Incluye más
   funciones que las obligatorias; no tienes que hacerlas. Si un spec dice algo distinto a este archivo
   o a tu instrucción, mandan estos dos.

## Notas

- Las decisiones (interfaz, roles, qué opcionales y por qué) están en
  [specs/0001-sistema-abarrotes](specs/0001-sistema-abarrotes/index.md).
- dump clásico solo sirve en ext4; AlmaLinux usa XFS, por eso se usa xfsdump.
- En el enunciado aparecen "wireshort" y "gzip2": se refieren a **Wireshark** y **bzip2**.
