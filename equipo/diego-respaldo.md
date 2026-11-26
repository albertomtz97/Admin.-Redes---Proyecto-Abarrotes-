# Diego: Respaldo

**Archivo:** `modulos/respaldo.sh` · **Rama:** `diego/respaldo`

Antes lee [GUIA.md](GUIA.md): explica el proyecto, cómo preparar la VM y cómo subir tu trabajo.
Requisitos del proyecto: [docs/requisitos.md](../docs/requisitos.md).

## Qué vas a construir

La opción **Respaldo de la información** del menú: copiar una carpeta a otro lugar. Tiene 3 opciones
y **en las tres se pregunta qué carpeta respaldar y en qué ruta guardarla**.

**tar** junta muchos archivos en uno; **gzip** y **bzip2** lo comprimen (gzip suele ser más rápido y
bzip2 suele dejarlo más pequeño). **rsync** no comprime: deja una copia igual de la carpeta y, si lo
repites, solo copia lo que cambió.

```
RESPALDO
├── 1. tar + gzip  (.tar.gz)    → carpeta y destino
├── 2. tar + bzip2 (.tar.bz2)   → carpeta y destino
└── 3. rsync                    → carpeta y destino
```

(El profesor permite dump/restore en la opción 3; elegimos rsync. Ver
[requisitos](../docs/requisitos.md).)

## Obligatorio, paso a paso

Parte de [plantilla_modulo.sh](plantilla_modulo.sh).

### 1. Preguntar carpeta y destino (sirve para las 3 opciones)

```bash
origen=$(ui_pedir "Carpeta a respaldar (ruta completa)" "$DATOS_DIR") || return 0
destino=$(ui_pedir "Ruta donde guardar el respaldo" "$RESPALDOS_DIR") || return 0
```

Antes de respaldar revisa, y si algo no se cumple usa `ui_error` y no hagas nada:
- Las dos rutas empiezan con `/` y el origen es una carpeta que existe (`[[ -d "$origen" ]]`).
- Normaliza: `origen=$(realpath "$origen")` y `destino=$(realpath -m "$destino")`.
- El origen no es `/`.
- El destino no es la carpeta de origen ni está dentro de ella (se copiaría a sí misma):
  `[[ "$destino/" == "$origen/"* ]]` significa que está dentro.
- Crea el destino si no existe: `mkdir -p "$destino"` (y revisa que haya funcionado).

### 2. tar + gzip

```bash
archivo="$destino/$(basename "$origen")_$(date '+%Y%m%d_%H%M%S').tar.gz"
( umask 077; tar -czf "$archivo" -C "$(dirname "$origen")" "$(basename "$origen")" )
```

- `-c` crear, `-z` comprimir con gzip, `-f` nombre del archivo.
- `-C` hace que dentro del respaldo quede solo la carpeta y no toda la ruta.
- `umask 077` hace que solo root pueda leer el archivo (puede traer datos sensibles, como `/etc`).
  Va entre paréntesis para que no afecte al resto del menú.
- La fecha en el nombre evita pisar respaldos anteriores.

Si `tar` falla: `ui_error` y borra el archivo incompleto (`rm -f "$archivo"`). Si funciona: muestra el
archivo y su tamaño (`ui_comando ls -lh "$archivo"`) y usa `registrar respaldo "..."`.

### 3. tar + bzip2
Igual, cambiando `-czf` por `-cjf` y `.tar.gz` por `.tar.bz2`.

### 4. rsync

```bash
ui_comando rsync -av -- "$origen/" "$destino/"
```

- `-a` conserva permisos y fechas, `-v` muestra lo que copia.
- La `/` al final del origen copia **el contenido** de la carpeta.
- `--` evita que una ruta se tome como opción. **No uses `--delete`** (borra archivos del destino).
- Si falla, `ui_error`; si funciona, `registrar respaldo "..."`.

## Extra (solo si sobra tiempo)

- **Ver y restaurar:** `tar -tf <archivo>` lista el contenido.
  `mkdir -p /tmp/restauracion && tar -xf <archivo> -C /tmp/restauracion` lo extrae.

## No olvides

- Restaura solo en `/tmp`, nunca encima de los originales.
- Para probar usa carpetas pequeñas (`$DATOS_DIR` o `/etc`).
- No subas respaldos a git.

## Terminaste cuando

1. Cada opción pregunta carpeta y destino, y el resultado queda **en la ruta que escribiste**
   (pruébalo con `/tmp/mis_respaldos`).
2. `sudo ls -lh /tmp/mis_respaldos` muestra el `.tar.gz` y el `.tar.bz2` (compara tamaños).
3. `sudo tar -tf <archivo>` lista los archivos respaldados.
4. rsync deja la copia en el destino; si agregas un archivo y repites, solo copia ese cambio.
5. Una carpeta que no existe, o un destino dentro del origen, muestra error.
6. La bitácora del menú muestra tus registros.

Guarda capturas de cada opción para el reporte.
