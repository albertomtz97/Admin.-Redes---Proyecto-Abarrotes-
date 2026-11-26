# Cómo trabajar en este proyecto

## Para qué es este archivo

Es la guía única para el equipo. **Léelo tú antes de empezar.** Si usas una herramienta de IA
(Claude Code, Copilot, Cursor, ChatGPT, Codex), pásaselo o dile que lo lea antes de hacer cualquier
cosa (hay un prompt listo al final). Si algo de aquí choca con otro documento: en lo de git manda
[LEEME.md](LEEME.md); en lo técnico manda `docs/specs/0001-sistema-abarrotes/index.md`.

## 1. Tu rama y tus archivos

Solo creas o cambias los archivos de tu fila. Nada más.

| Persona | Rama | Archivos que puedes crear/modificar | Instrucción y spec |
|---|---|---|---|
| Beto | `beto/gestion` | `modulos/gestion.sh`, `pruebas/probar_gestion.sh` | [beto-gestion.md](beto-gestion.md) · `0003-gestion.md` |
| Diego | `diego/respaldo` | `modulos/respaldo.sh`, `pruebas/probar_respaldo.sh` | [diego-respaldo.md](diego-respaldo.md) · `0004-respaldo.md` |
| Brian | `brian/tareas` | `modulos/tareas.sh`, `tareas/pago_distribuidores.sh`, `tareas/pago_unico.sh`, `tareas/respaldar.sh`, `tareas/limpiar_respaldos.sh`, `tareas/reporte_disco.sh`, `tareas/recordatorio.sh`, `config/abarrotes.cron`, `pruebas/probar_tareas.sh` | [brian-tareas.md](brian-tareas.md) · `0005-tareas.md` |
| Gonzalo | `gonzalo/seguridad` | `modulos/seguridad.sh`, `pruebas/probar_seguridad.sh` | [gonzalo-seguridad.md](gonzalo-seguridad.md) · `0006-seguridad.md` |
| Erick | `erick/base` | `lib/comunes.sh`, `menu.sh`, `instalar.sh`, `docs/`, `equipo/`, integración | [erick-integracion.md](erick-integracion.md) · `0002-base.md` |

Los specs están en `docs/specs/0001-sistema-abarrotes/`.

## 2. Flujo de trabajo con git

**Beto (una sola vez):** si ya trabajaste en `dev` sin subir nada, haz commit de todo y luego:
```bash
git switch -c beto/gestion
git push -u origin beto/gestion
git switch dev
git reset --hard origin/dev
```
`reset --hard` borra lo que no tenga commit: primero el commit y la rama.

**Primera vez** (dentro de la VM con AlmaLinux):
```bash
git clone https://github.com/albertomtz97/Admin.-Redes---Proyecto-Abarrotes-.git proyecto
cd proyecto
git switch <tu-nombre>/<tu-modulo>
sudo ./instalar.sh
```

**Cada día:**
```bash
git switch dev && git pull                 # baja lo último que Erick unió a dev
git switch <tu-nombre>/<tu-modulo>
git merge dev                              # trae esos cambios a tu rama
# ...programa tu módulo...
git add <solo tus archivos>                # nunca "git add ."
git commit -m "<modulo>: <qué hiciste>"    # ej.: respaldo: agrega respaldo con tar
git push
```

**Entregar:** abre un pull request de tu rama hacia `dev` (en GitHub o con `gh pr create --base dev`).
Erick lo revisa y lo une. `main` solo recibe `dev` cuando todo pasa las pruebas.

## 3. Lo que nunca se hace

- Tocar archivos de otra persona. Nunca edites `lib/comunes.sh`, `menu.sh` ni `instalar.sh`
  (solo Erick, en `erick/base`); si necesitas algo ahí, pídeselo.
- Hacer commit directo en `dev` o `main` (tampoco Erick): todo entra por pull request.
- `git add .`: agrega solo tus archivos por nombre.
- Subir `datos/`, `logs/` o `respaldos/`.
- Cambiar las columnas o el formato de los CSV (están fijos en el contrato).
- Usar `echo`, `read` o `clear` para pantallas: solo funciones `ui_*`.
- Escribir en el CSV o en la bitácora cuando un comando falló.
- Usar `eval`, o `sed` con texto del usuario como patrón.
- Poner `set -Eeuo pipefail` en `modulos/*.sh` (solo en `instalar.sh`, `tareas/*.sh` y `pruebas/*.sh`).
- Usar Bloc de notas (rompe el fin de línea). Puedes escribir código en Windows con VS Code u otro editor con fin de línea LF (`.gitattributes` lo normaliza), pero siempre se prueba en la VM con AlmaLinux.
- Mandar pedazos de código por chat: se entrega el archivo completo por pull request.

## 4. Cómo escribir un módulo

Parte de [plantilla_modulo.sh](plantilla_modulo.sh) (cópiala a `modulos/<tu-modulo>.sh`).

1. El archivo **solo define funciones**; no ejecuta nada al cargarse. `menu.sh` ya carga
   `lib/comunes.sh` antes que tu módulo.
2. Función de entrada `menu_<modulo>`; al volver, hace `return`.
3. Todas las funciones con prefijo del módulo: `gestion_`, `respaldo_`, `tareas_`, `seguridad_`.
4. Variables dentro de funciones siempre con `local`.
5. Pantallas solo con `ui_*`. Separa la **lógica** (recibe parámetros, no pregunta nada) de la
   **pantalla** (pregunta y llama a la lógica); así se puede probar.
6. Éxito -> `registrar <modulo> "mensaje"`. En `tareas/*.sh` y `instalar.sh` las fallas van como
   `registrar <modulo> "ERROR: ..."`. Nunca registres éxito de algo que falló.
7. Revisa el código de salida de cada comando que cambia el sistema.
8. Valida antes de actuar (`validar_*`). CSV: `awk` por campo exacto, sin comas ni saltos de línea.
9. Comentarios: cada archivo abre con encabezado (nombre, qué es, `Requiere: lib/comunes.sh cargado antes`)
   y cada función lleva su bloque con nombre, qué hace, `Recibe:` y `Regresa:`. Mira la plantilla.
10. Pruebas en `pruebas/probar_<modulo>.sh` con `verificar`, `esperar_falla` y `resumen` (ver el final de la plantilla).

**Funciones de `lib/comunes.sh` que puedes usar:** `ui_menu`, `ui_pedir`, `ui_password`, `ui_confirmar`,
`ui_mensaje`, `ui_pausa`, `ui_error`, `ui_tabla_csv`, `ui_archivo`, `ui_comando`, `registrar`, `validar_campo`,
`validar_usuario`, `validar_telefono`, `validar_correo`, `validar_monto`, `csv_asegurar`, `csv_agregar`,
`csv_existe`, `csv_quitar`, `csv_actualizar`, `requiere`, `abrir_como_usuario`.
Variables: `$CSV_USUARIOS`, `$CSV_GRUPOS`, `$CSV_PAGOS`, `$CSV_RESPALDOS`, `$DATOS_DIR`, `$RESPALDOS_DIR`,
`$LOG_FILE`, `$SRV_DIR`, `$CRON_FIJAS`, `$CRON_USUARIO`.

**Entre módulos solo existen estas funciones** (no uses otras):
`respaldo_crear <origen> <gz|bz2>`, `respaldo_eliminar <archivo>` (Respaldo, las usa Tareas) y
`gestion_crear_grupo <grupo> <descripcion>` (Gestión, la usa `instalar.sh`). Lo demás se comunica por los CSV.

## 5. Antes de abrir el pull request

- [ ] `bash -n modulos/<tu-modulo>.sh` sin errores (y `shellcheck -S warning` si lo tienes).
- [ ] `sudo ./pruebas/correr_todas.sh` pasa completo, no solo lo tuyo.
- [ ] Hiciste la lista "Cómo probarlo a mano" de tu instrucción (con las capturas que pide).
- [ ] Cada función tiene su bloque de comentario.
- [ ] `git status` muestra **solo** los archivos de tu fila (si sale `lib/comunes.sh`, `menu.sh` o `instalar.sh`, deshaz ese cambio).

## 6. Si usas una herramienta de IA

**Reglas para la IA (léeselas):**

- Trabaja solo en los archivos del integrante (tabla de la sección 1).
- Lee primero su instrucción en `equipo/` y su spec en `docs/specs/0001-sistema-abarrotes/`.
- No modifiques `lib/comunes.sh`, `menu.sh`, `instalar.sh` ni los specs. Si hace falta algo ahí, dilo para pedírselo a Erick.
- No ejecutes `git push` ni `git merge`, ni toques `dev` o `main`. El humano hace commit en su rama y abre el PR.
- No inventes funciones de otros módulos: usa solo las del contrato (sección 4).
- Sigue la plantilla y el estándar de comentarios.
- El código es para AlmaLinux 9: pruébalo ahí, no en Windows.

**Prompt para pegar:**

```text
Eres mi asistente en un proyecto Bash para AlmaLinux 9. Soy <tu-nombre> y mi módulo es <tu-módulo>.
Antes de hacer nada, lee equipo/COMO-TRABAJAR.md, mi instrucción en equipo/ y mi spec en
docs/specs/0001-sistema-abarrotes/. Trabaja solo en mis archivos (los de mi fila en la tabla).
No modifiques lib/comunes.sh, menu.sh, instalar.sh ni los specs; si necesitas algo ahí, dímelo y
se lo pido a Erick. No ejecutes git push ni git merge ni toques dev o main. Usa solo las funciones
de lib/comunes.sh y las del contrato entre módulos; no inventes otras. Sigue
equipo/plantilla_modulo.sh y su estándar de comentarios. Al terminar, dime qué archivos cambiaste.
```

## 7. Problemas comunes

| Síntoma | Causa | Solución |
|---|---|---|
| `bad interpreter` o `\r: orden no encontrada` | Fin de línea de Windows (CRLF) | `sed -i 's/\r$//' archivo.sh` |
| `Permission denied` al correr un `.sh` nuevo | Se creó desde Windows sin permiso de ejecución | `git update-index --chmod=+x <archivo>` |
| "Debe ejecutarse con sudo" | El menú y las pruebas necesitan root | Corre `sudo ./menu.sh` o `sudo ./pruebas/correr_todas.sh` |
| Mi función "desapareció" o hace otra cosa | Otro módulo usa el mismo nombre | Revisa que tu función empiece con el prefijo de tu módulo |
| `git status` muestra archivos que no son tuyos | Cambio accidental | Deshazlo o no los agregues; nunca `git add .` |
