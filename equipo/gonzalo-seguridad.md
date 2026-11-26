# Gonzalo: módulo Seguridad (Nagios, Wireshark, nmap)

Detalle técnico completo: `docs/specs/0001-sistema-abarrotes/0006-seguridad.md`

## Qué vas a construir

Una segunda pantalla con tres herramientas:
- **Nagios**: arranca sus servicios si están apagados y abre el navegador en su página.
- **Wireshark**: abre su ventana ya capturando en la red principal.
- **nmap**: 5 escaneos sobre tu red o lo que escribas, guardando cada resultado.

`instalar.sh` ya instala todo (Nagios, Apache, php-fpm, Wireshark, nmap) y pone la contraseña de
Nagios. Tú solo programas el menú y su lógica.

## Archivos que entregas (solo estos)

- `modulos/seguridad.sh`
- `pruebas/probar_seguridad.sh`

## Menú

```
SEGURIDAD
1 Nagios (abre navegador) · 2 Wireshark (abre y captura) · 3 nmap · 4 Resultados de nmap anteriores
   └── nmap: 1 Equipos en la red · 2 Puertos abiertos · 3 Versiones · 4 Sistema operativo · 5 Completo
```

## Lista de tareas

- [ ] **Nagios**: `requiere nagios nagios`. Si `httpd`, `php-fpm` o `nagios` no están activos
      (`systemctl is-active`), arráncalos (`systemctl start`) y regístralo. Luego
      `abrir_como_usuario xdg-open http://localhost/nagios` (si falla, prueba con `firefox`).
      Sin escritorio (por SSH), muestra la URL y el usuario `nagiosadmin`.
- [ ] **Wireshark**: `requiere wireshark wireshark`. La interfaz de red sale de
      `ip route show default` (la palabra después de `dev`). Si no hay ruta, "No hay conexión de red activa".
      Si `$SUDO_USER` no está en el grupo `wireshark`, agrégalo (`usermod -aG wireshark`). Abre con
      `abrir_como_usuario wireshark -i <interfaz> -k`.
- [ ] **nmap**: propone tu red (`ip -o -4 addr show dev <interfaz>`, la dirección con `/24` o el prefijo
      que salga) o deja escribir otra. **Valida** antes de ejecutar: IP con cada número de 0 a 255 y
      prefijo opcional de 0 a 32, o un nombre de equipo. Lo demás se rechaza.
- [ ] Las 5 opciones:

  | # | Opción | Comando |
  |---|---|---|
  | 1 | Equipos en la red | `nmap -sn <objetivo>` |
  | 2 | Puertos abiertos | `nmap --open <objetivo>` |
  | 3 | Versiones de servicios | `nmap -sV <objetivo>` |
  | 4 | Sistema operativo | `nmap -O <objetivo>` |
  | 5 | Completo (tarda) | `nmap -A <objetivo>` |

- [ ] Cada escaneo se guarda con `-oN $DATOS_DIR/nmap/<AAAAMMDD_HHMMSS>_<opcion>.txt`, se muestra con
      `ui_archivo` y se registra: `registrar seguridad "nmap opción N a <objetivo>"`.
- [ ] **Resultados anteriores**: lista los archivos de `$DATOS_DIR/nmap/` y muestra el elegido.

## Cuidado con

- **Nunca abras ventanas como root.** Siempre con `abrir_como_usuario`: el menú corre con `sudo` y las
  ventanas de root no se ven en el escritorio.
- Si Wireshark o el navegador no abren, la causa queda en `logs/gui.log`.
- Si Nagios da error 503, revisa `systemctl status php-fpm`.
- Si SELinux bloquea algo de Nagios: `sudo ausearch -m avc -ts recent`.
- Solo escanea tu red o la del laboratorio.

## Cómo probarlo a mano

1. `sudo systemctl stop nagios`, entra al menú, elige Nagios: debe arrancarlo y abrir el navegador.
   **Captura para el reporte.**
2. Wireshark abre capturando y el menú sigue respondiendo. **Captura.**
3. Escribe como objetivo `hola;rm`: debe rechazarlo sin ejecutar nmap.
4. Las 5 opciones contra `localhost` y contra tu red. **Captura de cada una.**

## Pruebas automáticas (en `pruebas/probar_seguridad.sh`)

La validación de objetivos (IPs válidas, `300.1.1.1` inválida, `/33` inválido, textos raros
inválidos) y que cada opción del 1 al 5 dé las banderas correctas.
