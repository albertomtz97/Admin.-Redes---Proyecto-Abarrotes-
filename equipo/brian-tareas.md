# Brian: Tareas (cron, at y pago a distribuidores)

**Archivos:** `modulos/tareas.sh`, `tareas/pago_distribuidores.sh`, `config/abarrotes.cron`
**Rama:** `brian/tareas` · No dependes del módulo de nadie.

Antes lee [GUIA.md](GUIA.md): explica el proyecto, cómo preparar la VM y cómo subir tu trabajo.
Requisitos del proyecto: [docs/requisitos.md](../docs/requisitos.md).

## Qué vas a construir

La opción **Tareas** del menú: hacer que el sistema ejecute cosas solo. Linux tiene dos formas:

| | **cron** | **at** |
|---|---|---|
| Cuándo corre | Se **repite** (cada día, cada viernes...) | **Una sola vez** |
| Ejemplo | Pagar cada viernes a las 18:00 | Un aviso hoy a las 23:00 |

El profesor pide, **para las dos**: tener tareas **ya programadas** y poder **programar nuevas**
desde el menú. Su ejemplo es el pago automático a los distribuidores.

```
TAREAS
├── cron: ver · programar nueva
└── at:   ver · programar nueva · cargar ejemplos
```

## Cómo se escribe una tarea cron

Cinco campos de horario, el usuario y el comando:

```
0    18   *    *    5     root   /ruta/script.sh
│    │    │    │    └ día de la semana (0-7; 5 = viernes)
│    │    │    └ mes (1-12)
│    │    └ día del mes (1-31)
│    └ hora (0-23)
└ minuto (0-59)
```

`*` significa "cualquiera". `*/5` en minuto significa "cada 5 minutos".

Usamos dos archivos:
- `$CRON_FIJAS` (`/etc/cron.d/abarrotes`): las ya programadas. **No lo edites a mano**:
  `instalar.sh` lo genera a partir de `config/abarrotes.cron`.
- `$CRON_USUARIO` (`/etc/cron.d/abarrotes_usuario`): las que se crean desde el menú.

## Obligatorio, paso a paso

### 1. El script de pago: `tareas/pago_distribuidores.sh`
Es un script aparte (no una función del menú) porque cron lo ejecuta sin nadie presente: **no
pregunta nada ni usa `ui_*`**. El pago es simulado: solo se anota.

Empieza así:

```bash
#!/bin/bash
source "$(dirname "$0")/../lib/comunes.sh"   # rutas, csv_agregar, registrar
```

Luego lee `$CSV_USUARIOS`, columnas `usuario,rol,telefono,correo,empresa,monto`. La primera línea es
el encabezado. Para recorrerlo:

```bash
while IFS=, read -r usuario rol telefono correo empresa monto; do
    # si rol es "proveedor", agrega su pago
done < <(tail -n +2 "$CSV_USUARIOS")
```

Por cada proveedor guarda en `$CSV_PAGOS`: `fecha,proveedor,empresa,monto,semanal`.
Al final usa `registrar tareas "..."`.

Para probar no necesitas el módulo de Beto: agrega a mano en `datos/usuarios.csv` una línea como
`prov1,proveedor,N/A,N/A,Bimbo,1500` (el archivo se crea con `instalar.sh`).

### 2. cron ya programadas
Agrega **al final** de `config/abarrotes.cron` (deja `@BASE_DIR@` tal cual: el instalador lo cambia
por la ruta real del proyecto):

```
# Pago a distribuidores, viernes 18:00
0 18 * * 5 root @BASE_DIR@/tareas/pago_distribuidores.sh
# Reporte de disco, diario 08:00
0 8 * * * root df -h >> @BASE_DIR@/logs/disco.log
```

Después corre `sudo ./instalar.sh`: copia las tareas y da permiso de ejecución a tu script.

### 3. Ver cron
Muestra los dos archivos, por ejemplo `ui_archivo "$CRON_FIJAS"` y `ui_archivo "$CRON_USUARIO"`.

### 4. Programar cron nueva
Pide el horario (los 5 campos juntos, ej. `30 9 * * 1`) y el comando. Revisa los datos y agrega al
final de `$CRON_USUARIO` (con `>>`) la línea `<5 campos> root <comando>`. Registra en la bitácora.

### 5. at ya programadas
Una opción "cargar ejemplos" que cree 2 tareas. `at` recibe el comando por la entrada:

```bash
echo "$BASE_DIR/tareas/pago_distribuidores.sh" | at now + 1 hour
echo "wall 'Hacer corte de caja'" | at 23:00
```

(`wall` muestra un mensaje en las terminales abiertas.)

### 6. Programar at nueva
Pide comando y hora: `echo "$comando" | at $hora` (sin comillas en `$hora` para que
`now + 1 hour` funcione). Si `at` falla (hora mal escrita), muestra `ui_error`.

### 7. Ver at
`ui_comando atq` lista las pendientes (número y fecha). `at -c <número>` enseña qué ejecutará.

## No olvides

- En cada campo del horario acepta solo números y `* , - /`. Un campo mal puede hacer que cron
  ignore todo el archivo.
- Para separar los 5 campos usa `read -r -a campos <<< "$horario"` (así `*` no se convierte en
  nombres de archivos) y revisa que sean exactamente 5.
- No aceptes `%` en comandos de cron (cron lo toma como salto de línea).

## Terminaste cuando

1. `sudo ./instalar.sh` y `cat /etc/cron.d/abarrotes` muestra tus 2 tareas con la ruta real.
2. `sudo ./tareas/pago_distribuidores.sh` agrega un pago por cada proveedor en `datos/pagos.csv`.
3. Desde el menú creas una cron con horario `* * * * *` y comando `date >> /tmp/prueba_cron.txt`;
   en 1 o 2 minutos el archivo tiene líneas. **Después borra esa línea** de `$CRON_USUARIO`
   (`sudo nano`) para que no siga corriendo.
4. Cargas los ejemplos at y aparecen en "ver at".
5. Un horario incompleto o con letras se rechaza.

Guarda capturas de cada opción para el reporte.
