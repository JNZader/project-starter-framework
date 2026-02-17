# Propuesta de Mejoras y Evolución - Project Starter Framework

Este documento detalla las propuestas de mejora para el framework tras el análisis realizado el 16 de febrero de 2026. Las propuestas se dividen en herramientas de diagnóstico, expansión de IA, gestión de memoria y refinamiento del núcleo.

---

## 1. Nueva Herramienta: `scripts/doctor.sh` (Diagnóstico)

Se propone la creación de un comando "doctor" para validar la salud del entorno de desarrollo y la integración del framework en el proyecto.

- **Verificaciones de Entorno:**
    - Presencia y versión de Git, Docker y Semgrep.
    - Conectividad con el demonio de Docker (necesario para CI-Local full).
    - Presencia de CLIs de IA soportados (Claude Code, Cursor, Aider).
- **Verificaciones de Proyecto:**
    - Integridad de los Git Hooks (`core.hooksPath`).
    - Alineación de la versión local del framework con la versión del proyecto.
    - Detección correcta del stack tecnológico.
- **Salida:** Reporte visual con sugerencias de comandos para corregir problemas (ej: "Ejecuta `pip install semgrep` para habilitar el escaneo de seguridad").

## 2. Expansión del Ecosistema AI Config

El módulo `.ai-config` es uno de los pilares del proyecto. Se propone su expansión para soportar más herramientas emergentes.

- **Soporte Adicional:** Añadir perfiles de sincronización para `Continue.dev`, `Windsurf` y `Codeium`.
- **Lógica de Sincronización Inteligente:** Mejorar `sync-ai-config.sh` para que, en lugar de sobrescribir ciegamente, realice un backup automático o intente un "merge" básico de configuraciones existentes.
- **Generación de AGENTS.md:** Crear un script que genere automáticamente un catálogo visual (`AGENTS.md`) de todos los agentes disponibles en `.ai-config/agents`, extrayendo el nombre y la descripción de su frontmatter.

## 3. Interfaz CLI para Project Memory (cli-brain)

Para potenciar el uso de `obsidian-brain` sin salir de la terminal, se propone una utilidad `cli-brain`.

- **Comandos Propuestos:**
    - `cli-brain blocker "Descripción"`: Añade una entrada rápida a `BLOCKERS.md`.
    - `cli-brain decision "Título" --status accepted`: Registra una decisión en `DECISIONS.md`.
    - `cli-brain context`: Muestra un resumen del estado actual extraído de `CONTEXT.md`.
    - `cli-brain wave`: Alias para `new-wave.sh` con mejor formateo de salida.

## 4. Mejoras en el Núcleo (Core & Scripts)

- **Refactorización de `detect_stack`:** Mover la lógica de detección a una estructura basada en archivos de configuración o plugins, facilitando la adición de nuevos stacks (ej: Ruby, PHP, Elixir) sin engrosar `lib/common.sh`.
- **Dry-run en `init-project.sh`:** Añadir el flag `--dry-run` para que el usuario vea qué archivos se copiarán y qué hooks se activarán antes de realizar cambios reales.
- **Plantillas de Dependabot Externas:** Mover la generación de `dependabot.yml` de una función "hardcoded" en el script de inicio a archivos template en `templates/common/dependabot/`.

## 5. Automatización de Mantenimiento del Framework

- **Auto-Versioning:** Integrar un workflow que actualice automáticamente `.framework-version` basándose en los tags de Git o mediante `semantic-release`.
- **Paridad Bash/PowerShell:** Implementar un sistema de tests para los scripts `.ps1` (posiblemente usando `Pester`) para garantizar que la experiencia en Windows sea idéntica a la de Unix.

## 6. Documentación y UX

- **Matriz de Funcionalidades:** Incluir en el `README.md` una tabla comparativa de qué ofrece el framework para cada stack (Lint, Test, Docker support, etc.).
- **Guía de Extensión:** Documentar cómo un usuario puede añadir su propio "agente" o "skill" personalizado siguiendo los estándares del framework.

---

**Nota:** Estas propuestas están diseñadas para ser implementadas de forma incremental, priorizando la herramienta `doctor` y la expansión de `sync-ai-config` por su alto impacto inmediato en la productividad.
