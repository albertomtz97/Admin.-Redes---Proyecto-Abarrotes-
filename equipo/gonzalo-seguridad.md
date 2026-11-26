# Gonzalo: Seguridad

**Archivo:** `modulos/seguridad.sh` · **Rama:** `gonzalo/seguridad`

Antes lee [GUIA.md](GUIA.md): explica el proyecto, cómo preparar la VM y cómo subir tu trabajo.
Requisitos del proyecto: [docs/requisitos.md](../docs/requisitos.md).

## Qué vas a construir

La opción **Seguridad** del menú. Al elegirla aparece una **segunda pantalla** con **Monitoreo**, y
ahí el usuario elige entre **3 herramientas**. Las 3 son obligatorias, deben funcionar y mostrar el
monitoreo en tiempo real abriendo la aplicación o el navegador. No programas las herramientas; tu
menú las arranca. `sudo ./instalar.sh` ya las instala.

| Herramienta | Para qué sirve | Qué debe hacer tu menú |
|---|---|---|
| **Nagios** | Vigila si equipos y servicios están funcionando; se ve en una página web | Abrir el **navegador** en su página, automáticamente |
| **Wireshark** | Muestra en vivo los paquetes que pasan por la red | Abrir su ventana **ya capturando** |
| **nmap** | Escanea la red: equipos, puertos, versiones, sistema operativo | 5 opciones, mostrando el resultado y avance en la terminal |

```
SEGURIDAD
└── Monitoreo
    ├── Nagios
    ├── Wireshark
    └── nmap → 5 opciones
```

(El profesor permite iftop en lugar de nmap y también menciona Cacti; no los hacemos. Ver
[requisitos](../docs/requisitos.md).)

## Obligatorio, paso a paso

Parte de [plantilla_modulo.sh](plantilla_modulo.sh).

### 1. Submenús
`menu_seguridad` con un `ui_menu` dentro de un `while`, como en la plantilla. Su opción "Monitoreo"
llama a otra función (`seguridad_monitoreo`) con las 3 herramientas.

### 2. Nagios
1. Arranca sus servicios (`httpd` es el servidor web, `php-fpm` procesa sus páginas):
   `systemctl start httpd php-fpm nagios`. Si falla, `ui_error` y termina.
2. Abre el navegador: `abrir_como_usuario xdg-open http://localhost/nagios`.
   Si regresa error (no hay escritorio), muestra la dirección con `ui_mensaje`.
3. La página pide usuario `nagiosadmin` y la contraseña que escribiste al correr `instalar.sh`.
4. `registrar seguridad "Nagios abierto"`.

### 3. Wireshark capturando
`requiere wireshark wireshark || return 0`. Averigua tu tarjeta de red y ábrelo capturando
(`-i` interfaz, `-k` empezar ya):

```bash
interfaz=$(ip route show default | awk '{for (i=1; i<NF; i++) if ($i=="dev") {print $(i+1); exit}}')
abrir_como_usuario wireshark -i "$interfaz" -k
```

Si `$interfaz` queda vacía, avisa que no hay conexión de red. Si `abrir_como_usuario` regresa error,
avisa que se necesita el escritorio. Registra en la bitácora.

### 4. nmap
`requiere nmap nmap || return 0`. Pide la IP o red (tu red la ves con `ip -4 addr`, ej.
`192.168.1.0/24`; para probar usa `localhost`), valídala y muestra el resultado:
`ui_comando nmap --stats-every 5s <opción> "$objetivo"` (`--stats-every` muestra el avance cada
5 segundos).

| Opción del menú | Parámetro |
|---|---|
| Equipos conectados | `-sn` |
| Puertos abiertos | `--open` |
| Versiones de servicios | `-sV` |
| Sistema operativo | `-O` |
| Completo (tarda más) | `-A` |

Registra cada escaneo en la bitácora.

## No olvides

- Abre ventanas siempre con `abrir_como_usuario`: el menú corre con `sudo` y las ventanas de root
  no se muestran en el escritorio.
- Antes de usar nmap, acepta solo letras, números, puntos, `/` y `-`, sin empezar con `-`:
  `[[ "$objetivo" =~ ^[A-Za-z0-9][A-Za-z0-9./-]*$ ]]`
- Escanea solo tu red o la del laboratorio.

## Terminaste cuando

1. Probando desde el **escritorio** de la VM (no por SSH), la opción Nagios abre el navegador, puedes
   entrar y ves el estado de los servicios.
2. Wireshark abre y los paquetes van apareciendo sin que tengas que dar clic.
3. Las 5 opciones de nmap muestran resultado con `localhost`, y `hola;rm` se rechaza.

Si una ventana no abre, revisa `logs/gui.log`. Si Nagios muestra error, revisa
`systemctl status httpd php-fpm nagios`.

Guarda capturas de cada opción para el reporte.
