# Beto: Gestión (usuarios, grupos y procesos)

**Archivo:** `modulos/gestion.sh` · **Rama:** `beto/gestion`

Antes lee [GUIA.md](GUIA.md): explica el proyecto, cómo preparar la VM y cómo subir tu trabajo.
Requisitos del proyecto: [docs/requisitos.md](../docs/requisitos.md).

## Qué vas a construir

La opción **Gestión** del menú. Con ella se administran las cuentas de Linux de las personas de la
tienda y sus grupos, y se ven los procesos. Un **usuario** es una cuenta del sistema; un **grupo** es un conjunto de usuarios
(sirve para dar permisos a todos de una vez).

Cada usuario tiene un rol, y cada rol es un grupo:

| Rol | Grupo | Qué datos pides además del nombre |
|---|---|---|
| comprador | `compradores` | nada más |
| proveedor | `proveedores` | empresa y monto de pago semanal |
| empleado | `empleados` | nada más |

Linux no guarda empresa ni monto, por eso además lo anotas en un CSV (archivo de texto donde cada
línea es un registro y las columnas van separadas por comas).

Así se ve tu menú (puedes usar submenús o una sola lista):

```
GESTIÓN
├── Usuarios: agregar · borrar · consultar
├── Grupos:   agregar · borrar · consultar
└── Procesos: por usuario activo · del sistema
```

Ya existe un `modulos/gestion.sh` con una versión anterior. **Reemplázalo completo**, partiendo de
[plantilla_modulo.sh](plantilla_modulo.sh). El código viejo sirve para ver ideas, pero no usa las
funciones `ui_*`.

## Obligatorio, paso a paso

### 1. Agregar usuario
1. Pide el nombre con `ui_pedir` y revísalo con `validar_usuario` (minúsculas, números, `_`, `-`).
2. Si ya existe (`id "$usuario"` funciona), avisa con `ui_error` y termina.
3. Pide el rol con `ui_menu`. Si es proveedor, pide empresa (`validar_campo`) y monto
   (`validar_monto`). Pide todo **antes** de crear la cuenta.
4. Asegura que el grupo del rol exista (usa tu función del punto 4).
5. Crea la cuenta: `useradd -m -G <grupo> <usuario>` (`-m` crea su carpeta en `/home`,
   `-G` lo mete al grupo).
6. Ponle contraseña: `passwd <usuario>` (Linux la pide dos veces; tú no la guardas en ningún lado).
7. Guarda la fila en `$CSV_USUARIOS`. Son **6 columnas en este orden**:
   `usuario,rol,telefono,correo,empresa,monto`. Lo que no pidas va como `N/A`
   (teléfono y correo puedes dejarlos en `N/A`).

   ```bash
   csv_agregar "$CSV_USUARIOS" "$usuario" "$rol" "N/A" "N/A" "$empresa" "$monto"
   ```
   Brian lee `rol`, `empresa` y `monto` para pagar a los proveedores: si cambias el orden, le
   rompes su parte.
8. Anótalo: `registrar gestion "Usuario agregado: $usuario ($rol)"`.

### 2. Borrar usuario
Pide el nombre → revisa que se pueda borrar (ver "No olvides") → `ui_confirmar` →
`userdel -r <usuario>` (`-r` borra también su carpeta) → solo si funcionó,
`csv_quitar "$CSV_USUARIOS" 1 "$usuario"` y `registrar`.

### 3. Consultar usuarios
`ui_tabla_csv "$CSV_USUARIOS"` muestra la tabla.

### 4. Agregar grupo
Haz la función `gestion_crear_grupo <grupo> <descripcion>`. **No pregunta nada**: recibe los datos.
Tu pantalla los pide y la llama. El nombre debe ser exacto porque `instalar.sh` la usa para crear
los 3 grupos de rol.

- Si el grupo no existe (`getent group "$grupo"` falla), créalo con `groupadd`.
- Si no está en el CSV (`csv_existe "$CSV_GRUPOS" 1 "$grupo"` falla), agrega
  `grupo,descripcion,fecha` (la fecha con `date +%F`).
- Si ya existía todo, **debe terminar bien** (`return 0`), sin error ni filas repetidas.
- No uses `ui_*` dentro de esta función.

### 5. Borrar grupo
Pide el nombre → revisa que esté en `$CSV_GRUPOS` → confirma → `groupdel <grupo>` → si funcionó,
quítalo del CSV y `registrar`.

### 6. Consultar grupos
Muestra cada grupo de `$CSV_GRUPOS` con sus miembros. `getent group <grupo>` imprime
`nombre:x:número:miembro1,miembro2`.

### 7. Mostrar procesos
Un **proceso** es un programa que se está ejecutando. Son dos opciones (solo consultan, no cambian
nada):

- **Por usuario activo:** primero muestra quién tiene sesión abierta (`who`), pide el nombre con
  `ui_pedir`, revisa que exista (`id "$usuario"`) y muestra sus procesos:
  `ps -u "$usuario" -o user,pid,%cpu,%mem,etime,cmd`.
- **Del sistema:** todos los procesos con `ps -ef`.

La lista es larga; para poder desplazarte, guárdala en un temporal y muéstrala (`q` para salir):

```bash
temporal=$(mktemp)
ps -ef > "$temporal"
ui_archivo "$temporal"
rm -f "$temporal"
```

## No olvides (evita dañar tu sistema)

- Solo borra usuarios y grupos que estén en tus CSV. Nunca `root` ni `$SUDO_USER` (tu cuenta).
- No borres los 3 grupos de rol.
- Pide confirmación antes de borrar.
- Si `useradd`, `userdel`, `groupadd` o `groupdel` fallan, no cambies el CSV.

## Terminaste cuando

1. Creas un usuario de cada rol; aparecen en la tabla y en `getent group <grupo>`.
2. Creas un grupo, lo consultas y lo borras.
3. Borras un usuario: `id <usuario>` ya no lo encuentra y no está en el CSV.
4. Intentar borrar `root` muestra un error y no pasa nada.
5. `sudo ./instalar.sh` corre **dos veces** sin errores y existen los 3 grupos de rol.
6. "Procesos por usuario activo" muestra los de tu usuario, y un nombre que no existe da error.
7. "Procesos del sistema" muestra la lista completa y puedes volver al menú.

Guarda capturas de cada opción para el reporte.
