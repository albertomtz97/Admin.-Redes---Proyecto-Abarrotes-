# Guía del equipo

Tu trabajo: **programar tu módulo, que funcione y subirlo a tu rama.** Erick une todo.

## Dónde encontrar cada cosa

| Quiero saber... | Abre |
|---|---|
| Qué pide el profesor y qué es obligatorio | [docs/requisitos.md](../docs/requisitos.md) |
| Cómo crear la VM, qué descargar e instalar | [docs/guia-maquina-virtual.md](../docs/guia-maquina-virtual.md) |
| Qué tengo que programar, paso a paso | Tu instrucción: [Beto](beto-gestion.md) · [Brian](brian-tareas.md) · [Diego](diego-respaldo.md) · [Gonzalo](gonzalo-seguridad.md) |
| Con qué archivo empiezo | [plantilla_modulo.sh](plantilla_modulo.sh) (ejemplo de módulo comentado) |
| Qué funciones ya existen | "Funciones que ya existen" (abajo); su explicación completa está en los comentarios de [lib/comunes.sh](../lib/comunes.sh) |
| Cómo probar y subir mi trabajo | "Probar y subir" (abajo) |
| Diseño detallado (solo consulta, trae más de lo obligatorio) | [docs/specs/](../docs/specs/0001-sistema-abarrotes/index.md) |
| Algo falla | "Problemas comunes" (abajo y en la guía de la VM) |

**Orden sugerido:** requisitos → guía de la VM → esta guía → tu instrucción.

## El proyecto en un minuto

Materia **Administración de Redes**: un sistema para una **tienda de abarrotes** en **AlmaLinux**.
Es un menú de terminal escrito en Bash, con 4 opciones. Cada quien programa una:

| Opción del menú | Qué hace | Quién |
|---|---|---|
| Actividades de gestión | Usuarios y grupos (alta, baja, consulta) y mostrar procesos | Beto |
| Automatización de tareas | cron y at: ejemplos y tareas nuevas con fecha | Brian |
| Respaldo | tar + gzip, tar + bzip2 y rsync, preguntando carpeta y destino | Diego |
| Seguridad → Monitoreo | Nagios, Wireshark y nmap | Gonzalo |

El menú, el instalador y las funciones comunes **ya están hechos**:

```
menu.sh            menú principal; carga tu módulo si existe
instalar.sh        instala paquetes y prepara carpetas y datos
lib/comunes.sh     funciones compartidas (pantallas, CSV, bitácora)
modulos/           aquí va tu archivo
datos/             CSV con la información (se crea al instalar; no se sube a git)
logs/bitacora.log  historial de lo que se hizo
```

Cuando en el menú eliges tu opción, se llama tu función `menu_<modulo>`. Mientras tu archivo no
exista, el menú dice "Módulo no disponible todavía".

## 1. Preparar (una vez)

Sigue [docs/guia-maquina-virtual.md](../docs/guia-maquina-virtual.md): crear la VM, conectar GitHub,
descargar el proyecto en tu rama y correr `sudo ./instalar.sh`.

Para traer cambios nuevos del equipo a tu rama:

```bash
git fetch
git merge origin/dev
```

## 2. Programar

Copia [plantilla_modulo.sh](plantilla_modulo.sh) a `modulos/<tu-modulo>.sh` y cambia `ejemplo`
por tu módulo. Beto: reemplaza todo el `modulos/gestion.sh` que ya existe.

Solo 5 reglas:

1. **Toca solo tus archivos** (vienen en tu instrucción). Si necesitas otro cambio, pídelo a Erick.
2. Tu menú se llama `menu_<modulo>` y **todas** tus funciones empiezan con `<modulo>_`.
   El archivo solo define funciones.
3. Usa las funciones `ui_*` para pantallas (tabla de abajo) y `local` en las variables.
4. Si un comando falla, avisa con `ui_error` y no guardes nada como si hubiera funcionado.
5. Programa dentro de la VM (el Bloc de notas de Windows rompe los archivos).

## 3. Probar y subir

```bash
bash -n modulos/<tu-modulo>.sh      # busca errores de escritura
sudo ./menu.sh                      # prueba cada opción
git add <tus archivos>              # nunca "git add ."
git commit -m "<modulo>: qué hiciste"
git push -u origin <tu-rama>
```

Cuando termines, avísale a Erick. Guarda capturas de cada opción funcionando para el reporte.

## Funciones que ya existen

Ya están en `lib/comunes.sh`: úsalas, no las copies ni las edites. Las que piden datos "regresan
error" si se cancela (escribiendo `q`, o `0` en un menú); por eso llevan `|| return 0`, que significa
"si canceló, regresa".

Variables listas: `$DATOS_DIR`, `$RESPALDOS_DIR`, `$BASE_DIR` (carpeta del proyecto), `$CSV_USUARIOS`,
`$CSV_GRUPOS`, `$CSV_PAGOS`, `$CRON_FIJAS`, `$CRON_USUARIO`.

| Función | Ejemplo |
|---|---|
| Menú | `op=$(ui_menu "TÍTULO" crear "Crear" ver "Ver") \|\| return 0` |
| Pedir dato / contraseña | `x=$(ui_pedir "Nombre") \|\| return 0` · `ui_password "Contraseña"` |
| Sí o no | `ui_confirmar "¿Borrar?" \|\| return 0` |
| Avisos | `ui_mensaje "Listo"` · `ui_error "Falló"` |
| Mostrar | `ui_tabla_csv "$CSV_USUARIOS"` · `ui_archivo ruta` · `ui_comando atq` |
| Bitácora | `registrar <modulo> "qué pasó"` |
| Validar | `validar_usuario`, `validar_monto`, `validar_campo` (texto sin comas) |
| CSV | `csv_agregar archivo campo1 campo2` · `csv_existe archivo columna valor` · `csv_quitar archivo columna valor` |
| Otras | `requiere nmap nmap \|\| return 0` · `abrir_como_usuario firefox` |

No cambies las columnas de los CSV: otros módulos las usan.

## Si usas IA

Abre la herramienta dentro de la carpeta del proyecto. **Primero pide que te lo explique**:

> Soy <nombre>, mi módulo es <módulo>. Lee docs/requisitos.md, equipo/GUIA.md, mi instrucción en equipo/,
> equipo/plantilla_modulo.sh y lib/comunes.sh. Todavía no programes. Explícame en palabras simples
> qué tengo que hacer, qué significa cada comando y en qué orden conviene avanzar.

Cuando lo entiendas:

> Programemos solo lo que piden docs/requisitos.md y mi instrucción, una opción a la vez. Hazlo sencillo, es un proyecto escolar.
> Toca solo mis archivos. Después de cada opción dime cómo probarla en mi VM.

Si tu herramienta no puede leer el proyecto (un chat en el navegador), copia y pega el contenido de
esos 5 archivos. Debes poder explicar tu código: si algo no lo entiendes, pregúntalo.

## Problemas comunes

- `\r: orden no encontrada`: `sed -i 's/\r$//' archivo.sh`
- `Permission denied`: `chmod +x archivo.sh`
- El menú pide root: usa `sudo ./menu.sh`
