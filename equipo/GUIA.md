# Guía del equipo

Tu trabajo: **programar tu módulo, que funcione y subirlo a tu rama.** Erick une todo.

## 1. Preparar (una vez)

1. Instala AlmaLinux 9 en una máquina virtual: 4 GB de RAM, 2 CPU, 30 GB. Elige
   **Server with GUI**, partición automática y crea tu usuario como **administrador**.
2. En la terminal:

```bash
sudo dnf install -y git 'dnf-command(config-manager)'
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install -y gh
gh auth login          # GitHub.com, HTTPS, con navegador
git config --global user.name  "Tu Nombre"
git config --global user.email "tu-correo-de-github"
git clone https://github.com/albertomtz97/Admin.-Redes---Proyecto-Abarrotes-.git proyecto
cd proyecto
git switch <tu-rama>   # Beto, la primera vez: git switch -c beto/gestion origin/dev
git merge origin/dev   # trae las instrucciones actuales
sudo ./instalar.sh
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

Pégale esto:

> Soy <nombre>, mi módulo es <módulo>. Lee equipo/GUIA.md y mi instrucción en equipo/. Hazlo
> sencillo, es un proyecto escolar. Primero lo obligatorio. Toca solo mis archivos.

## Problemas comunes

- `\r: orden no encontrada`: `sed -i 's/\r$//' archivo.sh`
- `Permission denied`: `chmod +x archivo.sh`
- El menú pide root: usa `sudo ./menu.sh`
