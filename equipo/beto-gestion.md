# Beto: Gestión (usuarios y grupos)

**Archivo:** `modulos/gestion.sh` · **Rama:** `beto/gestion`

## Obligatorio

- [ ] **Agregar usuario**: pide nombre y rol (comprador, proveedor o empleado). Si es proveedor,
      también empresa y monto. Usa `useradd -m -G <grupo> <usuario>` y `passwd <usuario>`.
      Grupos: `compradores`, `proveedores`, `empleados`.
      Guarda en `$CSV_USUARIOS` las 6 columnas `usuario,rol,telefono,correo,empresa,monto`;
      lo que no pidas va como `N/A`. (Brian usa `rol`, `empresa` y `monto` para los pagos.)
- [ ] **Borrar usuario**: `userdel -r` y quítalo del CSV.
- [ ] **Consultar usuarios**: `ui_tabla_csv "$CSV_USUARIOS"`.
- [ ] **Agregar grupo**: función `gestion_crear_grupo <grupo> <descripcion>`. El instalador la usa:
      si el grupo ya existe **no debe fallar** ni repetirlo. Guarda en `$CSV_GRUPOS`:
      `grupo,descripcion,fecha`.
- [ ] **Borrar grupo**: `groupdel` y quítalo del CSV.
- [ ] **Consultar grupos**: nombre y miembros (`getent group <grupo>`).

## No olvides (evita dañar tu sistema)

- Solo borra usuarios y grupos que estén en tus CSV. Nunca `root` ni `$SUDO_USER` (tu cuenta).
- No borres los 3 grupos de rol.
- Pide confirmación antes de borrar.

## Pruébalo

Crea un usuario de cada rol y un grupo, consúltalos y bórralos. Intenta borrar `root`.
Después corre `sudo ./instalar.sh`: debe crear los 3 grupos sin errores.
