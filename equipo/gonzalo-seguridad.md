# Gonzalo: Seguridad

**Archivo:** `modulos/seguridad.sh` · **Rama:** `gonzalo/seguridad`

Antes lee [GUIA.md](GUIA.md): explica el proyecto, cómo preparar la VM y cómo subir tu trabajo.
Requisitos del proyecto: [docs/requisitos.md](../docs/requisitos.md).

## Qué vas a construir

La opción **Seguridad** del menú: al elegirla aparece una **segunda pantalla** (submenú) para abrir
herramientas de red. No programas las herramientas; tu menú solo las arranca.
`sudo ./instalar.sh` ya las instala.

| Herramienta | Para qué sirve | Qué debe hacer tu menú |
|---|---|---|
| **Nagios** | Vigila si equipos y servicios están funcionando; se ve en una página web | Abrir el **navegador** en su página, automáticamente |
| **Wireshark** | Muestra los paquetes que pasan por la red | Abrir **su ventana**, automáticamente |
| **nmap** (extra) | Escanea la red: equipos, puertos, versiones | Ofrecer 5 escaneos |

```
SEGURIDAD
├── Nagios
├── Wireshark
└── nmap (extra) → 5 opciones
```

(Cacti, la otra herramienta opcional del profesor, no se hace.)

## Obligatorio, paso a paso

Parte de [plantilla_modulo.sh](plantilla_modulo.sh).

### 1. Submenú
`menu_seguridad` con un `ui_menu` dentro de un `while`, como en la plantilla.

### 2. Nagios
1. Arranca sus servicios (`httpd` es el servidor web, `php-fpm` procesa sus páginas):
   `systemctl start httpd php-fpm nagios`. Si falla, `ui_error` y termina.
2. Abre el navegador: `abrir_como_usuario xdg-open http://localhost/nagios`.
   Si regresa error (no hay escritorio), muestra la dirección con `ui_mensaje`.
3. La página pide usuario `nagiosadmin` y la contraseña que escribiste al correr `instalar.sh`.
4. `registrar seguridad "Nagios abierto"`.

### 3. Wireshark
`requiere wireshark wireshark || return 0`, luego `abrir_como_usuario wireshark`. Si regresa error,
avisa que se necesita el escritorio. Registra en la bitácora. Para capturar, en la ventana se hace
doble clic en la tarjeta de red.

## Extra (solo si sobra tiempo): nmap

Pide la IP o red (tu red la ves con `ip -4 addr`, ej. `192.168.1.0/24`; para probar usa `localhost`),
valídala y muestra el resultado con `ui_comando nmap <opción> "$objetivo"`.

| Opción del menú | Parámetro |
|---|---|
| Equipos conectados | `-sn` |
| Puertos abiertos | `--open` |
| Versiones de servicios | `-sV` |
| Sistema operativo | `-O` |
| Completo (tarda más) | `-A` |

## No olvides

- Abre ventanas siempre con `abrir_como_usuario`: el menú corre con `sudo` y las ventanas de root
  no se muestran en el escritorio.
- Antes de usar nmap, acepta solo letras, números, puntos, `/` y `-`, sin empezar con `-`:
  `[[ "$objetivo" =~ ^[A-Za-z0-9][A-Za-z0-9./-]*$ ]]`
- Escanea solo tu red o la del laboratorio.

## Terminaste cuando

1. Probando desde el **escritorio** de la VM (no por SSH), la opción Nagios abre el navegador y puedes
   entrar.
2. La opción Wireshark abre su ventana.
3. (Extra) Las 5 opciones de nmap muestran resultado con `localhost`, y `hola;rm` se rechaza.

Si una ventana no abre, revisa `logs/gui.log`. Si Nagios muestra error, revisa
`systemctl status httpd php-fpm nagios`.

Guarda capturas de cada opción para el reporte.
