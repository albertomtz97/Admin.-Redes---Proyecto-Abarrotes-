# 0001. Sistema de administración para la tienda de abarrotes

**Date**: 2026-11-25
**Status**: Accepted

## Summary

Este spec decide cómo se construye todo el proyecto: un menú en Bash para AlmaLinux, dividido en
módulos independientes (Base, Gestión, Respaldo, Tareas, Seguridad). Primero todo funciona en
terminal con texto simple; las pantallas pasan por una capa de funciones `ui_*` para que después
puedas ponerle interfaz gráfica cambiando un solo archivo. Cada módulo se entrega completo, con
comentarios en cada función y con sus pruebas, antes de empezar el siguiente, así nunca queda
código roto.

## Structure

Cada hijo es un módulo que se construye por separado. Este `index.md` guarda lo que todos
comparten (el contrato entre módulos).

| Spec | Qué es | Decisión que sostiene |
|---|---|---|
| [0002-base.md](0002-base.md) | Menú principal, `lib/comunes.sh` (capa `ui_*`, bitácora, validaciones), `instalar.sh`, pruebas, migración de lo que ya existe | La base que usan todos; se construye primero |
| [0003-gestion.md](0003-gestion.md) | Usuarios (agregar, eliminar, modificar, consultar) y grupos con carpeta compartida | Requisito Gestión; roles comprador, proveedor, empleado |
| [0004-respaldo.md](0004-respaldo.md) | tar gzip, tar bzip2, restaurar, rsync, xfsdump de `/boot` | Requisito Respaldo con dos opcionales fáciles |
| [0005-tareas.md](0005-tareas.md) | cron fijas y de usuario, at, pagos a distribuidores | Requisito Tareas; usa `respaldo_crear` del 0004 |
| [0006-seguridad.md](0006-seguridad.md) | Nagios, Wireshark y nmap con 5 opciones | Requisito Seguridad (segunda pantalla) |

**Orden de construcción**: 0002 → 0003 → 0004 → 0005 → 0006. Tareas va después de Respaldo porque
llama a `respaldo_crear`. La interfaz gráfica (fase 2) queda fuera de este spec, ver Follow-up.

**Regla para no dejar código roto**: un módulo está terminado solo cuando (1) `bash -n` no marca
errores, (2) `pruebas/probar_<modulo>.sh` pasa, (3) la lista manual de su spec se revisó en
AlmaLinux, (4) cada función tiene su bloque de comentario. Solo entonces se hace commit en `dev`
y se empieza el siguiente.

## Decision

**Chosen option**: Option 1: Monolito modular en Bash, terminal primero con capa `ui_*`.

Un solo programa (`menu.sh`) que carga con `source` una librería común y un archivo por módulo;
toda la entrada y salida de pantalla pasa por funciones `ui_*`, implementadas hoy en texto.

**Implementation skills**: `bash-defensive-patterns` (`wshobson/agents`, `.agents/skills/bash-defensive-patterns/`) · `shellcheck-configuration` (`wshobson/agents`, `.agents/skills/shellcheck-configuration/`)

## Rationale

Razonamiento y opciones: ver [rationale.md](rationale.md).

## Proposed stack

| Capa | Elección | Razón |
|---|---|---|
| Sistema operativo | AlmaLinux 9 | Lo pide el profesor. |
| Lenguaje | Bash 5 | Lo que evalúa la materia; ya hay código en Bash. |
| Patrón | Monolito modular: `menu.sh` + `lib/comunes.sh` + `modulos/*.sh` cargados con `source` | Un programa simple; cada módulo es un archivo con un dueño. |
| Interfaz fase 1 | Texto (`echo`/`read`) detrás de la capa `ui_*` | Primero que funcione; la interfaz se cambia después en un solo archivo. |
| Interfaz fase 2 | Pendiente (zenity va adelante) | La decides cuando termines de estudiar interfaces; ver Follow-up. |
| Datos | Archivos CSV en `datos/` | Ya lo usan, se leen con `awk`/`column`, alcanzan para este tamaño. |
| Bitácora | `logs/bitacora.log`, formato `fecha \| usuario \| modulo \| mensaje` | Permite filtrar por módulo. |
| Tareas programadas | cronie (`/etc/cron.d/`) y at (`atd`) | Requisito; vienen en AlmaLinux. |
| Respaldo | tar + gzip, tar + bzip2, rsync, xfsdump/xfsrestore | Obligatorios más dos opcionales de poco esfuerzo. |
| Seguridad | Nagios Core (paquetes EPEL) + httpd, Wireshark, nmap | Obligatorios más nmap; EPEL instala en minutos. |
| Paquetes | `dnf` + repositorio EPEL | Forma estándar de instalar en AlmaLinux. |
| Instalación | `instalar.sh` que se puede correr varias veces | Deja una máquina limpia lista con un comando. |
| Pruebas | `pruebas/probar_<modulo>.sh` + lista manual por módulo + `bash -n` (y `shellcheck` si está) | Evita romper lo que ya funcionaba. |
| Control de versiones | git: `main` (entregas), `dev` (integración), `feature/<modulo>` | Permite repartir módulos después. |

## Contrato entre módulos

### Estructura de carpetas

```
proyecto/
├── .gitattributes             # fuerza fin de línea LF (el repo también vive en Windows)
├── menu.sh                    # punto de entrada (sudo ./menu.sh)
├── instalar.sh                # prepara la máquina; se puede correr varias veces
├── lib/
│   └── comunes.sh             # rutas, ui_*, registrar, validar_*, requiere, abrir_como_usuario
├── modulos/
│   ├── gestion.sh
│   ├── respaldo.sh
│   ├── tareas.sh
│   └── seguridad.sh
├── tareas/                    # scripts que ejecutan cron y at (sin pantallas)
├── config/
│   └── abarrotes.cron         # plantilla de las cron fijas (@BASE_DIR@ se reemplaza al instalar)
├── pruebas/
│   ├── lib_pruebas.sh         # verificar(), resumen
│   ├── probar_<modulo>.sh
│   └── correr_todas.sh
├── docs/
├── datos/                     # no va a git
├── respaldos/                 # no va a git
└── logs/                      # no va a git
```

Fuera del proyecto: `/srv/abarrotes/<grupo>/` (carpetas compartidas), `/etc/cron.d/abarrotes`
(cron fijas) y `/etc/cron.d/abarrotes_usuario` (cron creadas desde el menú).

### Reglas de cada módulo

1. Un solo archivo `modulos/<modulo>.sh` que **solo define funciones** (no ejecuta nada al cargarse).
2. Una función de entrada `menu_<modulo>`; al volver, hace `return`.
3. Todas sus funciones llevan el prefijo del módulo (`gestion_`, `respaldo_`, `tareas_`, `seguridad_`).
   Todos los módulos viven en el mismo shell; sin prefijo, dos funciones iguales se pisan.
4. Variables dentro de funciones siempre con `local`.
5. Nada de `echo`, `read` o `clear` directos para pantallas: solo funciones `ui_*`.
6. Toda acción que cambia el sistema se anota con `registrar <modulo> "mensaje"` cuando tuvo éxito.
   Las fallas se anotan como `registrar <modulo> "ERROR: ..."` en los scripts que corren sin nadie
   mirando (`tareas/*.sh`, `instalar.sh`); en el menú basta con mostrar el error. Nunca se registra
   éxito de algo que falló. Etiquetas de módulo: `base`, `gestion`, `respaldo`, `tareas`, `seguridad`.
7. Se revisa el código de salida de cada comando que cambia el sistema; si falla, no se escribe en
   CSV ni se registra éxito.
8. Nunca `eval`; siempre comillas en variables; los CSV se editan con `awk` por coincidencia exacta
   de campo (nunca `sed` con texto del usuario como patrón).
9. Modo estricto (`set -Eeuo pipefail`) solo en scripts que no son interactivos: `instalar.sh`,
   `tareas/*.sh` y `pruebas/*.sh`. Nunca en `menu.sh`, `lib/comunes.sh` ni `modulos/*.sh`: el menú
   usa a propósito comandos que fallan (como `id usuario` para saber si existe) y el modo estricto
   lo cerraría. Ahí cada comando importante se revisa a mano (regla 7).
10. Lógica separada de pantallas: la función que hace el trabajo (ej. `respaldo_crear`) recibe
   parámetros y no pregunta nada; la función de menú pregunta y la llama. Así se puede probar.

### Comentarios (estándar del proyecto)

Cada archivo abre con un encabezado y cada función lleva un bloque:

```bash
#!/bin/bash
# ==========================================================
# modulos/gestion.sh
# Módulo 1: usuarios y grupos de la tienda.
# Requiere: lib/comunes.sh cargado antes.
# ==========================================================

# ------------------------------------------
# gestion_agregar_usuario
# Crea un usuario del sistema con su rol, lo mete a su
# grupo y lo guarda en datos/usuarios.csv.
# Recibe: nada (pregunta los datos)
# Regresa: 0 si se creó, 1 si falló o se canceló
# ------------------------------------------
gestion_agregar_usuario() {
    ...
}
```

### Archivos de datos (formato fijo; el encabezado es la primera línea)

| Archivo | Columnas | Dueño (escribe) | Lo leen |
|---|---|---|---|
| `datos/usuarios.csv` | `usuario,rol,telefono,correo,empresa,monto` | Gestión | Tareas (pagos) |
| `datos/grupos.csv` | `grupo,descripcion,fecha` | Gestión | Gestión |
| `datos/pagos.csv` | `fecha,proveedor,empresa,monto,tipo` | Tareas | Tareas |
| `datos/respaldos.csv` | `fecha,archivo,origen,formato,tamano,estado` | Respaldo (Tareas solo vía sus funciones) | Respaldo |
| `datos/nmap/*.txt` | salida de nmap `-oN` | Seguridad | Seguridad |
| `logs/bitacora.log` | `fecha \| usuario \| modulo \| mensaje` | todos vía `registrar` | Base (visor) |

Valores: `rol` ∈ {comprador, proveedor, empleado}; `empresa` y `monto` son `N/A` si el rol no es
proveedor; `tipo` ∈ {semanal, unico}; `formato` ∈ {gz, bz2, xfsdump}; `estado` ∈ {activo, eliminado}.
En `respaldos.csv`, `archivo` es solo el nombre (sin carpeta, vive en `respaldos/`) y `origen` es
la ruta absoluta respaldada; `tamano` es `du -h` (ej. `4.0K`).
Fechas `AAAA-MM-DD HH:MM:SS`. Ningún campo puede tener coma ni salto de línea; ningún mensaje de
bitácora puede tener `|` (`registrar` lo reemplaza).

### Funciones que un módulo usa de otro

| Función | Definida en | La usa | Firma |
|---|---|---|---|
| `respaldo_crear` | `modulos/respaldo.sh` | `tareas/respaldar.sh` (cron y at) | `respaldo_crear <origen> <gz\|bz2>`: imprime la ruta creada; regresa 1 si falla |
| `respaldo_eliminar` | `modulos/respaldo.sh` | `tareas/limpiar_respaldos.sh` (cron) | `respaldo_eliminar <archivo>`: acepta nombre o ruta (usa `basename`); borra el archivo si existe y marca la fila `eliminado`; regresa 1 solo si no hay fila |
| `gestion_crear_grupo` | `modulos/gestion.sh` | `instalar.sh` (grupos de rol) | `gestion_crear_grupo <grupo> <descripcion>`: idempotente; crea grupo, fila y carpeta solo si faltan |

El resto de la comunicación entre módulos es por los CSV de arriba.

## Consequences

**Positive**:
- Cada módulo se puede construir, probar y entregar solo; si alguien se une, toma un archivo.
- Pasar a interfaz gráfica toca solo `lib/comunes.sh`.
- Las pruebas automáticas avisan si un cambio rompe algo que ya funcionaba.

**Negative / tradeoffs**:
- Separar lógica de pantallas y escribir pruebas toma más tiempo que hacer cada pantalla directo.
- CSV no tiene candados: dos procesos escribiendo al mismo tiempo (por ejemplo, el menú y una cron)
  podrían mezclar líneas. Con el volumen de este proyecto es poco probable; se acepta.
- Todo corre como root (`sudo`): un error en un módulo afecta al sistema entero. Por eso las reglas
  de validación y borrado protegido.
- Las ventanas gráficas (Nagios, Wireshark y la futura interfaz) necesitan abrirse como tu usuario
  normal desde un proceso root; depende de que exista sesión gráfica.

**Neutral**:
- `Datos_de_Usuarios/` pasa a `datos/` y el CSV cambia de columnas (lo hace 0002).
- Este spec reemplaza la documentación anterior (`docs/arquitectura.md`, `docs/plan.md`, `docs/modulos/`), ya borrada.

## Follow-up

- [ ] **Interfaz fase 2**: cuando termines la fase 1 y hayas estudiado interfaces, corre `/architect interfaz fase 2`. Zenity va adelante; implica ejecutar zenity como `$SUDO_USER` (igual que `abrir_como_usuario`) y decidir qué pasa sin escritorio (la versión de texto ya existirá como respaldo).
- [x] Borrados `docs/arquitectura.md`, `docs/plan.md` y `docs/modulos/`; el README y `docs/requisitos.md` apuntan a este spec.
- [ ] Servidores MCP para nmap, Wireshark o Nagios: pospuesto. Solo tienen sentido si el agente trabaja desde la AlmaLinux; los candidatos encontrados son comunitarios (`nagios-mcp`, `wireshark-mcp`, `mcp-nmap`).
- [ ] Registrar en un `AGENTS.md` del proyecto los dos skills instalados (lo hace `/sync` o `/audit`).
- [ ] Antes de la entrega: actualizar el reporte `Proyecto final.docx` con una sección por módulo, Resultados y Conclusión.
