# Guía: preparar la máquina virtual

Se hace **una sola vez**. Al terminar tendrás AlmaLinux 9 con el proyecto instalado y conectado a
GitHub. Tiempo aproximado: 1 a 1.5 horas.

## 1. Descargar

- **VirtualBox** (gratis, también sirve VMware), desde su página oficial.
- El ISO de **AlmaLinux 9** (DVD), desde la página oficial de AlmaLinux.

## 2. Crear la máquina virtual

| Recurso | Valor |
|---|---|
| Memoria | 4 GB (mínimo 3 GB) |
| Procesadores | 2 |
| Disco | 30 GB |
| Red | NAT. Opcional: un segundo adaptador "Bridged" si quieres que nmap vea la red del laboratorio |

## 3. Instalar AlmaLinux

1. **Selección de software:** elige **"Server with GUI"** (con escritorio; Nagios y Wireshark lo
   necesitan).
2. **Destino de instalación:** deja la **partición automática**.
3. **Usuario:** crea tu usuario normal y marca **"Hacer administrador a este usuario"** (para poder
   usar `sudo`). No trabajes como root.
4. Instala y reinicia.

## 4. Conectar con GitHub

Primero acepta la invitación de colaborador que te llega por correo (si no te llegó, pídela a Erick).
En una terminal de la VM:

```bash
sudo dnf update -y
sudo dnf install -y git 'dnf-command(config-manager)'
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install -y gh
gh auth login          # elige GitHub.com, HTTPS, y entra con el navegador
git config --global user.name  "Tu Nombre"
git config --global user.email "tu-correo-de-github"
```

## 5. Descargar el proyecto e instalar

```bash
cd ~
git clone https://github.com/albertomtz97/Admin.-Redes---Proyecto-Abarrotes-.git proyecto
cd proyecto
git switch <tu-rama>
sudo ./instalar.sh
```

| Persona | Rama |
|---|---|
| Beto | `beto/gestion` |
| Diego | `diego/respaldo` |
| Brian | `brian/tareas` |
| Gonzalo | `gonzalo/seguridad` |

`instalar.sh` descarga e instala todo lo que usa el proyecto (cron, at, rsync, xfsdump, nmap,
Wireshark, Apache y Nagios), crea las carpetas de datos y te pide la contraseña de Nagios. No
instales esos programas a mano ni instales Nginx (choca con Apache).

**Si ya habías clonado el proyecto**, solo actualízalo. Guarda antes tus cambios con un commit:

```bash
cd ~/proyecto
git fetch
git switch <tu-rama>
git merge origin/dev
```

## 6. Instantánea (recomendado)

En VirtualBox: Máquina → Tomar instantánea → **"limpia"**. Si algo se rompe al probar (borrar
usuarios, restaurar archivos), regresas a ella en segundos.

## Siguiente paso

Lee [equipo/GUIA.md](../equipo/GUIA.md): cómo programar, probar y subir tu módulo.

## Problemas comunes

| Síntoma | Qué hacer |
|---|---|
| `$'\r': command not found` | `sed -i 's/\r$//' archivo.sh` |
| `Permission denied` al correr un `.sh` | `chmod +x archivo.sh` |
| "Este sistema debe ejecutarse con sudo" | Usa `sudo ./menu.sh` desde tu usuario |
| Una cron no corre | `sudo tail /var/log/cron` y `ls -lZ /etc/cron.d/` |
| Nagios da error 503 | `sudo systemctl status php-fpm httpd nagios` |
| Wireshark o el navegador no abren | Prueba desde el escritorio y revisa `logs/gui.log` |
