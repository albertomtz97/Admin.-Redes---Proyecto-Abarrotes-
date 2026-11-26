# 0001. Razonamiento: sistema de administración para la tienda de abarrotes

> **Documento de consulta.** Es el diseño detallado e incluye funciones que **no son obligatorias**.
> Lo que hay que entregar está en [requisitos](../../requisitos.md) y en tu instrucción de
> [equipo/](../../../equipo/GUIA.md); si algo no coincide, mandan esos.

## Context

> ⚠️ Premise note: el tema abarca 5 decisiones que se construyen por separado (base y 4 módulos).
> Por eso este spec es un paraguas con un hijo por módulo, más la interfaz gráfica, que queda
> pendiente para un spec propio. Otra nota: los compradores tienen cuenta de Linux. En una tienda
> real los clientes no tendrían cuenta en el servidor; aquí se lee "comprador" como personal de
> compras. Es una simplificación válida para la materia, solo tenlo presente al explicarlo.

Es el proyecto final de Administración de Redes. Plataforma obligatoria AlmaLinux. El profesor pide
un menú con Gestión (usuarios y grupos), Tareas (cron y at, con tareas ya programadas y la opción de
programar nuevas), Respaldo (tar gzip y bzip2 obligatorios; rsync o dump/restore opcionales) y
Seguridad (Nagios y Wireshark obligatorios abriendo su ventana; Cacti y nmap opcionales).

Fuerzas que pesan:
- Hoy existe un menú en Bash con Gestión a medias (rama `dev`), con errores conocidos: permite borrar
  cualquier cuenta, registra "creado" aunque `passwd` falle, el CSV se rompe con comas.
- El trabajo lo hará principalmente una persona con ayuda de un agente, pero quizá se reparta después.
  Hace falta orden: módulos funcionales, probados, sin código roto entre entregas.
- El ingeniero quiere todo funcionando en terminal antes de pensar en interfaz, y aún no conoce las
  opciones de interfaz para Linux.
- El código se evalúa leyendo: cada función debe decir qué hace.
- Todo corre como root, y algunas partes abren ventanas gráficas (navegador, Wireshark).

## Options considered

### Option 1: Monolito modular en Bash, terminal primero con capa `ui_*`

Un `menu.sh` que carga una librería común y un archivo por módulo. Las pantallas pasan por
funciones `ui_*` que hoy usan texto y mañana pueden usar zenity o dialog.

**Pros**:
- Reutiliza lo que ya existe; Bash es lo que evalúa la materia.
- La interfaz se decide al final sin reescribir módulos.
- Lógica separada de pantallas: se puede probar con scripts.

**Cons**:
- Más disciplina: prefijos, `local`, separar lógica de pantalla.
- Bash es frágil con texto (comillas, comas); obliga a validar todo.

### Option 2: Bash con dialog desde el inicio

Mismo monolito, pero cada pantalla se escribe directo con `dialog`.

**Pros**:
- Se ve terminado desde el primer módulo.

**Cons**:
- Va contra lo que pidió el ingeniero (terminal primero, interfaz al final).
- Cambiar de interfaz después obliga a reescribir cada pantalla.

### Option 3: Panel web (por ejemplo Python con Flask) que ejecuta comandos

Una página web local con botones que llaman `useradd`, `tar`, `crontab`.

**Pros**:
- Interfaz familiar para quien viene de web.

**Cons**:
- Un servidor web ejecutando comandos como root es un hueco de seguridad que el profesor señalaría.
- Muchas horas en web que no suman a la materia; el centro dejaría de ser la administración de Linux.

### Option 4: Programa en Python de terminal

Un CLI en Python que llama comandos del sistema con `subprocess`.

**Pros**:
- Manejo de datos y errores más robusto que Bash.

**Cons**:
- Tira el código Bash existente y se aleja de lo que se espera ver (scripts de shell).

## Rationale

Gana la opción 1 porque es la única que respeta las dos condiciones del ingeniero a la vez: todo
funcional en terminal primero y la interfaz decidida al final. La capa `ui_*` convierte la decisión
de interfaz en un cambio de un solo archivo, así que posponerla no cuesta retrabajo. Bash mantiene
el proyecto en lo que la materia evalúa y reutiliza el código y la experiencia que ya tienen.

Se eligió CSV sobre SQLite porque el volumen es de decenas de filas y ya lo usan; el riesgo de
escrituras simultáneas se acepta y queda anotado. Cacti se descartó por costo (MariaDB, PHP,
poller) contra la regla del ingeniero de agregar opcionales solo si son fáciles; xfsdump entró
porque son dos funciones y `/boot` ya es XFS en AlmaLinux (el dump clásico solo sirve en ext4).
Nagios va por EPEL y no compilado porque instala en minutos con menos puntos de falla.

Decisiones tomadas por el arquitecto (sin pregunta, con su alternativa):
- **Contraseña con `ui_password` + `chpasswd`** en vez de llamar `passwd` directo: `passwd` es
  interactivo y no funcionaría dentro de una interfaz gráfica en la fase 2. Se valida mínimo 8
  caracteres y que coincidan, y luego `chage -d 0` fuerza el cambio. Alternativa: `passwd` directo
  (más simple hoy, pero se reescribe en la fase 2).
- **Dos archivos cron** (`abarrotes` fijas y `abarrotes_usuario`) en vez de uno: `instalar.sh`
  regenera las fijas y así nunca borra las tareas que creaste desde el menú. Alternativa: un archivo
  con secciones (riesgo de perder tareas al reinstalar).
- **Carpeta de un grupo borrado se archiva**, no se elimina: se mueve a `/srv/abarrotes/_archivados/`
  para no perder archivos. Alternativa: borrarla (más limpio, riesgo de pérdida).
- **Respaldos con rutas relativas** (`tar -C <padre>`): permite restaurar igual en `/tmp` o en el
  lugar original. Alternativa: rutas absolutas (restaurar en otro lugar se complica).
- **tar con código 1 cuenta como éxito con aviso**: significa "un archivo cambió mientras se leía",
  normal en `/etc`. Solo 2 o más es error.
- **Pago semanal no se duplica**: si ya hay un pago semanal del mismo proveedor ese día, se salta.
  Evita pagar doble si la tarea corre dos veces.
- **Pruebas con datos falsos**: las pruebas cambian `DATOS_DIR` y `LOG_FILE` a una carpeta temporal,
  así nunca tocan tus datos reales.
- **Orden por módulos completos** (no hay un enfoque de construcción registrado en el proyecto): cada
  módulo se termina y prueba antes del siguiente, que es lo que pediste para no dejar código roto.
