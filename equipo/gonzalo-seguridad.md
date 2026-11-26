# Gonzalo: Seguridad

**Archivo:** `modulos/seguridad.sh` · **Rama:** `gonzalo/seguridad`

`sudo ./instalar.sh` ya instala Nagios, Wireshark y nmap.

## Obligatorio

- [ ] **Submenú** de Seguridad.
- [ ] **Nagios**: `systemctl start httpd php-fpm nagios` y
      `abrir_como_usuario xdg-open http://localhost/nagios` (usuario `nagiosadmin`).
- [ ] **Wireshark**: `abrir_como_usuario wireshark`

## Extra (solo si sobra tiempo)

- [ ] **nmap** con 5 opciones. Pide la IP o red y muestra el resultado con `ui_comando`:
      `-sn` (equipos), `--open` (puertos), `-sV` (versiones), `-O` (sistema operativo),
      `-A` (completo).

## No olvides

- Abre ventanas siempre con `abrir_como_usuario`.
- Antes de usar nmap, acepta solo letras, números, puntos, `/` y `-`, sin empezar con `-`:
  `[[ "$objetivo" =~ ^[A-Za-z0-9][A-Za-z0-9./-]*$ ]]`
- Escanea solo tu red o la del laboratorio.

## Pruébalo

Desde el escritorio (no por SSH): Nagios abre el navegador y Wireshark su ventana.
Si no abren, revisa `logs/gui.log`.
