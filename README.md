# Project Starter Framework

> Framework para iniciar proyectos con CI-Local, VibeKanban y metodología de oleadas paralelas.

---

## Requisitos Previos

| Herramienta | Requerido | Para qué |
|-------------|-----------|----------|
| **Git** | Sí | Control de versiones |
| **Docker Desktop** | Sí | CI simulation (pre-push) |
| **Semgrep** | Recomendado | Security scan (pre-commit) |

```bash
# Instalar Semgrep
pip install semgrep
```

---

## Quick Start (2 minutos)

### Windows (PowerShell)

```powershell
# 1. Copiar framework a tu proyecto
Copy-Item -Recurse C:\Programacion\project-starter-framework\* C:\path\to\tu-proyecto\

# 2. Ir al proyecto
cd C:\path\to\tu-proyecto

# 3. Renombrar .gitignore
Rename-Item .gitignore.template .gitignore

# 4. Ejecutar setup
.\scripts\init-project.ps1
```

### Linux/Mac

```bash
# 1. Copiar framework
cp -r /path/to/project-starter-framework/. /path/to/tu-proyecto/

# 2. Ir al proyecto
cd /path/to/tu-proyecto

# 3. Renombrar .gitignore
mv .gitignore.template .gitignore

# 4. Ejecutar setup
./scripts/init-project.sh
```

---

## Qué incluye

```
project-starter-framework/
│
├── .ai-config/                   # Config agnóstica para AI CLIs
│   ├── agents/                   # 78+ agentes organizados
│   │   ├── business/             # API design, análisis, PM
│   │   ├── creative/             # UX/UI design
│   │   ├── data-ai/              # ML, data science, MLOps
│   │   ├── development/          # Frontend, backend, full-stack
│   │   ├── infrastructure/       # DevOps, cloud, K8s
│   │   ├── quality/              # Testing, security, code review
│   │   ├── specialized/          # Workflows, migrations, etc.
│   │   └── _TEMPLATE.md          # Template para crear nuevos
│   ├── skills/                   # Skills (Gentleman-Skills compatible)
│   │   ├── frontend-design.md    # Diseño frontend distintivo
│   │   ├── ci-local-guide.md     # Guía CI-Local
│   │   ├── wave-workflow.md      # Flujo de oleadas
│   │   ├── git-workflow.md       # Git workflow
│   │   └── references/           # Documentación de referencia
│   ├── hooks/                    # Hooks de eventos
│   ├── prompts/                  # System prompts reutilizables
│   └── README.md                 # Documentación
│
├── .ci-local/                    # CI Local (evita romper CI)
│   ├── ci-local.ps1/sh           # Scripts principales
│   ├── install.ps1/sh            # Instaladores standalone
│   ├── semgrep.yml               # Reglas de seguridad
│   └── hooks/                    # Git hooks
│       ├── pre-commit            # AI check + lint + security
│       ├── commit-msg            # Bloquea AI en mensajes
│       └── pre-push              # CI simulation en Docker
│
├── .project/                     # Memoria del proyecto
│   ├── Memory/
│   │   ├── CONTEXT.md            # Estado actual (leer al inicio)
│   │   ├── DECISIONS.md          # ADRs (decisiones arquitectura)
│   │   ├── BLOCKERS.md           # Problemas y soluciones
│   │   └── WAVES.md              # Oleadas de trabajo
│   └── Sessions/
│       └── TEMPLATE.md           # Template de sesión diaria
│
├── .github/                      # GitHub config
│   ├── workflows/                # Reusable workflows (CI mínimo)
│   │   ├── reusable-build-java.yml
│   │   ├── reusable-build-node.yml
│   │   ├── reusable-build-python.yml
│   │   ├── reusable-build-go.yml
│   │   ├── reusable-docker.yml
│   │   └── reusable-release.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── ISSUE_TEMPLATE/
│
├── templates/                    # CI templates para copiar
│   ├── github/                   # GitHub Actions templates
│   │   ├── ci-java.yml
│   │   ├── ci-node.yml
│   │   └── ci-python.yml
│   ├── gitlab/                   # GitLab CI templates
│   │   ├── gitlab-ci-java.yml
│   │   └── gitlab-ci-node.yml
│   └── README.md                 # Documentación de templates
│
├── scripts/                      # Automatización
│   ├── init-project.ps1/sh       # Setup inicial
│   ├── new-wave.ps1/sh           # Gestión de oleadas
│   ├── sync-ai-config.ps1/sh     # Sincronizar AI config
│   └── add-skill.sh              # Agregar Gentleman-Skills
│
├── CLAUDE.md                     # Instrucciones Claude Code
├── README.md                     # Esta documentación
└── .gitignore.template           # Template de .gitignore
```

---

## Flujo de Trabajo

### Visión General

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PLANIFICACIÓN                               │
│  VibeKanban: Lista de tareas → Análisis dependencias → Oleadas      │
└─────────────────────────────────────────────────────────────────────┘
                                   ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      EJECUCIÓN POR OLEADAS                          │
│  Oleada 1: [T-001] [T-002] [T-003]  (paralelo, sin dependencias)   │
│                        ↓ merge all → develop                        │
│  Oleada 2: [T-004] [T-005]          (dependen de oleada 1)         │
│                        ↓ merge all → develop                        │
│  Release: develop → main                                            │
└─────────────────────────────────────────────────────────────────────┘
                                   ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         CI-LOCAL                                    │
│  pre-commit: lint + security (~30s)                                │
│  pre-push: CI completo en Docker (~3min)                           │
│  Si pasa local → pasa en GitHub Actions                            │
└─────────────────────────────────────────────────────────────────────┘
```

### Ejemplo Práctico

```bash
# 1. Crear oleada con tareas de VibeKanban
./scripts/new-wave.sh "T-001 T-002 T-003"

# 2. Crear branches automáticamente
./scripts/new-wave.sh --create-branches

# 3. Trabajar en cada tarea (paralelo o secuencial)
git checkout feature/t-001
# ... código ...
git add . && git commit -m "feat(scope): implement T-001"
git push  # ← CI-Local valida antes de push

# 4. Repetir para T-002, T-003...

# 5. Merge all a develop cuando oleada completa
# 6. Marcar oleada como completada
./scripts/new-wave.sh --complete

# 7. Siguiente oleada...
```

---

## Comandos Principales

### CI-Local

```bash
# Check rápido (lint + compile)
./.ci-local/ci-local.sh quick       # Linux/Mac
.\.ci-local\ci-local.ps1 quick      # Windows

# CI completo (como GitHub Actions)
./.ci-local/ci-local.sh full

# Shell interactivo en entorno CI (para debug)
./.ci-local/ci-local.sh shell

# Ver stack detectado
./.ci-local/ci-local.sh detect
```

### Oleadas

```bash
# Ver oleada actual
./scripts/new-wave.sh --list

# Crear nueva oleada
./scripts/new-wave.sh "T-001 T-002 T-003"

# Crear branches para tareas
./scripts/new-wave.sh --create-branches

# Completar oleada
./scripts/new-wave.sh --complete
```

### Git (con hooks automáticos)

```bash
git commit -m "..."   # → pre-commit: AI check + lint (~30s)
                      # → commit-msg: valida mensaje
git push              # → pre-push: CI en Docker (~3min)

# Skipear hooks (emergencia)
git commit --no-verify
git push --no-verify
```

---

## Stacks Soportados

El CI-Local **detecta automáticamente** tu stack:

| Stack | Archivo detectado | Lint | Test |
|-------|-------------------|------|------|
| Java/Gradle | `build.gradle(.kts)` | spotlessCheck | ./gradlew test |
| Java/Maven | `pom.xml` | spotless:check | ./mvnw test |
| Go | `go.mod` | golangci-lint | go test |
| Rust | `Cargo.toml` | clippy | cargo test |
| Node.js | `package.json` | npm/yarn/pnpm lint | npm test |
| Python | `pyproject.toml` | ruff/pylint | pytest |

---

## AI Attribution Blocker

Los hooks **bloquean automáticamente** cualquier referencia a IA:

- `Co-authored-by: Claude/GPT/AI`
- `Made by Claude`, `Generated by AI`
- `@anthropic.com`, `@openai.com`
- Nombres de modelos: `claude opus`, `gpt-4`, etc.

**Tú eres el único autor de tu código.**

---

## Integración con VibeKanban

El framework está diseñado para trabajar con [VibeKanban](https://github.com/BloopAI/vibe-kanban):

1. **Tareas en VibeKanban** → IDs tipo T-001, T-002
2. **Oleadas en el framework** → Agrupa tareas sin dependencias
3. **Branches automáticos** → `feature/t-001`, `feature/t-002`
4. **Estados sincronizados** → Actualizar en VibeKanban al completar

---

## AI Config (Agnóstico Multi-CLI)

El framework incluye configuración centralizada para múltiples AI CLIs:

### CLIs Soportados

| CLI | Config generada | Comando |
|-----|-----------------|---------|
| Claude Code | `CLAUDE.md` | `./scripts/sync-ai-config.sh claude` |
| OpenCode | `AGENTS.md` | `./scripts/sync-ai-config.sh opencode` |
| Cursor | `.cursorrules` | `./scripts/sync-ai-config.sh cursor` |
| Aider | `.aider.conf.yml` | `./scripts/sync-ai-config.sh aider` |

### Gentleman-Skills Integration

Compatible con [Gentleman-Skills](https://github.com/Gentleman-Programming/Gentleman-Skills):

```bash
# Listar skills disponibles
./scripts/add-skill.sh list

# Instalar skill
./scripts/add-skill.sh gentleman react-19
./scripts/add-skill.sh gentleman typescript

# Sincronizar config
./scripts/sync-ai-config.sh all
```

### Agentes Incluidos (78+)

El framework incluye una biblioteca completa de agentes organizados por categoría:

| Categoría | Agentes | Ejemplos |
|-----------|---------|----------|
| **business/** | 6 | api-designer, business-analyst, product-strategist, project-manager |
| **creative/** | 1 | ux-designer |
| **data-ai/** | 6 | ai-engineer, data-scientist, mlops-engineer, prompt-engineer |
| **development/** | 14 | backend-architect, fullstack-engineer, react-pro, rust-pro, python-pro |
| **infrastructure/** | 7 | cloud-architect, devops-engineer, kubernetes-expert, monitoring-specialist |
| **quality/** | 7 | code-reviewer, test-engineer, security-auditor, e2e-test-specialist |
| **specialized/** | 12+ | workflow-optimizer, error-detective, code-migrator, solo-dev-planner |
| **root/** | 4 | orchestrator, code-reviewer, test-runner, wave-executor |

### Skills Incluidos

| Skill | Descripción |
|-------|-------------|
| `frontend-design` | Diseño frontend con estética distintiva |
| `claude-md-improver` | Auditoría y mejora de CLAUDE.md |
| `claude-automation-recommender` | Recomendaciones de automatización |
| `ci-local-guide` | Guía de CI-Local |
| `wave-workflow` | Flujo de oleadas paralelas |
| `git-workflow` | Guía de Git workflow |

### Crear agente/skill personalizado

```bash
# Copiar template
cp .ai-config/agents/_TEMPLATE.md .ai-config/agents/mi-agente.md

# Editar y sincronizar
./scripts/sync-ai-config.sh all
```

---

## Branching Strategy

```
main (producción)
  ↑ PR (release)
develop (integración)
  ↑ PR (merge oleada)
feature/t-xxx-descripcion (trabajo)
```

---

## Personalización

### Agregar reglas Semgrep

Editar `.ci-local/semgrep.yml` para reglas específicas de tu proyecto.

### Cambiar comandos de CI

Editar `detect_stack()` en `.ci-local/ci-local.sh` o `.ci-local/ci-local.ps1`.

### Agregar scripts

Crear en `scripts/` con versiones `.sh` y `.ps1`.

---

## Documentación Adicional

- [CI-Local Guide](.ci-local/README.md) - Detalles de CI local
- [Memory Templates](.project/Memory/README.md) - Cómo usar la memoria
- [Scripts Reference](scripts/README.md) - Todos los scripts
- [Waves Guide](.project/Memory/WAVES.md) - Cómo usar oleadas

---

## CI Templates (Ahorro de Minutos)

El framework incluye **workflows reutilizables** para minimizar el consumo de minutos de CI.

### Filosofía

```
┌─────────────────────────────────────────────────────────────────────┐
│  CI LOCAL (completo)                 CI REMOTO (mínimo)             │
│  ─────────────────                   ─────────────────              │
│  • Tests                             • Solo build                   │
│  • Lint                              • Solo en PRs/tags             │
│  • Security scans                    • Sin schedules                │
│  • Docker simulation                 • ~3 min por ejecución         │
└─────────────────────────────────────────────────────────────────────┘
```

### Uso en tu proyecto

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    uses: JNZader/project-starter-framework/.github/workflows/reusable-build-java.yml@main
    with:
      java-version: '21'
      run-tests: false  # Tests localmente!
```

### Workflows Disponibles

| Workflow | Stack | Minutos |
|----------|-------|---------|
| `reusable-build-java.yml` | Java/Gradle | ~3 min |
| `reusable-build-node.yml` | Node.js | ~2 min |
| `reusable-build-python.yml` | Python | ~2 min |
| `reusable-build-go.yml` | Go | ~2 min |
| `reusable-docker.yml` | Docker | ~5 min |
| `reusable-release.yml` | Semantic Release | ~2 min |

### Templates pre-configurados

```bash
# Copiar template a tu proyecto
cp templates/github/ci-java.yml .github/workflows/ci.yml
cp templates/gitlab/gitlab-ci-java.yml .gitlab-ci.yml
```

Ver [templates/README.md](templates/README.md) para documentación completa.

---

## Troubleshooting

### "Docker not running"

```bash
# Iniciar Docker Desktop
# O verificar: docker info
```

### "Tests pasan local pero fallan en pre-push"

Ese es el punto. El pre-push usa Docker para replicar CI.
Debug con:

```bash
./.ci-local/ci-local.sh shell
# Estás en el mismo entorno que CI
```

### "Commit bloqueado por AI attribution"

Revisa tu mensaje de commit o archivos staged.
El hook detectó una referencia a IA que debe removerse.

---

*Framework Version: 1.1.0* - Incluye 78+ agentes, 6 skills, AI-agnostic config
