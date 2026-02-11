# Project Starter Framework

> Framework modular para iniciar proyectos con CI-Local, AI Config y CI mínimo.

---

## Requisitos Previos

| Herramienta | Requerido | Para qué |
|-------------|-----------|----------|
| **Git** | Sí | Control de versiones |
| **Docker Desktop** | Recomendado | CI simulation (pre-push) |
| **Semgrep** | Opcional | Security scan (pre-commit) |

```bash
# Instalar Semgrep (opcional)
pip install semgrep
```

---

## Quick Start (2 minutos)

### Linux/Mac

```bash
# 1. Copiar framework (sin optional/)
cp -r /path/to/project-starter-framework/{.ai-config,.ci-local,.github,templates,scripts,CLAUDE.md,.gitignore.template} /path/to/tu-proyecto/

# 2. Ir al proyecto
cd /path/to/tu-proyecto

# 3. Renombrar .gitignore
mv .gitignore.template .gitignore

# 4. Ejecutar setup
./scripts/init-project.sh
```

### Windows (PowerShell)

```powershell
# 1. Copiar framework
Copy-Item -Recurse C:\path\to\project-starter-framework\{.ai-config,.ci-local,.github,templates,scripts,CLAUDE.md,.gitignore.template} C:\path\to\tu-proyecto\

# 2. Ir al proyecto
cd C:\path\to\tu-proyecto

# 3. Renombrar .gitignore
Rename-Item .gitignore.template .gitignore

# 4. Ejecutar setup
.\scripts\init-project.ps1
```

---

## Qué incluye

```
project-starter-framework/
│
├── .ai-config/                   # Config para AI CLIs (78+ agentes)
│   ├── agents/                   # Agentes organizados por categoría
│   ├── skills/                   # Skills reutilizables
│   └── hooks/                    # Hooks de eventos
│
├── .ci-local/                    # CI Local (evita romper CI remoto)
│   ├── ci-local.ps1/sh           # Scripts principales
│   ├── semgrep.yml               # Reglas de seguridad
│   └── hooks/                    # Git hooks (pre-commit, pre-push)
│
├── .github/                      # GitHub config
│   └── workflows/                # Reusable workflows (CI mínimo)
│       ├── reusable-build-java.yml
│       ├── reusable-build-node.yml
│       ├── reusable-build-python.yml
│       ├── reusable-build-go.yml
│       ├── reusable-build-rust.yml
│       ├── reusable-docker.yml
│       └── reusable-release.yml
│
├── templates/                    # CI templates para copiar
│   ├── github/                   # GitHub Actions (java, node, python, rust)
│   └── gitlab/                   # GitLab CI (java, node, rust)
│
├── optional/                     # Módulos opcionales
│   ├── vibekanban/               # Oleadas paralelas + memoria
│   └── memory-simple/            # Solo un archivo de notas
│
├── scripts/                      # Automatización
│   ├── init-project.ps1/sh       # Setup inicial
│   ├── sync-ai-config.ps1/sh     # Sincronizar AI config
│   └── add-skill.sh              # Agregar Gentleman-Skills
│
├── CLAUDE.md                     # Instrucciones Claude Code
└── .gitignore.template           # Template de .gitignore
```

---

## Componentes

### 1. CI-Local (Core)

Valida tu código localmente antes de push. Si pasa local → pasa en CI remoto.

```bash
# Check rápido (lint + compile)
./.ci-local/ci-local.sh quick

# CI completo (como GitHub Actions)
./.ci-local/ci-local.sh full

# Shell interactivo en entorno CI
./.ci-local/ci-local.sh shell
```

**Git hooks automáticos:**
```bash
git commit -m "..."   # → pre-commit: AI check + lint (~30s)
git push              # → pre-push: CI en Docker (~3min)
```

### 2. CI Templates (Core)

Workflows reutilizables para minimizar minutos de CI:

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    uses: JNZader/project-starter-framework/.github/workflows/reusable-build-java.yml@main
    with:
      java-version: '21'
      run-tests: false  # Tests localmente!
```

| Workflow | Stack | Minutos |
|----------|-------|---------|
| `reusable-build-java.yml` | Java/Gradle | ~3 min |
| `reusable-build-node.yml` | Node.js | ~2 min |
| `reusable-build-python.yml` | Python | ~2 min |
| `reusable-build-go.yml` | Go | ~2 min |
| `reusable-build-rust.yml` | Rust | ~3 min |
| `reusable-docker.yml` | Docker | ~5 min |
| `reusable-release.yml` | Semantic Release | ~2 min |

### 3. AI Config (Core)

Config centralizada para múltiples AI CLIs:

| CLI | Config generada | Comando |
|-----|-----------------|---------|
| Claude Code | `CLAUDE.md` | `./scripts/sync-ai-config.sh claude` |
| Cursor | `.cursorrules` | `./scripts/sync-ai-config.sh cursor` |
| Aider | `.aider.conf.yml` | `./scripts/sync-ai-config.sh aider` |

**78+ agentes incluidos** organizados por categoría.

### 4. VibeKanban (Opcional)

Metodología de oleadas paralelas. Ver [optional/vibekanban/](optional/vibekanban/).

```bash
# Instalar si lo necesitas
cp -r optional/vibekanban/.project tu-proyecto/
cp optional/vibekanban/new-wave.* tu-proyecto/scripts/
```

---

## Stacks Soportados

El CI-Local **detecta automáticamente** tu stack:

| Stack | Archivo detectado | Lint | Test |
|-------|-------------------|------|------|
| Java/Gradle | `build.gradle` | spotlessCheck | ./gradlew test |
| Java/Maven | `pom.xml` | spotless:check | ./mvnw test |
| Go | `go.mod` | golangci-lint | go test |
| Rust | `Cargo.toml` | clippy | cargo test |
| Node.js | `package.json` | npm lint | npm test |
| Python | `pyproject.toml` | ruff | pytest |

---

## AI Attribution Blocker

Los hooks **bloquean automáticamente** cualquier referencia a IA:

- `Co-authored-by: Claude/GPT/AI`
- `Made by Claude`, `Generated by AI`
- `@anthropic.com`, `@openai.com`

**Tú eres el único autor de tu código.**

---

## Módulos Opcionales

| Módulo | Descripción | Instalación |
|--------|-------------|-------------|
| `vibekanban/` | Oleadas paralelas + memoria | `cp -r optional/vibekanban/.project .` |
| `memory-simple/` | Solo un archivo NOTES.md | `cp -r optional/memory-simple/.project .` |

Ver [optional/README.md](optional/README.md) para más detalles.

---

## Documentación

- [CI-Local Guide](.ci-local/README.md)
- [CI Templates](templates/README.md)
- [AI Config](.ai-config/README.md)
- [Optional Modules](optional/README.md)

---

## Troubleshooting

### "Docker not running"

```bash
# Iniciar Docker Desktop o verificar
docker info
```

### "Tests pasan local pero fallan en pre-push"

Ese es el punto. El pre-push usa Docker para replicar CI exacto.

```bash
./.ci-local/ci-local.sh shell
# Debug en el mismo entorno que CI
```

### "Commit bloqueado por AI attribution"

Revisa tu mensaje de commit o archivos staged.
El hook detectó una referencia a IA que debe removerse.

---

*Framework Version: 2.0.0* - Modular: CI-Local + AI Config + CI Templates (VibeKanban opcional)
