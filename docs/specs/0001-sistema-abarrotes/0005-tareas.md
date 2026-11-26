# 0005. Tareas: cron, at y pagos a distribuidores

## Summary

Deja cuatro tareas cron ya programadas (pago semanal a distribuidores, respaldo nocturno, limpieza de
respaldos viejos, reporte de disco), permite crear y borrar tareas cron nuevas con atajos de horario,
y maneja tareas at de una sola vez (programar, ver, cancelar y cargar ejemplos). Los pagos se
guardan en `pagos.csv` y se pueden ver desde el menú.

Razón corta: cumple "tareas ya programadas más opción de programar nuevas" tanto en cron como en at,
con el ejemplo del profesor (pago a distribuidores) funcionando con datos reales del CSV.

## Requirements

**User stories**:
- Como dueño de la tienda, quiero que cada viernes se registre el pago a cada distribuidor según su monto.
- Como administrador, quiero programar tareas repetidas (cron) o de una vez (at) sin saber la sintaxis exacta.
- Como administrador, quiero ver el historial de pagos para comprobar que la tarea corrió.

**Acceptance criteria**:
- **AC-1**: Después de `instalar.sh`, `/etc/cron.d/abarrotes` tiene: pago viernes 18:00, respaldo de `datos/` diario 02:00, limpieza de respaldos domingo 03:00, reporte de disco diario 08:00, todos como `root` con rutas absolutas al proyecto.
- **AC-2**: `tareas/pago_distribuidores.sh` agrega a `pagos.csv` una fila `fecha,proveedor,empresa,monto,semanal` por cada proveedor de `usuarios.csv` con monto mayor a 0; si ese proveedor ya tiene pago semanal ese día, lo salta. Sin proveedores, solo registra "sin proveedores".
- **AC-3**: `tareas/pago_unico.sh <proveedor> <monto>` valida que el proveedor exista con rol proveedor y el monto sea válido, y agrega una fila con tipo `unico`; si no, regresa 1 sin escribir.
- **AC-4**: `tareas/respaldar.sh <origen> <gz|bz2>` llama a `respaldo_crear` (el éxito lo registra Respaldo; este script solo registra `ERROR:` si falla); `tareas/limpiar_respaldos.sh` elimina con `respaldo_eliminar` los respaldos de más de 30 días (todos los formatos); `tareas/reporte_disco.sh` agrega `df -h` con fecha a `logs/disco.log`; `tareas/recordatorio.sh "<texto>"` escribe el aviso en bitácora y con `wall` (en GNOME Terminal puede no verse; la bitácora es la prueba). Todos usan `set -Eeuo pipefail` y registran con módulo `tareas`, incluidas sus fallas como `ERROR:`.
- **AC-5**: Ver tareas cron muestra las fijas y las de usuario, cada una con su descripción (línea `# ...` encima) y su horario en palabras (ej. "viernes 18:00"). Horarios que no son un atajo simple (`*/n`, listas, rangos) se muestran con sus 5 campos tal cual.
- **AC-6**: Programar cron: elige comando (script de `tareas/` con sus argumentos, o comando libre) y horario por atajo (cada hora, diario HH:MM, semanal día y HH:MM, mensual día y HH:MM) o personalizado (5 campos; `q` cancela, `0` es un valor válido). Se agrega a `$CRON_USUARIO` con una línea `# id=<n> <descripción>` antes. Se ejecuta como `root`. Cada `%` del comando se guarda como `\%` (en cron `%` significa salto de línea). El archivo se reescribe con un temporal **dentro de `/etc/cron.d` cuyo nombre empieza con punto** (cron lo ignora), luego `mv` y `restorecon` (si el temporal viniera de `/tmp`, SELinux haría que cron lo rechazara).
- **AC-7**: Cada campo cron se valida: `*`, número en rango, `*/n`, listas `a,b` y rangos `a-b` dentro del rango (minuto 0 a 59, hora 0 a 23, día 1 a 31, mes 1 a 12, día de semana 0 a 7). Inválido se rechaza sin tocar el archivo.
- **AC-8**: Eliminar cron solo ofrece tareas de `abarrotes_usuario`, por id, con confirmación; las fijas no se pueden borrar.
- **AC-9**: at: programar (comando como en AC-6 y hora en formato `HH:MM`, `HH:MM tomorrow` o `now + N minutes`), ver pendientes (`atq`), ver contenido (`at -c`), cancelar (`atrm`). El comando se pasa a `at` con argumentos escapados (`printf '%q '`, porque at lo corre con `/bin/sh`); el número de tarea se toma del mensaje `job N at ...` que `at` imprime en stderr y se registra. Si `at` rechaza la hora, se muestra su error.
- **AC-10**: Cargar ejemplos programa con at: pago único (eliges proveedor de la lista y monto; si no hay proveedores, se salta con aviso), `tareas/recordatorio.sh "Revisar inventario"` en 1 hora, `tareas/respaldar.sh etc bz2` a las 23:00.
- **AC-11**: Ver historial de pagos muestra `pagos.csv` en tabla.
- **AC-12**: `pruebas/probar_tareas.sh` pasa (validación de campos cron, pago semanal sin duplicar, pago único inválido).

## Feature design

**Menú**:
```
TAREAS
├── cron: ver · programar nueva · eliminar (solo de usuario)
├── at: ver pendientes · programar nueva · ver contenido · cancelar · cargar ejemplos
└── Ver historial de pagos
```

**Archivos**:
- `config/abarrotes.cron` (plantilla, va en git):
  ```
  SHELL=/bin/bash
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
  MAILTO=""
  # Pago semanal a distribuidores
  0 18 * * 5 root @BASE_DIR@/tareas/pago_distribuidores.sh >> @BASE_DIR@/logs/cron.log 2>&1
  # Respaldo nocturno de datos (gzip)
  0 2  * * * root @BASE_DIR@/tareas/respaldar.sh datos gz >> @BASE_DIR@/logs/cron.log 2>&1
  # Limpieza de respaldos de más de 30 días
  0 3  * * 0 root @BASE_DIR@/tareas/limpiar_respaldos.sh >> @BASE_DIR@/logs/cron.log 2>&1
  # Reporte de espacio en disco
  0 8  * * * root @BASE_DIR@/tareas/reporte_disco.sh >> @BASE_DIR@/logs/cron.log 2>&1
  ```
- `$CRON_FIJAS` (`/etc/cron.d/abarrotes`, generado por `instalar.sh`) y `$CRON_USUARIO` (`/etc/cron.d/abarrotes_usuario`, solo lo escribe este módulo). Ambas rutas se pueden cambiar para las pruebas, así `probar_tareas.sh` nunca toca las reales. Las tareas de usuario llevan el mismo `PATH` y `>> logs/cron.log 2>&1`.
- Scripts en `tareas/`: cargan `lib/comunes.sh` (y `modulos/respaldo.sh` cuando lo necesitan), no usan pantallas.

**Funciones de lógica** (se prueban): `tareas_validar_campo_cron <valor> <min> <max>`,
`tareas_horario_atajo <tipo> <args>` (devuelve los 5 campos), `tareas_describir_horario <5 campos>`,
`tareas_siguiente_id`, `tareas_agregar_cron <horario> <comando> <descripcion>`, `tareas_quitar_cron <id>`.

**Value sourcing**:
| Acción | Valor | Fuente |
|---|---|---|
| pago semanal | proveedores y montos | `usuarios.csv` filas con rol `proveedor` |
| pago semanal | empresa | columna `empresa` de `usuarios.csv` |
| pago único | proveedor, monto | argumentos (en ejemplos: elegidos en pantalla) |
| cron usuario | id | mayor `id=` existente en `$CRON_USUARIO` + 1 (1 si no hay) |
| cron fijas | descripción | línea `# ...` encima de cada tarea en la plantilla |
| at | número de tarea | stderr de `at` (`job N at ...`) |
| cron | ruta del proyecto | `@BASE_DIR@` reemplazado por `instalar.sh` |
| limpieza | antigüedad | 30 días fijo (`find -mtime +30`) |

**Key invariants**:
- `instalar.sh` nunca modifica `abarrotes_usuario`.
- Un mismo proveedor no recibe dos pagos semanales el mismo día.
- Solo `respaldo.sh` escribe `respaldos.csv`; las tareas usan sus funciones.

**Security model**: todas las tareas corren como root (decisión del ingeniero). El comando libre no
abre un hueco nuevo porque solo root puede usar el menú, pero cada tarea creada se registra completa
en la bitácora para que quede rastro. Se rechazan comandos vacíos o con salto de línea.

**Critical test scenarios**:
- Happy path: con dos proveedores, correr `pago_distribuidores.sh` dos veces; solo hay dos filas, verifica **AC-2**.
- Cron real: crear tarea "cada minuto" que escriba en bitácora, esperar y verla, luego borrarla, verifica **AC-6**, **AC-8**.
- Falla: minuto `75`, rechazado y archivo igual, verifica **AC-7**.
- at: cargar ejemplos, ver en `atq`, cancelar uno, verifica **AC-9**, **AC-10** (captura para el reporte).

## Build plan

1. Scripts de `tareas/` (pago semanal, pago único, respaldar, limpiar, reporte de disco, recordatorio) con comentarios, satisfies **AC-2**, **AC-3**, **AC-4**.
2. Plantilla `config/abarrotes.cron` con las 4 fijas (`instalar.sh` ya la genera desde 0002), satisfies **AC-1**.
3. Funciones de lógica cron (validar, atajos, describir, agregar, quitar), satisfies **AC-6**, **AC-7**, **AC-8**.
4. `pruebas/probar_tareas.sh`, satisfies **AC-12**.
5. Pantallas cron y at, cargar ejemplos, historial de pagos, satisfies **AC-5**, **AC-6**, **AC-8**, **AC-9**, **AC-10**, **AC-11**.
6. Revisión manual en AlmaLinux y commit, satisfies **AC-1** a **AC-12**.

## Consequences

**Negative / tradeoffs**:
- Los pagos son simulados (solo se registran); no hay conexión a un banco.
- Si mueves la carpeta del proyecto, las cron fijas fallan hasta correr `instalar.sh` otra vez; las de usuario guardan la ruta con la que se crearon.
