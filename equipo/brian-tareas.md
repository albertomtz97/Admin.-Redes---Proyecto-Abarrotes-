# Brian: Tareas (cron, at y pago a distribuidores)

**Archivos:** `modulos/tareas.sh`, `tareas/pago_distribuidores.sh`, `config/abarrotes.cron`
**Rama:** `brian/tareas` · No dependes del módulo de nadie.

## Obligatorio

- [ ] **`tareas/pago_distribuidores.sh`**: por cada fila de `$CSV_USUARIOS` con rol `proveedor`
      guarda en `$CSV_PAGOS`: `fecha,proveedor,empresa,monto,semanal`. Al inicio carga la base:
      `source "$(dirname "$0")/../lib/comunes.sh"`
- [ ] **cron ya programadas**: agrega al final de `config/abarrotes.cron` (deja `@BASE_DIR@` tal cual):

```
# Pago a distribuidores, viernes 18:00
0 18 * * 5 root @BASE_DIR@/tareas/pago_distribuidores.sh
# Reporte de disco, diario 08:00
0 8 * * * root df -h >> @BASE_DIR@/logs/disco.log
```

- [ ] **Ver cron**: muestra `$CRON_FIJAS` y `$CRON_USUARIO`.
- [ ] **Programar cron**: pide los 5 campos del horario y el comando, y agrega al final de
      `$CRON_USUARIO` la línea `<5 campos> root <comando>`.
- [ ] **at ya programadas**: opción "cargar ejemplos" con 2 tareas, por ejemplo
      `echo "ruta/al/pago_distribuidores.sh" | at now + 1 hour` y un aviso a las `23:00`.
- [ ] **Programar at**: pide comando y hora: `echo "<comando>" | at <hora>`.
- [ ] **Ver at**: `atq`.

## No olvides

- En cada campo acepta solo números y `* , - /`. Un campo mal puede hacer que cron ignore
  todo el archivo.
- No aceptes `%` en comandos de cron (cron lo toma como salto de línea).
- Para separar los 5 campos usa `read -r -a campos <<< "$horario"` (así `*` no se convierte en
  nombres de archivos).

## Pruébalo

Corre `sudo ./instalar.sh` y revisa `/etc/cron.d/abarrotes`. Corre
`sudo ./tareas/pago_distribuidores.sh` con un proveedor registrado. Programa una cron cada minuto
y verifica que corra. Carga los ejemplos y revisa `atq`.
