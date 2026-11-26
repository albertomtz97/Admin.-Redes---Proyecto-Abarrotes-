# 0006. Seguridad: Nagios, Wireshark y nmap

> **Documento de consulta.** Es el diseño detallado e incluye funciones que **no son obligatorias**.
> Lo que hay que entregar está en [requisitos](../../requisitos.md) y en tu instrucción de
> [equipo/](../../../equipo/GUIA.md); si algo no coincide, mandan esos.
>
> **Cambio por el enunciado oficial (2026-11-25), manda sobre el texto de abajo:** Seguridad tiene un submenú **Monitoreo** con 3 herramientas **obligatorias**: Nagios, Wireshark (capturando) y nmap, con resultado en tiempo real.

## Summary

Una segunda pantalla con tres herramientas. Nagios arranca sus servicios si hace falta y abre el
navegador en su panel. Wireshark abre su ventana ya capturando en tu interfaz de red principal. nmap
ofrece 5 escaneos sobre tu red o el objetivo que escribas, y guarda cada resultado.

Razón corta: Nagios y Wireshark son obligatorios; nmap es el opcional más útil para Redes. Cacti se
dejó fuera por costo. Como el menú corre como root, las ventanas se abren como tu usuario normal.

## Requirements

**User stories**:
- Como administrador, quiero abrir el monitoreo de Nagios con una opción, sin recordar comandos ni URL.
- Como administrador, quiero abrir Wireshark capturando de inmediato.
- Como administrador, quiero saber qué equipos, puertos, servicios y sistemas hay en mi red.

**Acceptance criteria**:
- **AC-1**: El menú de Seguridad es una segunda pantalla con: 1 Nagios, 2 Wireshark, 3 nmap, 4 Ver resultados de nmap anteriores.
- **AC-2**: Nagios: si falta el paquete, avisa (`requiere`); si `httpd`, `php-fpm` o `nagios` no están activos, los inicia y lo registra; luego abre `http://localhost/nagios` con `abrir_como_usuario xdg-open` (si `xdg-open` falla, prueba `firefox`). Sin sesión gráfica, muestra la URL y el usuario a usar (`nagiosadmin`).
- **AC-3**: Wireshark: si falta el paquete, avisa; detecta la interfaz de la ruta por defecto (`ip route show default`); si no hay ruta por defecto, dice "No hay conexión de red activa" y no abre. Si `$SUDO_USER` no está en el grupo `wireshark` (`id -nG`), lo agrega (no hace falta cerrar sesión porque `abrir_como_usuario` usa `runuser`). Abre `wireshark -i <interfaz> -k` como tu usuario, en segundo plano, y el menú sigue respondiendo. Sin sesión gráfica, explica que hay que usarlo desde el escritorio.
- **AC-4**: nmap pide objetivo proponiendo tu red actual (dirección y prefijo de la interfaz principal); si no hay ruta por defecto, no propone nada y pide escribirlo. Acepta: IPv4 con cada número de 0 a 255, opcionalmente con `/prefijo` de 0 a 32; o nombre de equipo `^[A-Za-z0-9]([A-Za-z0-9.-]{0,252})$`. Cualquier otra cosa se rechaza sin ejecutar nmap.
- **AC-5**: Las 5 opciones de nmap: 1 Descubrir equipos (`-sn`), 2 Puertos abiertos (`--open`), 3 Versiones de servicios (`-sV`), 4 Sistema operativo (`-O`), 5 Escaneo completo (`-A`, avisa que tarda).
- **AC-6**: Cada escaneo se guarda en `datos/nmap/<AAAAMMDD_HHMMSS>_<opcion>.txt` (`-oN`), se muestra al terminar y se registra en bitácora con módulo `seguridad` y el objetivo.
- **AC-7**: Ver resultados anteriores lista los archivos de `datos/nmap/` y muestra el elegido.
- **AC-8**: `pruebas/probar_seguridad.sh` pasa (validación de objetivos y armado del comando de cada opción).

## Feature design

**Menú**:
```
SEGURIDAD
1 Nagios (abre navegador) · 2 Wireshark (abre y captura) · 3 nmap · 4 Resultados de nmap
   └── nmap: 1 Equipos en la red · 2 Puertos abiertos · 3 Versiones · 4 Sistema operativo · 5 Completo
```

**Funciones de lógica** (se prueban): `seguridad_interfaz_principal`, `seguridad_red_local`,
`seguridad_validar_objetivo <obj>`, `seguridad_opciones_nmap <n>` (imprime las banderas de cada opción).

**Value sourcing**:
| Acción | Valor | Fuente |
|---|---|---|
| Nagios | URL | fija `http://localhost/nagios` |
| Nagios | navegador | `xdg-open` (paquete `xdg-utils`), si falla `firefox` |
| Nagios | credenciales | `nagiosadmin`, contraseña puesta en `instalar.sh` (no se guarda en git) |
| Wireshark | interfaz | campo `dev` de `ip route show default` |
| nmap | objetivo propuesto | `ip -o -4 addr show dev <interfaz>` (dirección/prefijo; nmap escanea toda la red) |
| nmap | nombre del resultado | `date '+%Y%m%d_%H%M%S'` + número de opción |

**Key invariants**:
- Ninguna ventana se abre como root; siempre vía `abrir_como_usuario`.
- nmap nunca se ejecuta con un objetivo que no pasó la validación.

**Security model**: solo root usa el menú. nmap solo debe usarse en tu red o la del laboratorio;
la pantalla de nmap lo recuerda. No se abre ningún puerto en el firewall: Nagios queda accesible
solo desde la misma máquina.

**Critical test scenarios**:
- Happy path: detener `nagios`, elegir Nagios; el servicio arranca y el navegador abre, verifica **AC-2** (captura para el reporte).
- Wireshark abre capturando y el menú sigue respondiendo, verifica **AC-3**.
- Falla: objetivo `hola mundo;rm` rechazado sin ejecutar nmap, verifica **AC-4**.
- Las 5 opciones contra `localhost` y contra la red del laboratorio, archivos guardados, verifica **AC-5**, **AC-6**.

## Build plan

1. Funciones de lógica (interfaz, red, validar objetivo, opciones nmap) con comentarios, satisfies **AC-4**, **AC-5**.
2. `pruebas/probar_seguridad.sh`, satisfies **AC-8**.
3. Pantallas nmap y resultados anteriores, satisfies **AC-1**, **AC-5**, **AC-6**, **AC-7**.
4. Nagios con arranque de servicios y navegador, satisfies **AC-2**.
5. Wireshark con captura automática, satisfies **AC-3**.
6. Revisión manual en AlmaLinux (escritorio y por SSH) y commit, satisfies **AC-1** a **AC-8**.

## Consequences

**Negative / tradeoffs**:
- SELinux puede bloquear partes de Nagios por defecto; si pasa, hay que revisar `ausearch -m avc` y ajustar (riesgo a validar en la máquina).
- Wireshark en AlmaLinux 9 usa Qt5, que en GNOME corre sobre X11 (Xwayland); por eso `abrir_como_usuario` le pasa `XAUTHORITY`. Si no abre, la causa queda en `logs/gui.log`.
- `abrir_como_usuario` depende de la sesión de GNOME; por SSH estas dos opciones solo muestran instrucciones.
