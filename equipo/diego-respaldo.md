# Diego: módulo Respaldo

Detalle técnico completo: `docs/specs/0001-sistema-abarrotes/0004-respaldo.md`

## Qué vas a construir

Respaldos de los datos de la tienda (`datos/`) y de la configuración (`/etc`) en `.tar.gz` (gzip) o
`.tar.bz2` (bzip2), con historial, ver contenido, restaurar sin pisar archivos actuales, copia espejo
con rsync y, como extra, respaldo de `/boot` con xfsdump.

**Brian (Tareas) usa dos funciones tuyas**, así que su forma exacta no puede cambiar:

```bash
respaldo_crear <origen> <gz|bz2>     # imprime la ruta del archivo creado; regresa 1 si falla
respaldo_eliminar <archivo>          # borra el archivo y marca la fila "eliminado"
```

Tu módulo se une **antes** que el de Brian.

## Archivos que entregas (solo estos)

- `modulos/respaldo.sh`
- `pruebas/probar_respaldo.sh`

## Menú

```
RESPALDO
1 Crear respaldo gzip · 2 Crear respaldo bzip2 · 3 Historial · 4 Ver contenido
5 Restaurar · 6 Eliminar respaldo · 7 Sincronizar con rsync
8 Respaldar /boot con xfsdump · 9 Restaurar xfsdump
```

## Lista de tareas

- [ ] **`respaldo_crear <origen> <gz|bz2>`** (sin pantallas). Origen `datos` = `$DATOS_DIR`,
      `etc` = `/etc`, o una ruta absoluta. Crea
      `$RESPALDOS_DIR/<nombre>_<AAAAMMDD_HHMMSS>.tar.gz` (o `.tar.bz2`):
      `tar -C "$(dirname <origen>)" --selinux --xattrs --acls -czf <archivo> "$(basename <origen>)"`
      (`-cjf` para bzip2). Si el nombre ya existe, agrega `_2`, `_3`.
- [ ] Usa `umask 077` al crear (el respaldo de `/etc` incluye contraseñas cifradas; solo root debe leerlo).
- [ ] Código de salida de `tar`: 0 = bien, 1 = bien con aviso, 2 o más = falla (borra el archivo a medias).
- [ ] Si salió bien: fila en `$CSV_RESPALDOS` → `fecha,archivo,origen,formato,tamano,estado` (con `estado` = `activo`)
      (`archivo` = solo el nombre, `origen` = ruta completa, `tamano` = `du -h <archivo> | cut -f1`)
      y `registrar respaldo "..."`.
- [ ] **Historial**: `ui_tabla_csv "$CSV_RESPALDOS"`.
- [ ] **Ver contenido**: `tar -tf` de un respaldo elegido (solo `gz` y `bz2` con `estado` = `activo`).
- [ ] **Restaurar**: por defecto en `/tmp/restauracion_<fecha>`. En la ruta original solo con **dos**
      confirmaciones. Si es la carpeta de datos, excluye `respaldos.csv` (`--exclude`).
- [ ] **`respaldo_eliminar <archivo>`** (sin pantallas): acepta nombre o ruta (usa `basename`), borra el
      archivo si existe y marca la fila `eliminado` aunque el archivo ya no estuviera. Regresa 1 solo si
      no hay fila.
- [ ] **rsync**: origen `respaldos/` o `datos/` (siempre con `/` al final), destino por defecto
      `/var/respaldo_espejo` o lo que escriba (`usuario@host:/ruta` para otra máquina). Rechaza destinos que
      empiecen con `-`. **Primero** muestra la simulación (`rsync -av --dry-run -- origen/ destino`),
      luego confirma y ejecuta. `--delete` solo con una confirmación aparte.
- [ ] **xfsdump**: revisa `findmnt -n -o FSTYPE /boot`. Si sale vacío o no es `xfs`, explica y no hagas
      nada. Si es XFS: `xfsdump -l 0 -L abarrotes -M abarrotes -f $RESPALDOS_DIR/boot_<fecha>.xfsdump /boot`.
- [ ] **xfsrestore**: solo en `/tmp/restauracion_<fecha>`, **nunca** sobre `/boot`.

## Cuidado con

- Nunca dejes un archivo de respaldo sin fila en el CSV, ni una fila con `estado` = `activo` sin archivo.
- `respaldo_crear` no puede usar `ui_*` (Brian la llama desde cron, donde no hay pantalla).

## Cómo probarlo a mano

1. Respalda `datos/` en gzip y en bzip2; compara los tamaños en el historial. **Captura para el reporte.**
2. Restaura en `/tmp` y compara: `diff -r /tmp/restauracion_<fecha>/datos datos/`.
3. Prueba rsync a `/var/respaldo_espejo` y verifica que primero muestre la simulación.
4. Respalda `/boot` con xfsdump y restáuralo en `/tmp`.

## Pruebas automáticas (en `pruebas/probar_respaldo.sh`)

Crea una carpeta de prueba con un par de archivos, respáldala en gz y bz2, revisa que haya filas en
el CSV, restaura en otra carpeta temporal y compara. Que `respaldo_crear /no/existe gz` falle sin crear
nada.
