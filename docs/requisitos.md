# Requisitos del proyecto

Sistema para una **tienda de abarrotes**, materia Administración de Redes.
Plataforma: **AlmaLinux**.

## Enunciado oficial (texto del profesor)

> PROYECTO ADR 2026. Elabore un script que contenga el siguiente menú:
>
> **ACTIVIDADES DE GESTIÓN:** 1. Usuarios: a) alta, b) baja, c) consulta. 2. Grupos: a) alta,
> b) baja, c) consulta. 3. Muestre procesos: a) por usuario activo, b) del sistema.
>
> A su script de automatización deberán agregarle 3 opciones más en el menú principal:
> **AUTOMATIZACIÓN DE TAREAS** (deberá traer 2 de ejemplo y 1 la pondré al revisar): 1. Cron, 2. At.
> **RESPALDO DE LA INFORMACIÓN:** 1. Tar-gzip, 2. Tar-bzip2, 3. rsync /use (dump-restore).
> **SEGURIDAD:** 1. Monitoreo: a. Nagios, b. Wireshark, c. Nmap o iftop, d. Cacti.
>
> En automatización de tareas deberá preguntar al usuario qué tarea quiere programar y en qué fecha,
> en cualquiera de sus 2 opciones (cron/at). En respaldos deberá preguntar qué carpeta va a respaldar
> y en qué ruta la deberá depositar. En caso de elegir dump y restore, recuerde que debe usar una USB,
> como si respaldara el sistema completo. En monitoreo deberá dejar al menos 3 opciones para que el
> usuario decida cuál quiere; deben quedar funcionando y mostrar el monitoreo en tiempo real abriendo
> la aplicación o el navegador. Se deja a su libre criterio con qué administraría usted el servidor;
> confiamos en su creatividad y originalidad.

## Lo que vamos a entregar

| Módulo | Quién | Requisito (todo es obligatorio) |
|---|---|---|
| Gestión | Beto | Usuarios: alta, baja, consulta |
| Gestión | Beto | Grupos: alta, baja, consulta |
| Gestión | Beto | Mostrar procesos: por usuario activo y del sistema |
| Automatización de tareas | Brian | cron y at: 2 ejemplos de cada uno |
| Automatización de tareas | Brian | Programar una tarea nueva en cron y en at, preguntando **qué tarea** y **en qué fecha** |
| Respaldo | Diego | tar + gzip, tar + bzip2 y rsync |
| Respaldo | Diego | En las tres opciones preguntar **qué carpeta** y **en qué ruta** guardar |
| Seguridad | Gonzalo | Submenú **Monitoreo** con 3 opciones: Nagios (navegador), Wireshark (abre capturando), nmap |

## Lo que decidimos como equipo

- **Opción 3 de respaldo: rsync.** No hacemos dump/restore (pediría una USB y respaldar el sistema
  completo).
- **Tercer monitoreo: nmap** (el instalador ya lo instala). No hacemos Cacti ni iftop.
- Ejemplo de tarea: pago automático a distribuidores. Los roles de usuario y la bitácora son parte de
  la "creatividad".

## Por confirmar con el profesor

- Que "rsync / dump-restore" significa una **u** otra. Si pide las dos, falta dump-restore con USB.
- Que nmap cuenta como monitoreo en tiempo real (se ve su avance en la terminal). Si no, la opción es
  **iftop** y hay que agregarlo a `instalar.sh`.

## Pendiente de Erick (código de la base)

- En `menu.sh`: nombrar las opciones "Actividades de gestión (usuarios, grupos, procesos)" y
  "Automatización de tareas (cron y at)".

## Cómo leer la documentación

1. Este archivo: **qué pide el proyecto**.
2. [equipo/GUIA.md](../equipo/GUIA.md) y tu instrucción en `equipo/`: **qué tienes que hacer** y cómo.
3. [specs/](specs/0001-sistema-abarrotes/index.md): **diseño detallado, de consulta**. Trae funciones
   que no son obligatorias. Si un spec dice algo distinto a este archivo o a tu instrucción, mandan
   estos dos.

En el enunciado original aparecen "wireshort" y "gzip2": son **Wireshark** y **bzip2**.
