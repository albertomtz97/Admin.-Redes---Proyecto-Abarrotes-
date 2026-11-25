# Instrucciones para el equipo

Hola. Aquí está lo que cada quien tiene que hacer, explicado simple.
**No necesitas saber git.** Tú programas tu parte, la pruebas en tu máquina virtual y se la mandas a Erick
en un `.zip`. Erick la junta con lo de los demás.

## ¿Quién hace qué?

| Persona | Módulo | Tus instrucciones |
|---|---|---|
| Beto | Gestión (usuarios y grupos) | [beto-gestion.md](beto-gestion.md) |
| Diego | Respaldo (tar, rsync, xfsdump) | [diego-respaldo.md](diego-respaldo.md) |
| Brian | Tareas (cron, at, pagos) | [brian-tareas.md](brian-tareas.md) |
| Gonzalo | Seguridad (Nagios, Wireshark, nmap) | [gonzalo-seguridad.md](gonzalo-seguridad.md) |
| Erick | Integración, pruebas y reporte | [erick-integracion.md](erick-integracion.md) |

## Cómo funciona (5 pasos)

1. **Prepara tu máquina virtual** con AlmaLinux siguiendo `docs/guia-maquina-virtual.md`
   (secciones 1, 2 y 5; puedes saltarte lo de GitHub).
2. **Erick te manda un `.zip`** con el proyecto. Descomprímelo dentro de la VM en `~/proyecto`
   y corre una vez:
   ```bash
   cd ~/proyecto
   sudo ./instalar.sh
   ```
3. **Programa tu módulo** siguiendo tu archivo de instrucciones. Usa
   [plantilla_modulo.sh](plantilla_modulo.sh) como punto de partida: ya trae la forma correcta.
4. **Pruébalo** en la VM:
   ```bash
   bash -n modulos/<tu-modulo>.sh          # revisa que no haya errores de escritura
   ./pruebas/probar_<tu-modulo>.sh         # tus pruebas automáticas
   sudo ./menu.sh                          # pruébalo a mano desde el menú
   ```
5. **Mándale a Erick un `.zip`** solo con **tus** archivos (la lista exacta está en tu instrucción),
   con este nombre: `<modulo>_<tu-nombre>_<fecha>.zip`, por ejemplo `respaldo_diego_2026-11-30.zip`.

## Reglas de oro (si no se cumplen, se rompe algo)

1. **Solo cambias tus archivos.** Nunca edites `lib/comunes.sh`, `menu.sh` ni `instalar.sh`.
   Si necesitas algo ahí, pídeselo a Erick.
2. **Programa dentro de la VM** (con `nano`, `vim` o VS Code conectado a la VM). Si editas en
   Windows con el Bloc de notas, los archivos se rompen por el fin de línea (CRLF).
   Si te pasa, se arregla con: `sed -i 's/\r$//' archivo.sh`
3. **Todas tus funciones empiezan con el nombre de tu módulo**: `gestion_`, `respaldo_`, `tareas_`, `seguridad_`.
   Si dos personas usan el mismo nombre de función, una borra a la otra.
4. **Cada función lleva su comentario** (qué hace, qué recibe, qué regresa). Mira la plantilla.
5. **Nada de `echo`, `read` o `clear` para pantallas.** Usa las funciones `ui_*` (abajo). Así después
   se le puede poner interfaz gráfica sin tocar tu código.
6. **Si algo falla, no digas que funcionó**: no escribas en el CSV ni en la bitácora cuando un comando falla.
7. **Manda siempre el `.zip` completo de tus archivos**, no pedazos de código por chat.

## Funciones que ya existen y puedes usar

Vienen en `lib/comunes.sh` (no lo edites, solo úsalo):

| Función | Para qué | Ejemplo |
|---|---|---|
| `ui_menu "Título" etiqueta "texto" ...` | Mostrar un menú | `op=$(ui_menu "RESPALDO" crear "Crear respaldo" ver "Ver historial") \|\| return` |
| `ui_pedir "Etiqueta" [valor inicial]` | Pedir un dato (`q` cancela) | `nombre=$(ui_pedir "Nombre del grupo") \|\| return` |
| `ui_password "Etiqueta"` | Pedir contraseña oculta | `pass=$(ui_password "Contraseña") \|\| return` |
| `ui_confirmar "¿Pregunta?"` | Sí o no | `ui_confirmar "¿Borrar?" \|\| return` |
| `ui_mensaje "texto"` / `ui_error "texto"` | Aviso o error | `ui_error "No existe el usuario"` |
| `ui_tabla_csv archivo` | Mostrar un CSV como tabla | `ui_tabla_csv "$CSV_USUARIOS"` |
| `ui_archivo archivo` / `ui_comando cmd ...` | Ver un archivo / ejecutar y mostrar salida | `ui_comando atq` |
| `registrar modulo "mensaje"` | Anotar en la bitácora | `registrar respaldo "Respaldo creado: x.tar.gz"` |
| `validar_campo`, `validar_usuario`, `validar_telefono`, `validar_correo`, `validar_monto` | Validar datos | `validar_telefono "$tel" \|\| ui_error "Teléfono inválido"` |
| `csv_agregar`, `csv_existe`, `csv_quitar`, `csv_actualizar` | Manejar CSV | `csv_existe "$CSV_USUARIOS" 1 "jose"` |
| `requiere comando paquete` | Revisar que algo esté instalado | `requiere nmap nmap \|\| return` |
| `abrir_como_usuario cmd ...` | Abrir ventanas (navegador, Wireshark) | `abrir_como_usuario xdg-open http://localhost/nagios` |

Variables listas: `$CSV_USUARIOS`, `$CSV_GRUPOS`, `$CSV_PAGOS`, `$CSV_RESPALDOS`, `$DATOS_DIR`,
`$RESPALDOS_DIR`, `$LOG_FILE`, `$SRV_DIR`, `$CRON_FIJAS`, `$CRON_USUARIO`.

## ¿Dónde está el detalle completo?

Cada módulo tiene su documento técnico en `docs/specs/0001-sistema-abarrotes/`. Tu instrucción es
el resumen fácil; si tienes una duda de detalle, ahí está la respuesta. Si no la encuentras,
pregúntale a Erick.
