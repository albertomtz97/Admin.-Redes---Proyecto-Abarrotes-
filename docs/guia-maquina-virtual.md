# Guía: cómo trabajar en la máquina virtual

Esta guía es para cada integrante del equipo. Al terminarla vas a tener una AlmaLinux en una
máquina virtual (VM) con el proyecto clonado, conectada a GitHub y, si quieres, con Claude Code
instalado para que te ayude a programar y a correr las pruebas.

Tiempo aproximado: 1 a 1.5 horas la primera vez.

---

## 1. Crear la máquina virtual

Usa **VirtualBox** (gratis) o VMware. Descarga el ISO de **AlmaLinux 9** (DVD o Boot) desde la
página oficial de AlmaLinux.

Configuración recomendada de la VM:

| Recurso | Valor |
|---|---|
| Memoria | 4 GB (mínimo 3 GB; Nagios y el escritorio consumen) |
| Procesadores | 2 |
| Disco | 30 GB |
| Red | NAT (internet). Opcional: un segundo adaptador "Bridged" si quieres que nmap vea la red del laboratorio |

## 2. Instalar AlmaLinux

En el instalador:

1. **Selección de software**: elige **"Server with GUI"** (servidor con escritorio). Hace falta
   escritorio para que Nagios abra el navegador y Wireshark abra su ventana.
2. **Destino de instalación**: deja la **partición automática**. Así `/boot` queda como partición
   separada en XFS, que es lo que usa el respaldo con xfsdump.
3. **Usuario**: crea tu usuario normal y marca **"Hacer administrador a este usuario"**
   (lo mete al grupo `wheel` para poder usar `sudo`). No trabajes como root directamente: el
   sistema usa `$SUDO_USER` y necesita que entres con tu usuario y uses `sudo`.
4. Instala y reinicia.

Primeros comandos, en una terminal:

```bash
sudo dnf update -y
sudo dnf install -y git
```

## 3. Conectarte a GitHub

El dueño del repositorio te agrega como colaborador (en GitHub: Settings, Collaborators).
Acepta la invitación que te llega por correo.

En la VM:

```bash
sudo dnf install -y 'dnf-command(config-manager)'
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install -y gh
gh auth login            # elige GitHub.com, HTTPS, y entra con el navegador
git config --global user.name  "Tu Nombre"
git config --global user.email "tu-correo-de-github"
```

`gh auth login` deja configurado git para que `git push` funcione sin pedir contraseña.

## 4. Clonar el proyecto

```bash
cd ~
git clone https://github.com/albertomtz97/Admin.-Redes---Proyecto-Abarrotes-.git proyecto
cd proyecto
git switch dev
```

Cuando ya exista el módulo Base (spec 0002), prepara todo el ambiente con:

```bash
sudo ./instalar.sh
```

Instala cron, at, rsync, xfsdump, nmap, Wireshark, Apache y Nagios, crea las carpetas y deja las
tareas fijas. Se puede correr varias veces sin problema. Mientras no exista, instala a mano solo lo
de tu módulo (por ejemplo `sudo dnf install -y nmap wireshark`).

> **No instales Nginx.** La página de Nagios usa Apache (`httpd`); los dos pelearían por el puerto 80.

## 5. Sacar una instantánea (snapshot)

Con la VM ya lista, en VirtualBox: Máquina, Tomar instantánea, nombre **"limpia"**.
Antes de probar algo delicado (borrar usuarios, restaurar `/etc`), saca otra. Si algo se rompe,
regresas a la instantánea en segundos.

## 6. (Opcional) Editar con VS Code desde Windows

Es más cómodo que `nano` o `vim` para archivos largos.

1. En la VM: `sudo systemctl enable --now sshd`.
2. En VirtualBox, con red NAT: Configuración, Red, Avanzado, Reenvío de puertos. Agrega una regla:
   anfitrión `2222` → invitado `22`.
3. En Windows, en VS Code instala la extensión **Remote - SSH** y conéctate a
   `tu_usuario@localhost -p 2222`.
4. Abre la carpeta `~/proyecto`. Editas en VS Code; los archivos viven en la VM.

## 7. Instalar Claude Code en la VM

Así Claude puede ejecutar el código y las pruebas directamente, en lugar de que tú le copies los
errores.

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Si el comando cambia o falla, revisa la guía de instalación oficial de Claude Code. Luego:

```bash
cd ~/proyecto
claude          # la primera vez te pide iniciar sesión con tu cuenta
```

### Permitir que Claude use `sudo` (solo en la VM de pruebas)

El sistema necesita root, y Claude no puede escribir tu contraseña de `sudo`. Tienes dos opciones:

- **Opción A (recomendada para la VM de pruebas):** permitir `sudo` sin contraseña a tu usuario.
  ```bash
  echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/90-pruebas
  sudo chmod 440 /etc/sudoers.d/90-pruebas
  ```
  ⚠️ Hazlo **solo en esta VM de pruebas**, nunca en un servidor real. Para quitarlo:
  `sudo rm /etc/sudoers.d/90-pruebas`.
- **Opción B:** dejar `sudo` con contraseña. Claude te pide que corras tú los comandos con root
  escribiendo `! sudo <comando>` dentro de Claude Code, y la salida le llega directo.

### Primera instrucción a Claude en la VM

Claude en la VM no recuerda las conversaciones que tuviste en Windows, pero todo lo decidido está en
el repositorio. Empieza con algo como:

> Lee `docs/specs/0001-sistema-abarrotes/index.md` y el spec de mi módulo. Vamos a programar
> el módulo `<nombre>` siguiendo su Build plan.

### Qué puede probar Claude y qué te toca a ti

| Claude lo hace solo | Lo pruebas tú |
|---|---|
| `bash -n` y `shellcheck` | Recorrer el menú a mano (es interactivo) |
| `pruebas/probar_<modulo>.sh` y `correr_todas.sh` | Que Nagios abra el navegador y Wireshark su ventana |
| Correr `instalar.sh` y revisar su salida | Capturas de pantalla para el reporte |
| Ejecutar funciones y scripts de `tareas/` | Probar con `su - <usuario>` los permisos de carpetas |
| Revisar `logs/`, `crontab`, `atq`, `systemctl status` | |

## 8. Flujo de trabajo de cada día

```bash
cd ~/proyecto
git switch dev && git pull                 # traer lo último del equipo
git switch <tu-nombre>/<tu-modulo>         # o crearla la 1a vez: git switch -c <tu-nombre>/<tu-modulo>
git merge dev                              # meter a tu rama lo nuevo de dev

# ... programar y probar ...
bash -n modulos/<tu-modulo>.sh
./pruebas/correr_todas.sh

git add <tus archivos>
git commit -m "respaldo: crear respaldo gzip y bzip2"
git push -u origin <tu-nombre>/<tu-modulo>
gh pr create --base dev                    # abre el pull request hacia dev
```

Reglas del equipo (detalle en el spec 0001):

- Solo tocas **tus** archivos. `lib/comunes.sh`, `menu.sh` e `instalar.sh` los cambia solo el
  responsable de la Base; si necesitas algo ahí, se lo pides.
- No subas `datos/`, `logs/` ni `respaldos/` (ya están en `.gitignore`).
- Antes del pull request, las pruebas tienen que pasar.
- Erick revisa el pull request y lo une a `dev`.

## 9. Problemas comunes

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| `$'\r': command not found` | El archivo tiene fin de línea de Windows (CRLF) | `sed -i 's/\r$//' archivo.sh`; revisa que exista `.gitattributes` |
| `Permission denied` al correr un `.sh` | Falta permiso de ejecución | `chmod +x archivo.sh` |
| "Este sistema debe ejecutarse con sudo" | Corriste sin `sudo` o entraste como root | `sudo ./menu.sh` desde tu usuario |
| Una cron no corre | Fin de línea CRLF, permisos o SELinux | `sudo tail /var/log/cron`, `ls -lZ /etc/cron.d/` |
| Nagios da error 503 | `php-fpm` detenido | `sudo systemctl status php-fpm httpd nagios` |
| Wireshark o el navegador no abren | Sesión gráfica o grupo | Revisa `logs/gui.log` |
| Algo raro con SELinux | Bloqueo de permisos | `sudo ausearch -m avc -ts recent` |

## 10. Día de la entrega

En **una** VM limpia (restaura la instantánea "limpia" o haz una nueva):

```bash
git clone https://github.com/albertomtz97/Admin.-Redes---Proyecto-Abarrotes-.git proyecto
cd proyecto
git switch main
sudo ./instalar.sh
sudo ./menu.sh
```

Ensáyalo al menos una vez antes de la presentación para confirmar que con esos comandos una
máquina nueva queda lista.
