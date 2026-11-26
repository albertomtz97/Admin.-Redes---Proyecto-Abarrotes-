# Brian: módulo Tareas (cron, at y pagos)

Detalle técnico completo: `docs/specs/0001-sistema-abarrotes/0005-tareas.md`

## Qué vas a construir

Tareas automáticas de la tienda. Unas ya quedan programadas al instalar (cron fijas) y desde el menú
se pueden crear más, tanto repetidas (cron) como de una sola vez (at). El ejemplo del profesor, el
**pago a distribuidores**, lee los proveedores y su monto de `usuarios.csv` y registra cada pago en
`pagos.csv`.

## Archivos que entregas (solo estos)

- `modulos/tareas.sh`
- `tareas/pago_distribuidores.sh`, `tareas/pago_unico.sh`, `tareas/respaldar.sh`,
  `tareas/limpiar_respaldos.sh`, `tareas/reporte_disco.sh`, `tareas/recordatorio.sh`
- `config/abarrotes.cron` (agregas las 4 tareas fijas al final del archivo que ya existe)
- `pruebas/probar_tareas.sh`

## Dependencia con Diego

`tareas/respaldar.sh` y `tareas/limpiar_respaldos.sh` usan `respaldo_crear` y `respaldo_eliminar`
del módulo de Diego. Mientras él termina, en **tu VM** crea un `modulos/respaldo.sh` falso solo para
probar:

```bash
respaldo_crear()    { echo "/tmp/respaldo_falso.tar.gz"; }
respaldo_eliminar() { echo "eliminado falso: $1"; }
```

**No me mandes ese archivo falso** en tu `.zip`.

## Menú

```
TAREAS
├── cron: ver · programar nueva · eliminar (solo las creadas por usuarios)
├── at:   ver pendientes · programar nueva · ver contenido · cancelar · cargar ejemplos
└── Ver historial de pagos
```

## Lista de tareas

- [ ] **Tareas fijas** en `config/abarrotes.cron` (cada una con su comentario `#` encima):
      pago viernes 18:00, `respaldar.sh datos gz` diario 02:00, limpieza domingo 03:00, reporte de disco
      diario 08:00. Todas como `root`, con `@BASE_DIR@` en la ruta y `>> @BASE_DIR@/logs/cron.log 2>&1`
      al final. Ejemplo:
      `0 18 * * 5 root @BASE_DIR@/tareas/pago_distribuidores.sh >> @BASE_DIR@/logs/cron.log 2>&1`
- [ ] **Scripts de `tareas/`**: empiezan con `set -Eeuo pipefail`, cargan `lib/comunes.sh` y **no usan
      pantallas**. Si fallan, `registrar tareas "ERROR: ..."`.
  - `pago_distribuidores.sh`: por cada proveedor con monto > 0 agrega `fecha,proveedor,empresa,monto,semanal`
    a `$CSV_PAGOS`. **Si ese proveedor ya tiene pago semanal ese día, sáltalo** (no pagar doble).
  - `pago_unico.sh <proveedor> <monto>`: valida y agrega una fila con tipo `unico`.
  - `respaldar.sh <origen> <gz|bz2>`: llama a `respaldo_crear`.
  - `limpiar_respaldos.sh`: para respaldos de más de 30 días (`find $RESPALDOS_DIR -mtime +30`) llama a `respaldo_eliminar`.
  - `reporte_disco.sh`: agrega la fecha y `df -h` a `logs/disco.log`.
  - `recordatorio.sh "<texto>"`: escribe el aviso en la bitácora y con `wall`.
- [ ] **Programar cron nueva**: comando (script de `tareas/` o comando libre) y horario con atajos
      (cada hora, diario HH:MM, semanal, mensual) o personalizado (5 campos). Se agrega a `$CRON_USUARIO`
      con una línea `# id=<n> <descripción>` encima.
- [ ] **Valida cada campo** del horario: minuto 0 a 59, hora 0 a 23, día 1 a 31, mes 1 a 12, día de
      semana 0 a 7; acepta `*`, `*/n`, `a,b` y `a-b`. Si es inválido, no toques el archivo.
- [ ] **Eliminar cron**: solo las de `$CRON_USUARIO`, por id, con confirmación.
- [ ] **at**: programar (`HH:MM`, `HH:MM tomorrow`, `now + 30 minutes`), ver (`atq`), ver contenido
      (`at -c N`), cancelar (`atrm N`).
- [ ] **Cargar ejemplos** (at): pago único a un proveedor que elijas, `recordatorio.sh` en 1 hora,
      `respaldar.sh etc bz2` a las 23:00.
- [ ] **Ver historial de pagos**: `ui_tabla_csv "$CSV_PAGOS"`.

## Cuidado con (errores que rompen cron sin avisar)

- **El `%` en cron significa salto de línea.** Al guardar un comando, cambia cada `%` por `\%`.
- **SELinux**: el archivo temporal para reescribir `$CRON_USUARIO` créalo **dentro de `/etc/cron.d`**
  con nombre que empiece con punto (ej. `.abarrotes_usuario.tmp`), luego `mv` y `restorecon`.
  Si lo creas en `/tmp`, cron lo ignora.
- En los campos del horario el `0` es un valor válido (para cancelar se usa `q`).
- El número de tarea `at` sale en el mensaje de error de `at`: `job 5 at ...`.

## Cómo probarlo a mano

1. Con 2 proveedores registrados, corre dos veces `sudo ./tareas/pago_distribuidores.sh`: solo debe
   haber 2 filas en pagos.
2. Crea una cron "cada minuto" que llame a `recordatorio.sh`, espera y búscala en la bitácora; luego bórrala.
3. Pon minuto `75`: debe rechazarlo.
4. Carga los ejemplos at, revísalos con `atq` y cancela uno. **Captura para el reporte.**

## Pruebas automáticas (en `pruebas/probar_tareas.sh`)

La validación de campos cron (válidos e inválidos), que el pago semanal no se duplique y que un pago
único con monto inválido falle. Las pruebas usan `$CRON_USUARIO` temporal, así que no tocan el cron real.
