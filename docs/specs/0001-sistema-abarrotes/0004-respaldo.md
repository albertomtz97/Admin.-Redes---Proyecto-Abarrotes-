# 0004. Respaldo: tar gzip, tar bzip2, rsync y xfsdump

> **Documento de consulta.** Es el diseño detallado e incluye funciones que **no son obligatorias**.
> Lo que hay que entregar está en [requisitos](../../requisitos.md) y en tu instrucción de
> [equipo/](../../../equipo/GUIA.md); si algo no coincide, mandan esos.
>
> **Cambio por el enunciado oficial (2026-11-25), manda sobre el texto de abajo:** gzip, bzip2 y rsync **preguntan carpeta de origen y ruta de destino** (no solo `datos/` o `/etc`, ni destino fijo). rsync es obligatorio. **xfsdump/xfsrestore (AC-9 y AC-10) ya no se hacen.**

## Summary

Respalda los datos de la tienda (`datos/`) y la configuración (`/etc`) en archivos `.tar.gz` o
`.tar.bz2`, lleva un historial, deja ver y restaurar respaldos sin pisar lo actual, copia a otra
carpeta o máquina con rsync, y como extra respalda `/boot` con xfsdump. La función `respaldo_crear`
la usan también las tareas programadas.

Razón corta: gzip y bzip2 son obligatorios; rsync y xfsdump son los opcionales más baratos (el dump
clásico no sirve en XFS, que es lo que usa AlmaLinux).

## Requirements

**User stories**:
- Como administrador, quiero respaldar datos y configuración en gzip o bzip2 y comparar tamaños.
- Como administrador, quiero restaurar un respaldo sin arriesgar los archivos actuales.
- Como administrador, quiero mantener una copia espejo de mis respaldos en otra carpeta o máquina.

**Acceptance criteria**:
- **AC-1**: Crear respaldo deja elegir origen (`datos/` o `/etc`) y genera `respaldos/<nombre>_<AAAAMMDD_HHMMSS>.tar.gz` (gzip) o `.tar.bz2` (bzip2), con rutas relativas (`tar -C "$(dirname <origen>)"`) y conservando permisos de SELinux (`--selinux --xattrs --acls`). Si el nombre ya existe (dos respaldos en el mismo segundo), agrega `_2`, `_3`.
- **AC-2**: Cada respaldo exitoso agrega `fecha,archivo,origen,formato,tamano,estado` (con `estado` = `activo`) a `respaldos.csv` (`archivo` = solo el nombre, `origen` = ruta absoluta, `tamano` = `du -h | cut -f1`) y muestra el tamaño. Los respaldos se crean con `umask 077` (solo root los puede leer, porque `/etc` incluye `/etc/shadow`).
- **AC-3**: `respaldo_crear <origen> <gz|bz2>` funciona sin pantallas: imprime la ruta creada y regresa 0; con origen inexistente o formato inválido regresa 1 sin crear archivo ni fila. Código de tar 1 cuenta como éxito con aviso en bitácora; 2 o más es falla y borra el archivo parcial. Registra en bitácora con módulo `respaldo` (los scripts de Tareas no vuelven a registrar el éxito).
- **AC-4**: Historial muestra `respaldos.csv` en tabla.
- **AC-5**: Ver contenido lista los archivos de un respaldo tar elegido (`tar -tf`); la lista solo ofrece respaldos con `estado` = `activo` y con formato `gz` o `bz2`.
- **AC-6**: Restaurar (solo tar) extrae en `/tmp/restauracion_<AAAAMMDD_HHMMSS>` por defecto; restaurar en la ruta original solo después de dos confirmaciones, en `dirname` de la columna `origen`, con `--selinux --xattrs --acls`. Si el origen es la carpeta de datos, se excluye `respaldos.csv` al restaurar (`--exclude`) para no desfasar el historial.
- **AC-7**: Eliminar respaldo pide confirmación y llama a `respaldo_eliminar <archivo>` (sin pantallas, la usa también la limpieza de Tareas): acepta nombre o ruta, borra el archivo si existe y marca la fila `eliminado` aunque el archivo ya no estuviera; regresa 1 solo si no hay fila.
- **AC-8**: rsync deja elegir origen (`respaldos/` o `datos/`, siempre con `/` final) y destino (por defecto `/var/respaldo_espejo`, o una ruta local, o `usuario@host:/ruta`); rechaza destinos que empiecen con `-` o que estén dentro del origen; usa `--` antes de las rutas. Primero muestra la simulación (`rsync -av --dry-run`), luego pide confirmar y ejecuta `rsync -av`. `--delete` solo con confirmación aparte.
- **AC-9**: xfsdump revisa `/boot` con `findmnt -n -o FSTYPE /boot`: si sale vacío ("`/boot` no es una partición separada en esta máquina") o no es `xfs`, lo explica y no hace nada. Si es XFS, genera `respaldos/boot_<fecha>.xfsdump` sin preguntas interactivas (`-l 0 -L abarrotes -M abarrotes`) con `umask 077` y lo registra con formato `xfsdump`.
- **AC-10**: xfsrestore restaura un `.xfsdump` elegido solo en `/tmp/restauracion_<fecha>`, nunca sobre `/boot`.
- **AC-11**: Toda acción exitosa queda en la bitácora con módulo `respaldo`.
- **AC-12**: `pruebas/probar_respaldo.sh` pasa (crea, lista y restaura un respaldo de una carpeta temporal en gzip y bzip2).

## Feature design

**Menú**:
```
RESPALDO
1 Crear respaldo gzip · 2 Crear respaldo bzip2 · 3 Historial · 4 Ver contenido
5 Restaurar · 6 Eliminar respaldo · 7 Sincronizar con rsync
8 Respaldar /boot con xfsdump · 9 Restaurar xfsdump
```

**Orígenes**: `datos` → `$DATOS_DIR`, `etc` → `/etc`; el padre siempre es `dirname` de la ruta
(así las pruebas, con `DATOS_DIR` temporal, funcionan igual). `respaldo_crear` también acepta una
ruta absoluta existente (lo usan las pruebas con una carpeta temporal).

**Limpieza** (la llama `tareas/limpiar_respaldos.sh`): aplica a todos los formatos, incluido `.xfsdump`.

**Value sourcing**:
| Acción | Valor | Fuente |
|---|---|---|
| crear | nombre | nombre corto del origen (`datos`, `etc`, o `basename` de la ruta) |
| crear | fecha en nombre | `date '+%Y%m%d_%H%M%S'` |
| crear | tamaño | `du -h <archivo>` |
| restaurar original | ruta padre | `dirname` de la columna `origen` de `respaldos.csv` |
| rsync | destino por defecto | `/var/respaldo_espejo` |
| xfsdump | etiquetas | fijas: `-L abarrotes -M abarrotes` |

**Key invariants**:
- Nunca queda un archivo de respaldo sin fila, ni una fila con `estado` = `activo` sin archivo.
- `respaldos/` tiene permisos `700` y cada respaldo `600`.
- Restaurar nunca sobrescribe sin doble confirmación; xfsrestore nunca toca `/boot`.

**Critical test scenarios**:
- Happy path: respaldar `datos/` en gzip y bzip2, comparar tamaños en el historial, verifica **AC-1**, **AC-2** (captura para el reporte).
- Falla: `respaldo_crear /no/existe gz` regresa 1 sin archivo ni fila, verifica **AC-3**.
- Restaurar: extraer en `/tmp` y comparar con `diff -r`, verifica **AC-6**.
- rsync: simulación mostrada antes de copiar, verifica **AC-8**.

## Build plan

1. `respaldo_crear` y funciones de historial con comentarios, satisfies **AC-1**, **AC-2**, **AC-3**, **AC-11**.
2. `pruebas/probar_respaldo.sh`, satisfies **AC-12**, **AC-3**.
3. Pantallas: crear, historial, contenido, restaurar, eliminar, satisfies **AC-4**, **AC-5**, **AC-6**, **AC-7**.
4. rsync con simulación, satisfies **AC-8**.
5. xfsdump y xfsrestore, satisfies **AC-9**, **AC-10**.
6. Revisión manual en AlmaLinux y commit, satisfies **AC-1** a **AC-12**.

## Consequences

**Negative / tradeoffs**:
- rsync a otra máquina pide la contraseña SSH en la terminal; en la fase 2 (interfaz gráfica) convendrá usar llave SSH.
- Los respaldos viven en la misma máquina; el espejo con rsync es la única protección si el disco falla.
