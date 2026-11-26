# Instrucciones para agentes de IA

Proyecto en Bash para AlmaLinux 9 (sistema de administración de una tienda de abarrotes; equipo de 5).

Antes de cualquier cambio, lee `equipo/COMO-TRABAJAR.md` y la instrucción del integrante en `equipo/`.

Reglas duras:
- Trabaja solo en los archivos del integrante (tabla en `equipo/COMO-TRABAJAR.md`).
- No toques `lib/comunes.sh`, `menu.sh` ni `instalar.sh`, salvo que se trabaje en la rama `erick/base`.
- La IA no ejecuta `git push`, `git merge` ni commits en `dev` o `main`; esos pasos los hace la persona. Todo entra por pull request desde `<nombre>/<módulo>` hacia `dev`.
- El contrato técnico (funciones, CSV, comentarios) está en `docs/specs/0001-sistema-abarrotes/index.md`; no inventes funciones de otros módulos.
- Pantallas solo con `ui_*`; sigue `equipo/plantilla_modulo.sh`.
