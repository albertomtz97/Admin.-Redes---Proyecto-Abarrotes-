# Beto: módulo Gestión (usuarios y grupos)

Detalle técnico completo: `docs/specs/0001-sistema-abarrotes/0003-gestion.md`

## Qué vas a construir

Desde el menú se administran las cuentas de la tienda. Hay 3 roles y cada rol es un grupo de Linux
con una carpeta compartida a la que solo entran sus miembros:

| Rol | Grupo | Datos que se piden |
|---|---|---|
| comprador | `compradores` | teléfono, correo |
| proveedor | `proveedores` | teléfono, correo, empresa, monto de pago semanal |
| empleado | `empleados` | teléfono, correo |

Ya existe un `modulos/gestion.sh` de transición (el código que hiciste antes, adaptado). **Lo vas a
reescribir completo** usando la plantilla.

## Archivos que entregas (solo estos)

- `modulos/gestion.sh`
- `pruebas/probar_gestion.sh`

## Menú

```
GESTIÓN
├── Usuarios: agregar · eliminar · modificar datos · consultar · ver detalle
└── Grupos:   agregar · eliminar · consultar · agregar usuario a grupo · quitar usuario de grupo
```

## Lista de tareas

- [ ] **Agregar usuario**: pide nombre, rol, teléfono, correo (y empresa y monto si es proveedor) y la
      contraseña dos veces (mínimo 8 caracteres, que coincidan). Pasos:
      `useradd -m -G <grupo> -c <rol> <usuario>` → `echo "<usuario>:<pass>" | chpasswd` →
      `chage -d 0 <usuario>` (obliga a cambiar la contraseña al entrar) → fila en `$CSV_USUARIOS`
      → `registrar gestion "..."`.
- [ ] **Si algo falla después de `useradd`**, borra el usuario (`userdel -r`) y no escribas en el CSV.
- [ ] El CSV siempre tiene 6 columnas: `usuario,rol,telefono,correo,empresa,monto`
      (`N/A` en empresa y monto si no es proveedor).
- [ ] **Eliminar usuario**: solo usuarios que estén en el CSV, nunca `root`, `$SUDO_USER`
      (tu propia cuenta) ni un UID menor a 1000, pide confirmación. Si `userdel -r` falla, muestra el error y no toques el CSV.
- [ ] **Modificar datos**: cambia teléfono y correo (y empresa y monto si es proveedor) con
      `csv_actualizar`. El rol no se cambia.
- [ ] **Consultar usuarios**: `ui_tabla_csv "$CSV_USUARIOS"`. **Ver detalle**: la fila del CSV,
      `id`, `chage -l` y `lastlog -u`.
- [ ] **`gestion_crear_grupo <grupo> <descripcion>`** (función muy importante: `instalar.sh` la usa
      para crear los 3 grupos de rol). Crea el grupo, su fila en `$CSV_GRUPOS` y la carpeta
      `$SRV_DIR/<grupo>` con dueño `root:<grupo>` y permisos `2770`. **Si algo ya existe, no falla**:
      solo completa lo que falte.
- [ ] **Eliminar grupo**: solo grupos de `$CSV_GRUPOS`; los 3 de rol **nunca** se borran; no borrar
      un grupo que sea el grupo principal de alguien. La carpeta **no se borra**: se mueve a
      `$SRV_DIR/_archivados/<grupo>_<fecha>`.
- [ ] **Consultar grupos**: los grupos de la tienda con sus miembros; aparte, todos los grupos del
      sistema o los grupos de un usuario.
- [ ] **Agregar / quitar usuario de grupo**: `gpasswd -a` / `gpasswd -d`. No se puede quitar a
      alguien del grupo de su propio rol.

## Cuidado con

- Valida todo antes de crear nada: `validar_usuario`, `validar_telefono`, `validar_correo`,
  `validar_monto`. Rechaza también un nombre de usuario que ya exista como grupo (`getent group`).
- La contraseña nunca va a la bitácora, al CSV ni a la pantalla.
- Usa `local` en todas las variables (el código viejo tenía un error: el correo de un proveedor se le
  quedaba al siguiente usuario).

## Cómo probarlo a mano

1. Crea un empleado y un proveedor. Revisa: `getent group empleados`, `ls -ld /srv/abarrotes/*`,
   `chage -l <usuario>` y el CSV.
2. Pon contraseñas distintas: no se debe crear nada.
3. Intenta borrar `root` y tu propia cuenta: debe rechazarlo.
4. Entra como el empleado (`su - <usuario>`): debe poder entrar a `/srv/abarrotes/empleados` y **no**
   a `/srv/abarrotes/proveedores`. **Toma captura para el reporte.**

## Pruebas automáticas (en `pruebas/probar_gestion.sh`)

Prueba las funciones de lógica: validaciones, que no deje borrar `root`, que `gestion_crear_grupo`
se pueda correr dos veces. Las que crean usuarios reales solo si `es_root` (con `sudo`).
