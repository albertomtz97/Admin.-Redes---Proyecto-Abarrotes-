# Diego: Respaldo

**Archivo:** `modulos/respaldo.sh` · **Rama:** `diego/respaldo`

Respalda la carpeta de datos (`$DATOS_DIR`) o `/etc`. Guarda en `$RESPALDOS_DIR`.

## Obligatorio

- [ ] **Respaldo gzip**: `tar -czf archivo.tar.gz -C <carpeta padre> <carpeta>`
- [ ] **Respaldo bzip2**: igual con `-cjf` y `.tar.bz2`
- [ ] Pon la fecha en el nombre (`date '+%Y%m%d_%H%M%S'`) y muestra el archivo creado con su tamaño.

## Extra (solo si sobra tiempo)

- [ ] **Ver y restaurar**: `tar -tf` y `tar -xf archivo -C /tmp/restauracion`
- [ ] **rsync**: `rsync -av "$DATOS_DIR/" /var/respaldo_espejo/`
- [ ] **xfsdump** de `/boot`: `xfsdump -l 0 -L abarrotes -M abarrotes -f archivo.xfsdump /boot`
- [ ] **xfsrestore**: `xfsrestore -f archivo.xfsdump /tmp/restauracion_boot` (crea antes la carpeta)

## No olvides

- Restaura solo en `/tmp`, nunca encima de los originales.
- Usa `umask 077` antes de crear el respaldo (el de `/etc` trae contraseñas). Ponlo dentro de
  paréntesis, `( umask 077; tar ... )`, para que no afecte al resto del menú.

## Pruébalo

Crea ambos respaldos y compara tamaños. Revisa el contenido con `sudo tar -tf <archivo>`.
