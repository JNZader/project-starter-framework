# Claude Code Instructions - Project Starter Framework

> Framework modular para iniciar proyectos con CI-Local, AI Config y CI templates.

## IMPORTANTE: Este es un FRAMEWORK

Este repositorio es un **framework para bootstrap de proyectos**, NO un proyecto de aplicación.
Los componentes se copian a nuevos proyectos usando `scripts/init-project.sh`.

## Reglas Críticas

- **NO agregar atribuciones a IA** en commits, PRs, código o documentación
- **NO commitear CLAUDE.md** (está en .gitignore)
- **NO modificar hooks sin entender su función**
- Si un comando no da respuesta, asume que falló

## Estructura del Framework

```
.ai-config/         # 90+ agentes + 80+ skills para AI CLIs
.ci-local/          # CI local con git hooks (pre-commit, pre-push)
.github/workflows/  # Reusable workflows para GitHub Actions
templates/          # Templates CI + Global AI CLI config templates
templates/global/   # Templates para setup-global.sh (hooks, commands, settings)
scripts/            # Automatización (setup-global, init, sync, add-skill)
optional/           # Obsidian Brain, VibeKanban (legacy), memory-simple, Engram
tests/              # Bats (81 tests) + Pester tests
```

## Project Memory (Obsidian Brain)

Modulo recomendado para memoria de proyecto. Se instala con `init-project.sh` opcion 1.
Funciona como markdown plano sin Obsidian. Con Obsidian agrega Kanban visual, queries Dataview y templates Templater.

### Al iniciar sesion (leer en orden):
1. `.project/Memory/CONTEXT.md` - Estado actual del proyecto
2. `.project/Memory/KANBAN.md` - Tareas activas (board visual)
3. `.project/Memory/BLOCKERS.md` - Problemas abiertos

### Durante la sesion:
- Mover tareas en KANBAN.md entre secciones H2 (Backlog/En Progreso/Review/Completado)
- Documentar decisiones en DECISIONS.md con inline fields: `type:: adr`, `status::`, `date::`
- Documentar blockers en BLOCKERS.md con inline fields: `type:: blocker`, `status::`, `impact::`

### Al finalizar sesion:
- Actualizar CONTEXT.md con estado actual
- Mover tareas completadas en KANBAN.md

### Oleadas (Waves):
```bash
./scripts/new-wave.sh --list              # Ver oleada actual
./scripts/new-wave.sh "T-001 T-002"       # Crear oleada
./scripts/new-wave.sh --complete          # Completar oleada
```

## Comandos Principales

```bash
# Setup global de AI CLIs ($HOME level)
./scripts/setup-global.sh --auto          # No-interactivo
./scripts/setup-global.sh --dry-run       # Preview
./scripts/setup-global.sh --clis=claude   # Solo Claude

# Setup nuevo proyecto (interactivo)
./scripts/init-project.sh

# Diagnóstico del entorno y framework
./scripts/doctor.sh           # Linux/Mac
.\scripts\doctor.ps1          # Windows

# Sincronizar config AI por proyecto
./scripts/sync-ai-config.sh claude    # Solo Claude Code
./scripts/sync-ai-config.sh all       # Todos los CLIs

# Gestión de skills
./scripts/add-skill.sh list           # Ver disponibles
./scripts/add-skill.sh gentleman react-19  # Instalar skill
./scripts/sync-skills.sh validate     # Validar formato

# CI Local (para probar en proyectos)
./.ci-local/ci-local.sh quick         # Lint + compile
./.ci-local/ci-local.sh full          # CI completo en Docker
./.ci-local/ci-local.sh shell         # Debug interactivo
```

## Stacks Soportados

Auto-detectados por archivo de build:

| Stack | Archivo | Lint | Test |
|-------|---------|------|------|
| Java/Gradle | build.gradle | spotlessCheck | ./gradlew test |
| Java/Maven | pom.xml | spotless:check | ./mvnw test |
| Node.js | package.json | npm lint | npm test |
| Python | pyproject.toml | ruff | pytest |
| Go | go.mod | golangci-lint | go test |
| Rust | Cargo.toml | clippy | cargo test |

## Workflows Reutilizables

Los proyectos usan workflows de este repo:

```yaml
# En tu proyecto: .github/workflows/ci.yml
jobs:
  build:
    uses: JNZader/project-starter-framework/.github/workflows/reusable-build-java.yml@main
    with:
      java-version: '21'
```

## Convenciones

### Commits (Conventional)

```
feat(scope): add feature
fix(scope): fix bug
docs(scope): update docs
refactor(scope): refactor code
chore(scope): maintenance
```

### Branches

```
feature/descripcion
fix/descripcion
docs/descripcion
```

## Archivos Clave

| Archivo | Propósito |
|---------|-----------|
| `scripts/setup-global.sh` | Setup global de AI CLIs |
| `templates/global/` | Templates para setup-global.sh |
| `.ai-config/AUTO_INVOKE.md` | Reglas de auto-carga de skills |
| `.ci-local/semgrep.yml` | Reglas de seguridad |
| `templates/README.md` | Documentación de templates |
| `optional/README.md` | Módulos opcionales |
| `tests/framework.bats` | Tests del framework (45 tests) |
| `tests/setup-global.bats` | Tests de setup-global.sh (36 tests) |
