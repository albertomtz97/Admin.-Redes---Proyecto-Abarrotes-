# Erick: integración, pruebas y reporte

## Tu papel

Eres el único que usa git. Recibes los `.zip` de cada compañero, los revisas, los unes a `dev` y les
mandas de vuelta el proyecto actualizado. También corres las pruebas completas, mantienes `lib/comunes.sh`,
`menu.sh` e `instalar.sh`, y armas el reporte.

## 1. Mandar el proyecto a tus compañeros

Cada vez que `dev` cambie (sobre todo si cambias `lib/comunes.sh`):

```bash
git switch dev
git archive --format=zip -o ~/abarrotes_dev_$(date +%F).zip dev
```

Mándales ese `.zip` (WhatsApp, Drive, correo). Lleva solo lo que está en git: sin datos ni logs.
Diles que lo descompriman en `~/proyecto` dentro de su VM.

## 2. Recibir el `.zip` de un compañero

Revisa que traiga **solo** los archivos de su lista (ver su instrucción en esta carpeta). Luego:

```bash
git switch dev && git pull
git switch -c feature/<modulo>            # la primera vez; después: git switch feature/<modulo>
unzip -o ~/Descargas/<modulo>_<nombre>_<fecha>.zip -d /tmp/entrega
cp -r /tmp/entrega/<sus archivos> .        # solo sus archivos, a su lugar

sed -i 's/\r$//' modulos/<modulo>.sh pruebas/probar_<modulo>.sh   # quitar CRLF por si acaso
chmod +x pruebas/probar_<modulo>.sh
git status                                 # confirma que SOLO cambiaron sus archivos
```

Si en `git status` aparece `lib/comunes.sh`, `menu.sh` o `instalar.sh`, **no lo aceptes**: regrésale
el `.zip` y pídele que quite esos cambios (o que te diga qué necesita para que tú lo agregues).

## 3. Revisar antes de unir

```bash
bash -n modulos/<modulo>.sh
shellcheck -S warning modulos/<modulo>.sh       # si lo instalaste (dnf install ShellCheck)
sudo ./pruebas/correr_todas.sh                  # que TODO siga pasando, no solo lo suyo
sudo ./menu.sh                                  # recorre su módulo y los demás
```

Revisa a mano la lista "Cómo probarlo a mano" de su instrucción. Si algo falla, regrésale la
lista de errores (o pídele ayuda a Claude para corregirlo).

## 4. Unir a dev con su nombre como autor

Así en el historial se ve quién hizo cada módulo:

```bash
git add modulos/<modulo>.sh pruebas/probar_<modulo>.sh   # y sus otros archivos
git update-index --chmod=+x pruebas/probar_<modulo>.sh
# solo Tareas: cron ejecuta estos scripts directo, necesitan permiso de ejecución
git update-index --chmod=+x tareas/*.sh
git commit --author="Diego Apellido <correo-de-diego>" -m "feat(respaldo): crear respaldos gzip/bzip2, restaurar, rsync y xfsdump"
git switch dev
git merge --no-ff feature/<modulo> -m "merge: módulo <modulo>"
sudo ./pruebas/correr_todas.sh
git push origin dev
```

Luego manda el proyecto actualizado a todos (paso 1).

## Orden para unir

1. **Gestión (Beto)**: después de unirlo, corre `sudo ./instalar.sh` para que cree los grupos de rol.
2. **Respaldo (Diego)**: antes que Tareas.
3. **Tareas (Brian)**: revisa que **no** venga el `modulos/respaldo.sh` falso que usó para probar.
4. **Seguridad (Gonzalo)**: en cualquier momento.

## Al final

- Prueba completa en una VM limpia: `git clone`, `sudo ./instalar.sh`, `sudo ./pruebas/correr_todas.sh`,
  recorrer el menú entero.
- `dev` → `main` y ensayo de la demostración (sección 10 de `docs/guia-maquina-virtual.md`).
- Reporte: pide a cada quien su sección (texto + capturas) en un documento aparte y tú lo juntas en
  `reporte/Proyecto final.docx`.
