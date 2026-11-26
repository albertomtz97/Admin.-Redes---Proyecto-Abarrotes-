# 0003. Gestión: usuarios y grupos

> **Documento de consulta.** Es el diseño detallado e incluye funciones que **no son obligatorias**.
> Lo que hay que entregar está en [requisitos](../../requisitos.md) y en tu instrucción de
> [equipo/](../../../equipo/GUIA.md); si algo no coincide, mandan esos.
>
> **Cambio por el enunciado oficial (2026-11-25), manda sobre el texto de abajo:** Se agrega **Mostrar procesos**: por usuario activo (`who`, `ps -u`) y del sistema (`ps -ef`).

## Summary

Administra las cuentas de la tienda con tres roles: comprador, proveedor y empleado. Cada rol es un
grupo de Linux con una carpeta compartida a la que solo entran sus miembros. Desde aquí se agregan,
eliminan, modifican y consultan usuarios, y se agregan, eliminan y consultan grupos. Solo se puede
borrar lo que creó el sistema, nunca cuentas del sistema ni la tuya.

Razón corta: reutiliza lo que ya hay en `dev` (roles, CSV) y corrige sus errores (borrado sin
límite, registro de éxito aunque falle, CSV roto por comas).

## Requirements

**User stories**:
- Como administrador, quiero dar de alta compradores, proveedores y empleados con sus datos, para que tengan cuenta y carpeta de su grupo.
- Como administrador, quiero crear grupos extra y meter o sacar usuarios, para controlar quién entra a qué carpeta.
- Como administrador, no quiero poder borrar por error `root`, mi cuenta ni cuentas del sistema.

**Acceptance criteria**:
- **AC-1**: Agregar usuario pide nombre, rol, teléfono y correo (y empresa y monto si es proveedor), contraseña dos veces. Al terminar, el usuario existe, pertenece al grupo de su rol, tiene `chage -d 0` (debe cambiar contraseña al entrar) y su fila está en `usuarios.csv` con 6 columnas (`N/A` en empresa y monto si no es proveedor).
- **AC-2**: Si cualquier paso falla después de `useradd` (contraseña, `chage`, CSV), el usuario se elimina (`userdel -r`), no queda fila en el CSV y no se registra éxito.
- **AC-3**: Datos inválidos (tabla de validación del 0002), contraseñas distintas o menores a 8 caracteres, usuario ya existente, o nombre igual a un grupo que ya existe (`getent group`), se rechazan antes de crear nada.
- **AC-4**: Eliminar usuario solo ofrece usuarios de `usuarios.csv`; rechaza `root`, `$SUDO_USER` y UID menor a 1000; pide confirmación; borra cuenta, home y fila del CSV. Si `userdel -r` falla (por ejemplo, el usuario tiene procesos abiertos), muestra el error y no toca el CSV.
- **AC-5**: Modificar usuario cambia teléfono y correo (y empresa y monto si es proveedor) en el CSV, validando igual que al agregar. El rol no se cambia.
- **AC-6**: Consultar usuarios muestra `usuarios.csv` en tabla; ver detalle muestra la fila, `id`, `chage -l` y último acceso.
- **AC-7**: Agregar grupo valida el nombre con `validar_usuario` (mismas reglas), crea el grupo, su fila en `grupos.csv` y `/srv/abarrotes/<grupo>` con `root:<grupo>` y `2770`. `gestion_crear_grupo` es idempotente: si algo ya existe, lo deja y completa lo que falte (así la usa `instalar.sh`).
- **AC-8**: Eliminar grupo solo ofrece grupos de `grupos.csv`; los 3 grupos de rol (`compradores`, `proveedores`, `empleados`) **nunca** se pueden borrar; rechaza cualquier grupo que sea grupo principal de alguien; mueve su carpeta a `/srv/abarrotes/_archivados/<grupo>_<fecha>` y borra grupo y fila.
- **AC-9**: Consultar grupos muestra los grupos de la tienda con sus miembros, y aparte permite ver todos los grupos del sistema o los grupos de un usuario.
- **AC-10**: Agregar o quitar usuario de grupo (`gpasswd -a` / `gpasswd -d`) solo acepta usuarios de `usuarios.csv` y grupos de `grupos.csv`; no permite quitar a alguien del grupo de su propio rol.
- **AC-11**: Cada cambio exitoso queda en la bitácora con módulo `gestion`.
- **AC-12**: `pruebas/probar_gestion.sh` pasa.

## Feature design

**Menú**:
```
GESTIÓN
├── 1 Usuarios: agregar · eliminar · modificar datos · consultar · ver detalle
└── 2 Grupos: agregar · eliminar · consultar · agregar usuario a grupo · quitar usuario de grupo
```

**Datos**:
- `usuarios.csv`: `usuario,rol,telefono,correo,empresa,monto` (clave: `usuario`).
- `grupos.csv`: `grupo,descripcion,fecha` (clave: `grupo`). Los 3 de rol se registran al instalar.
- Rol a grupo: comprador → `compradores`, proveedor → `proveedores`, empleado → `empleados`.

**Funciones de lógica** (sin pantallas, se prueban): `gestion_usuario_registrado <u>`,
`gestion_puede_borrar_usuario <u>`, `gestion_puede_borrar_grupo <g>`, `gestion_grupo_de_rol <rol>`,
`gestion_crear_usuario <u> <rol> <tel> <correo> <empresa> <monto> <pass>` (hace los pasos y el
deshacer de AC-2), `gestion_crear_grupo <g> <descripcion>` (idempotente),
`gestion_modificar_usuario <u> <campo> <valor>` (valida y usa `csv_actualizar`).

**Pasos de crear usuario**: validar todo → `getent group` o `gestion_crear_grupo` del rol → `useradd -m -G <grupo> -c <rol> <u>` →
`echo "<u>:<pass>" | chpasswd` → `chage -d 0 <u>` → `csv_agregar` → `registrar`. Si falla un paso
después de `useradd`: `userdel -r <u>` y regresa 1.

**Value sourcing**:
| Acción | Valor | Fuente |
|---|---|---|
| agregar usuario | grupo | derivado del rol (tabla de arriba) |
| agregar usuario | empresa, monto | entrada si es proveedor; `N/A` si no |
| agregar grupo | fecha | `date '+%F %T'` |
| eliminar grupo | fecha del archivado | `date '+%Y%m%d_%H%M%S'` |
| detalle | último acceso | `lastlog -u <u>` |

**Key invariants**:
- Ninguna cuenta con UID menor a 1000, `root` ni `$SUDO_USER` se borra desde el menú.
- Todo usuario del CSV existe en el sistema y viceversa para los creados por el menú.
- Un usuario siempre pertenece al grupo de su rol.
- Nada en `/srv/abarrotes` se borra; solo se archiva.

**Security model**: solo root (el menú entero exige sudo). La contraseña nunca se escribe en
bitácora, CSV ni pantalla, y se pasa a `chpasswd` por tubería, no como argumento.

**Critical test scenarios**:
- Happy path: crear un empleado y un proveedor, verificar grupo, carpeta, CSV y `chage -l`, verifica **AC-1**, **AC-7**.
- Falla: contraseñas distintas, nada se crea, verifica **AC-3**; forzar falla de `chage` (prueba automática con función simulada), el usuario no queda, verifica **AC-2**.
- Permiso: intentar borrar `root` y tu cuenta, rechazado, verifica **AC-4**.
- Grupo: borrar `proveedores` con miembros, rechazado; borrar un grupo extra, carpeta archivada, verifica **AC-8**.
- Manual con `su - <usuario>`: un empleado entra a `/srv/abarrotes/empleados` y no a `/srv/abarrotes/proveedores`, verifica **AC-7** (captura para el reporte).

## Build plan

1. Funciones de lógica y validación del módulo con comentarios, satisfies **AC-3**, **AC-4**, **AC-8**, **AC-10**.
2. `gestion_crear_usuario` con deshacer, satisfies **AC-1**, **AC-2**, **AC-11**.
3. `pruebas/probar_gestion.sh` (validaciones sin root; alta y baja de un usuario temporal con root), satisfies **AC-12**.
4. Pantallas de usuarios: agregar, eliminar, modificar, consultar, detalle, satisfies **AC-1**, **AC-4**, **AC-5**, **AC-6**.
5. Grupos: `gestion_crear_grupo`, eliminar con archivado, consultar, agregar y quitar miembros, satisfies **AC-7**, **AC-8**, **AC-9**, **AC-10**, **AC-11**.
6. Revisión manual en AlmaLinux y commit, satisfies **AC-1** a **AC-12**.

## Consequences

**Negative / tradeoffs**:
- Usuarios creados fuera del menú no se pueden borrar desde aquí (decisión de seguridad).
- Archivos que un usuario borrado dejó en `/srv/abarrotes/<grupo>` se quedan con un UID sin dueño; se acepta (siguen siendo del grupo por el bit `2770`).
- `chpasswd` no aplica todas las reglas de calidad de contraseña del sistema; el módulo valida solo largo mínimo.
