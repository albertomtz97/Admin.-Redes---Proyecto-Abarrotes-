# Sistema de Administración — Tienda de Abarrotes

Proyecto final de **Administración de Redes**. Menú en Bash para AlmaLinux que administra
usuarios y grupos, tareas programadas (cron y at), respaldos y herramientas de seguridad.

## Uso rápido

```bash
sudo ./instalar.sh   # una sola vez: instala dependencias y servicios
sudo ./menu.sh       # abre el sistema
```

## Documentación

| Documento | Para qué |
|---|---|
| [docs/guia-maquina-virtual.md](docs/guia-maquina-virtual.md) | **Empieza aquí**: preparar tu VM de AlmaLinux, GitHub, Claude Code y flujo diario |
| [docs/requisitos.md](docs/requisitos.md) | Lo que pidió el profesor, obligatorio y opcional |
| [docs/specs/0001-sistema-abarrotes/index.md](docs/specs/0001-sistema-abarrotes/index.md) | Arquitectura, estructura, contrato entre módulos, comentarios, formato de datos |
| [0002-base.md](docs/specs/0001-sistema-abarrotes/0002-base.md) | Menú, `lib/comunes.sh`, instalador, pruebas |
| [0003-gestion.md](docs/specs/0001-sistema-abarrotes/0003-gestion.md) | Usuarios y grupos |
| [0004-respaldo.md](docs/specs/0001-sistema-abarrotes/0004-respaldo.md) | tar gzip/bzip2, rsync, xfsdump |
| [0005-tareas.md](docs/specs/0001-sistema-abarrotes/0005-tareas.md) | cron, at, pagos a distribuidores |
| [0006-seguridad.md](docs/specs/0001-sistema-abarrotes/0006-seguridad.md) | Nagios, Wireshark, nmap |

## Equipo

Instrucciones simples por persona: [equipo/LEEME.md](equipo/LEEME.md).

| Módulo | Responsable | Rama |
|---|---|---|
| 0002 Base + integración y pruebas | Erick | `dev` |
| 0003 Gestión | Beto | `feature/gestion` |
| 0004 Respaldo | Diego | `feature/respaldo` |
| 0005 Tareas | Brian | `feature/tareas` |
| 0006 Seguridad | Gonzalo | `feature/seguridad` |
