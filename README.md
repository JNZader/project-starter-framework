# Project Starter Framework

![CI](https://github.com/JNZader/project-starter-framework/actions/workflows/ci-framework.yml/badge.svg)

> Framework modular para iniciar proyectos con CI-Local, AI Config y CI mínimo.

---

## Por que este framework?

### El Problema
- Los pipelines CI/CD consumen minutos costosos en runners remotos
- Los equipos rompen CI repetidamente porque no pueden testear localmente
- El desarrollo asistido por IA carece de contexto y memoria de proyecto
- Cada nuevo proyecto requiere horas de setup repetitivo
- Configurar 5 AI CLIs manualmente (Claude, OpenCode, Codex, Copilot, Gemini) es tedioso y propenso a errores

### La Solucion
- **CI-Local**: Testea localmente en Docker, replicando tu CI remoto exactamente
- **AI Config**: Configuracion centralizada de agentes para asistencia AI consistente
- **Global CLI Setup**: Automatiza la configuracion de 5 AI CLIs a nivel `$HOME` con un solo comando
- **Diseno Modular**: Usa solo lo que necesitas (memoria, code review, etc.)
- **Framework, no template**: Copia y personaliza, no forkea

## Quien deberia usar esto?

| Perfil | Modulos Recomendados | Beneficio |
|--------|---------------------|-----------|
| Solo Developer | CI-Local + AI Config + obsidian-brain | Iteracion rapida, memoria AI, validacion local |
| Equipo Pequeno | Todo core + ghagga | Reviews automaticos, contexto compartido |
| Open Source | Core + templates | Minimizar costos CI, community-friendly |
| Enterprise | Core + agentes custom | Compliance, security scanning |

---

## Requisitos Previos

| Herramienta | Requerido | Para qué |
|-------------|-----------|----------|
| **Git** | Sí | Control de versiones |
| **Docker Desktop** | Recomendado | CI simulation (pre-push) |
| **Semgrep** | Opcional | Security scan (pre-commit). Fallback automático a Docker si disponible |

```bash
# Instalar Semgrep (opcional)
pip install semgrep
```

---

## Global CLI Setup (nuevo)

Configura **5 AI CLIs** (Claude, OpenCode, Codex, Copilot, Gemini) a nivel `$HOME` con hooks, commands, skills, agents, SDD y MCP servers:

```bash
# Clonar el framework
git clone https://github.com/JNZader/project-starter-framework.git
cd project-starter-framework

# Ver qué haría (sin cambios)
./scripts/setup-global.sh --dry-run

# Instalar + configurar todo (no-interactivo)
./scripts/setup-global.sh --auto

# Solo configurar CLIs ya instalados
./scripts/setup-global.sh --auto --skip-install

# Configurar solo CLIs específicos
./scripts/setup-global.sh --clis=claude,gemini --features=hooks,sdd
```

**Flags disponibles:**

| Flag | Descripción |
|------|-------------|
| `--auto` | No-interactivo, instala y configura todo |
| `--dry-run` | Preview sin hacer cambios |
| `--clis=X,Y` | Seleccionar CLIs: `claude,opencode,codex,copilot,gemini` |
| `--features=X,Y` | Seleccionar features: `hooks,commands,skills,agents,sdd,mcp` |
| `--skip-install` | Solo configurar, no instalar CLIs |

**Qué configura por CLI:**

| CLI | Directorio | Settings | Instructions | Commands | Agents/Skills |
|-----|-----------|----------|-------------|---------|---------------|
| Claude | `~/.claude/` | JSON merge (hooks + permisos) | CLAUDE.md marker merge | Subdirectorios | Subdirectorios |
| OpenCode | `~/.config/opencode/` | JSON merge (MCP + agents) | AGENTS.md (overwrite) | Flatten con prefijo | Flatten con prefijo |
| Codex | `~/.codex/` | TOML create-if-absent | AGENTS.md (overwrite) | Inline en AGENTS.md | - |
| Copilot | `~/.copilot/` | - | copilot-instructions.md merge | - | Flatten + subdirs |
| Gemini | `~/.gemini/` | JSON merge (context) | GEMINI.md (overwrite) | TOML files | - |

> Ver [scripts/README.md](scripts/README.md) para documentación completa de `setup-global.sh`.

---

## Quick Start (2 minutos)

### Opción 1: Framework Core (sin módulos opcionales)

El framework core incluye CI-Local, AI Config y templates CI. Es totalmente funcional sin necesidad de módulos opcionales.

#### Linux/Mac

```bash
# 1. Copiar framework core (sin optional/)
cp -r /path/to/project-starter-framework/{.ai-config,.ci-local,.github,templates,scripts,lib,CLAUDE.md,.gitignore.template} /path/to/tu-proyecto/

# 2. Ir al proyecto
cd /path/to/tu-proyecto

# 3. Renombrar .gitignore
mv .gitignore.template .gitignore

# 4. Ejecutar setup
./scripts/init-project.sh
```

#### Windows (PowerShell)

```powershell
# 1. Copiar framework core
$items = '.ai-config','.ci-local','.github','templates','scripts','lib','CLAUDE.md','.gitignore.template'
$items | ForEach-Object { Copy-Item -Recurse "C:\path\to\project-starter-framework\$_" "C:\path\to\tu-proyecto\" }

# 2. Ir al proyecto
cd C:\path\to\tu-proyecto

# 3. Renombrar .gitignore
Rename-Item .gitignore.template .gitignore

# 4. Ejecutar setup
.\scripts\init-project.ps1
```

> **Tip:** Usa `--dry-run` para ver qué hará el setup sin hacer cambios:
> ```bash
> ./scripts/init-project.sh --dry-run
> .\scripts\init-project.ps1 -DryRun  # Windows
> ```

### Opción 2: Framework con módulos opcionales

Si deseas memoria de proyecto (Obsidian Brain) o code review automatizado (Ghagga):

```bash
# 1. Copiar framework completo (incluye optional/)
cp -r /path/to/project-starter-framework/{.ai-config,.ci-local,.github,templates,scripts,lib,optional,CLAUDE.md,.gitignore.template} /path/to/tu-proyecto/

# 2. Continuar con pasos 2-4 de Opción 1
```

**Módulos opcionales disponibles:**
- `obsidian-brain`: Memoria de proyecto con Kanban visual, Dataview y Templater
- `vibekanban`: Metodología de oleadas paralelas (legacy)
- `memory-simple`: Solo un archivo NOTES.md básico
- `engram`: Memoria persistente para agentes AI (MCP server)

El script `init-project.sh` te permitirá elegir qué módulos instalar de forma interactiva.

---

## Qué incluye

```
project-starter-framework/
│
├── .ai-config/                   # Config para AI CLIs (90+ agentes, 80+ skills, hooks, commands y modos)
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
│       ├── reusable-release.yml
│       └── auto-version.yml
│
├── templates/                    # CI + Global templates
│   ├── github/                   # GitHub Actions (java, node, python, rust, monorepo)
│   ├── gitlab/                   # GitLab CI (java, node, rust)
│   ├── global/                   # Global AI CLI config templates
│   │   ├── claude-settings.json  # Claude hooks + permissions
│   │   ├── opencode-config.json  # OpenCode MCP + agents
│   │   ├── codex-config.toml     # Codex model + sandbox
│   │   ├── gemini-settings.json  # Gemini context fileNames
│   │   ├── gemini-commands/      # 10 TOML commands (commit, review, plan, tdd, sdd-*)
│   │   ├── copilot-instructions/ # Base rules + SDD orchestrator
│   │   ├── sdd-*.md              # SDD orchestrator templates per CLI
│   │   └── sdd-instructions.md   # Generic SDD instructions
│   ├── renovate.json             # Config Renovate (dependency updates)
│   └── dependabot.yml            # Config Dependabot (alternativa)
│
├── optional/                     # Módulos opcionales
│   ├── obsidian-brain/           # Memoria de proyecto con Obsidian
│   ├── vibekanban/               # Oleadas paralelas + memoria (legacy)
│   └── memory-simple/            # Solo un archivo de notas
│
├── scripts/                      # Automatización
│   ├── init-project.ps1/sh       # Setup inicial de proyecto
│   ├── setup-global.sh           # Setup global de AI CLIs ($HOME level)
│   ├── sync-ai-config.ps1/sh     # Sincronizar AI config por proyecto
│   ├── add-skill.sh              # Agregar Gentleman-Skills
│   └── collect-skills.sh         # Importar skills desde otras herramientas
│
├── lib/                          # Shared libraries
│   ├── common.sh                 # Funciones compartidas (Bash)
│   └── Common.psm1               # Funciones compartidas (PowerShell)
│
├── tests/                        # Framework tests (Bats + Pester)
│   ├── framework.bats            # Tests Bash (45 tests)
│   ├── setup-global.bats         # Tests setup-global.sh (36 tests)
│   └── README.md                 # Guía de testing
│
├── .framework-version            # Versión del framework (auto-updated)
├── .releaserc                    # Config semantic-release
├── CLAUDE.md                     # Instrucciones Claude Code
├── CONTRIBUTING.md               # Guía de contribución
├── CHANGELOG.md                  # Historial de versiones
├── SECURITY.md                   # Política de seguridad
├── LICENSE                       # Licencia MIT
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

**Templates adicionales:**
- `ci-monorepo.yml` - Multi-servicio con detección de cambios
- `renovate.json` / `dependabot.yml` - Actualización de dependencias
- `.releaserc` - Semantic versioning automático

### 3. AI Config (Core)

Config centralizada para múltiples AI CLIs:

| CLI | Config generada | Comando |
|-----|-----------------|---------|
| Claude Code | `CLAUDE.md` | `./scripts/sync-ai-config.sh claude` |
| OpenCode | `AGENTS.md` | `./scripts/sync-ai-config.sh opencode` |
| Cursor | `.cursorrules` | `./scripts/sync-ai-config.sh cursor` |
| Aider | `.aider.conf.yml` | `./scripts/sync-ai-config.sh aider` |
| Gemini CLI | `GEMINI.md` | `./scripts/sync-ai-config.sh gemini` |
| Claude Commands | `.claude/commands/*` | `./scripts/sync-ai-config.sh commands` |

**90+ agentes y 80+ skills incluidos** organizados por categoría.

También soporta:
- `.ai-config/config.yaml` para targets declarativos (`./scripts/sync-ai-config.sh` sin argumentos)
- `.ai-config/.skillignore` para excluir skills por target (o globalmente)

### 4. Módulos Opcionales

Los módulos opcionales agregan funcionalidades extra al framework core:

| Módulo | Qué agrega | Cuándo usarlo |
|--------|-----------|---------------|
| `obsidian-brain` | Memoria de proyecto con Kanban, Dataview, Templater | Proyectos con planificación compleja |
| `vibekanban` | Oleadas paralelas + memoria (legacy) | Proyectos existentes con VibeKanban |
| `memory-simple` | Solo archivo NOTES.md | Proyectos simples sin Obsidian |
| `engram` | Memoria persistente para agentes AI (MCP server) | Proyectos con asistencia AI frecuente |

Ver [optional/README.md](optional/README.md) para más detalles.

### Diagnóstico

```bash
./scripts/doctor.sh          # Linux/Mac
.\scripts\doctor.ps1         # Windows
```

Verifica entorno (Git, Docker, Semgrep), integridad del framework, y configuración del proyecto.

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

### Matriz de Funcionalidades por Stack

| Funcionalidad | Java | Node.js | Python | Go | Rust |
|---------------|------|---------|--------|----|------|
| CI-Local (quick) | ✓ | ✓ | ✓ | ✓ | ✓ |
| CI-Local (full/Docker) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Pre-commit hooks | ✓ | ✓ | ✓ | ✓ | ✓ |
| Semgrep security scan | ✓ | ✓ | ✓ | ✓ | ✓ |
| GitHub Actions template | ✓ | ✓ | ✓ | ✓ | ✓ |
| GitLab CI template | ✓ | ✓ | ✓ | ✓ | ✓ |
| Woodpecker CI template | ✓ | ✓ | ✓ | ✓ | ✓ |
| Reusable workflow | ✓ | ✓ | ✓ | ✓ | ✓ |
| Dependabot config | ✓ | ✓ | ✓ | ✓ | ✓ |
| Lint integrado | spotless | eslint | ruff | golangci-lint | clippy |
| Test runner | JUnit | jest/vitest | pytest | go test | cargo test |
| Docker build | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## AI Attribution Blocker

Los hooks **bloquean automáticamente** cualquier referencia a IA:

- `Co-authored-by: Claude/GPT/AI`
- `Made by Claude`, `Generated by AI`
- `@anthropic.com`, `@openai.com`

**Tú eres el único autor de tu código.**

---

## Documentación

- [CI-Local Guide](.ci-local/README.md)
- [CI Templates](templates/README.md)
- [AI Config](.ai-config/README.md)
- [Scripts Guide](scripts/README.md) — incluye `setup-global.sh`, `init-project.sh`, `sync-ai-config.sh`
- [Optional Modules](optional/README.md)
- [Testing Guide](tests/README.md)

---

## Troubleshooting

### Diagnóstico

```bash
./scripts/doctor.sh          # Linux/Mac
.\scripts\doctor.ps1         # Windows
```

Verifica entorno (Git, Docker, Semgrep), integridad del framework, y configuración del proyecto.

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

*Framework Version: 2.1.0* - Modular: CI-Local + AI Config + Global CLI Setup + CI Templates + Optional Modules
