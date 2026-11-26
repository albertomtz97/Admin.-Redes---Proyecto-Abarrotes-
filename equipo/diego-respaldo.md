# Diego: Respaldo

**Archivo:** `modulos/respaldo.sh` · **Rama:** `diego/respaldo`

Antes lee [GUIA.md](GUIA.md): explica el proyecto, cómo preparar la VM y cómo subir tu trabajo.
Requisitos del proyecto: [docs/requisitos.md](../docs/requisitos.md).

## Qué vas a construir

La opción **Respaldo** del menú: guardar una copia comprimida de información importante. Se respalda
la carpeta de datos de la tienda (`$DATOS_DIR`) o la configuración del sistema (`/etc`), y las copias
se guardan en `$RESPALDOS_DIR`.

**tar** junta muchos archivos en uno; **gzip** y **bzip2** lo comprimen. gzip suele ser más rápido y
bzip2 suele dejar el archivo más pequeño. El profesor pide **los dos**.

```
RESPALDO
├── Respaldo gzip  (.tar.gz)    → elegir: datos o /etc
└── Respaldo bzip2 (.tar.bz2)   → elegir: datos o /etc
```

## Obligatorio, paso a paso

Parte de [plantilla_modulo.sh](plantilla_modulo.sh).

1. Menú con las dos opciones (`ui_menu`).
2. Pregunta qué respaldar (otro `ui_menu`): datos → `$DATOS_DIR`, o etc → `/etc`.
3. Arma el nombre con la fecha para no pisar respaldos anteriores:

   ```bash
   fecha=$(date '+%Y%m%d_%H%M%S')
   archivo="$RESPALDOS_DIR/$(basename "$origen")_$fecha.tar.gz"
   ```
4. Crea el respaldo:

   ```bash
   ( umask 077; tar -czf "$archivo" -C "$(dirname "$origen")" "$(basename "$origen")" )
   ```
   - `-c` crear, `-z` comprimir con gzip, `-f` nombre del archivo.
   - Para bzip2 cambia `-z` por `-j` (`-cjf`) y la terminación por `.tar.bz2`.
   - `-C` hace que dentro del respaldo quede solo la carpeta (`datos/...`) y no toda la ruta.
   - `umask 077` hace que solo root pueda leerlo (el de `/etc` trae contraseñas). Va entre
     paréntesis para que no afecte al resto del menú.
5. Si `tar` falla: `ui_error` y borra el archivo incompleto (`rm -f "$archivo"`).
6. Si funciona: muestra el archivo y su tamaño (`ui_comando ls -lh "$archivo"`) y usa
   `registrar respaldo "Respaldo creado: $archivo"`.

## Extra (solo si sobra tiempo)

- **Ver y restaurar:** `tar -tf <archivo>` lista el contenido.
  `mkdir -p /tmp/restauracion && tar -xf <archivo> -C /tmp/restauracion` lo extrae.
- **rsync** (copia espejo: solo copia lo que cambió):
  `rsync -av "$DATOS_DIR/" /var/respaldo_espejo/` (la `/` final copia el contenido de la carpeta).
- **xfsdump** de `/boot` (respalda un sistema de archivos completo; AlmaLinux usa XFS, por eso se usa
  en lugar de `dump`): `xfsdump -l 0 -L abarrotes -M abarrotes -f <archivo>.xfsdump /boot`.
  Antes revisa que `findmnt -n -o FSTYPE /boot` diga `xfs`.
- **xfsrestore:** crea la carpeta y luego `xfsrestore -f <archivo>.xfsdump /tmp/restauracion_boot`.

## No olvides

- Restaura solo en `/tmp`, nunca encima de los originales ni sobre `/boot`.
- No subas respaldos a git.

## Terminaste cuando

1. Desde el menú creas un respaldo gzip y uno bzip2.
2. `sudo ls -lh respaldos/` muestra ambos (compara tamaños).
3. `sudo tar -tf respaldos/<archivo>` lista los archivos que respaldaste.
4. La bitácora del menú muestra tus registros.

Guarda capturas de cada opción para el reporte.
