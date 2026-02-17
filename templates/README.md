# CI Templates

Templates de CI mínimos para ahorrar minutos.

## Filosofía

1. **CI remoto mínimo**: Solo build verification en PRs
2. **CI local completo**: Tests, lint, security (con `.ci-local/`)
3. **Releases en tags**: Docker/publish solo en version tags
4. **Sin schedules**: Nada automático que consuma minutos

## GitHub Actions

### Uso de Reusable Workflows

Los proyectos llaman a los workflows de este repo:

```yaml
# Tu proyecto: .github/workflows/ci.yml
jobs:
  build:
    uses: JNZader/project-starter-framework/.github/workflows/reusable-build-java.yml@main
    with:
      java-version: '21'
```

### Templates disponibles

| Template | Stack | Copiar a |
|----------|-------|----------|
| `github/ci-java.yml` | Java/Gradle | `.github/workflows/ci.yml` |
| `github/ci-node.yml` | Node.js | `.github/workflows/ci.yml` |
| `github/ci-python.yml` | Python | `.github/workflows/ci.yml` |
| `github/ci-go.yml` | Go | `.github/workflows/ci.yml` |
| `github/ci-rust.yml` | Rust | `.github/workflows/ci.yml` |
| `github/ci-monorepo.yml` | Multi-servicio | `.github/workflows/ci.yml` |
| `github/dependabot-automerge.yml` | Auto-merge patches | `.github/workflows/dependabot-automerge.yml` |

Todos incluyen:
- **Concurrency control**: Cancela runs anteriores del mismo PR
- **Path filtering**: Ignora cambios en docs/markdown
- **Manual trigger**: Opción para ejecutar tests bajo demanda

### Reusable Workflows

| Workflow | Descripción | Minutos aprox |
|----------|-------------|---------------|
| `reusable-build-java.yml` | Java/Gradle build | ~3 min |
| `reusable-build-node.yml` | Node.js build | ~2 min |
| `reusable-build-python.yml` | Python build | ~2 min |
| `reusable-build-go.yml` | Go build | ~2 min |
| `reusable-build-rust.yml` | Rust build | ~3 min |
| `reusable-docker.yml` | Docker build & push | ~5 min |
| `reusable-release.yml` | Semantic release | ~2 min |

## GitLab CI

### Templates disponibles

| Template | Stack | Copiar a |
|----------|-------|----------|
| `gitlab/gitlab-ci-java.yml` | Java/Gradle | `.gitlab-ci.yml` |
| `gitlab/gitlab-ci-node.yml` | Node.js | `.gitlab-ci.yml` |
| `gitlab/gitlab-ci-python.yml` | Python | `.gitlab-ci.yml` |
| `gitlab/gitlab-ci-go.yml` | Go | `.gitlab-ci.yml` |
| `gitlab/gitlab-ci-rust.yml` | Rust | `.gitlab-ci.yml` |
| `gitlab/gitlab-ci-monorepo.yml` | Multi-servicio | `.gitlab-ci.yml` |

## Woodpecker CI

### Templates disponibles

| Template | Stack | Copiar a |
|----------|-------|----------|
| `woodpecker/woodpecker-java.yml` | Java/Gradle | `.woodpecker.yml` |
| `woodpecker/woodpecker-node.yml` | Node.js | `.woodpecker.yml` |
| `woodpecker/woodpecker-python.yml` | Python | `.woodpecker.yml` |
| `woodpecker/woodpecker-go.yml` | Go | `.woodpecker.yml` |
| `woodpecker/woodpecker-rust.yml` | Rust | `.woodpecker.yml` |

### Monorepo

Woodpecker soporta monorepos nativamente: cada `.yml` en `.woodpecker/` es un workflow independiente.

```bash
# Copiar directorio completo
cp -r templates/woodpecker/monorepo/ .woodpecker/
# Ajustar paths y stacks según tu proyecto
```

## Instalación Rápida

### Opción 1: Copiar template

```bash
# GitHub Actions - Java project
cp templates/github/ci-java.yml .github/workflows/ci.yml

# GitLab CI - Java project
cp templates/gitlab/gitlab-ci-java.yml .gitlab-ci.yml

# Woodpecker CI - Java project
cp templates/woodpecker/woodpecker-java.yml .woodpecker.yml
```

### Opción 2: Script automático

```bash
# El script init-project.sh ya configura todo (incluye selección de CI provider)
./scripts/init-project.sh
```

## Parámetros Comunes

### Java

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| `java-version` | `'21'` | 17, 21, 25 |
| `run-tests` | `false` | Ejecutar tests |
| `run-spotless` | `true` | Verificar formato |
| `gradle-args` | `''` | Args adicionales |

### Node.js

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| `node-version` | `'20'` | 18, 20, 22 |
| `package-manager` | `'npm'` | npm, yarn, pnpm |
| `run-tests` | `false` | Ejecutar tests |
| `run-lint` | `true` | Ejecutar lint |

### Python

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| `python-version` | `'3.12'` | 3.10, 3.11, 3.12 |
| `package-manager` | `'pip'` | pip, poetry, uv |
| `run-tests` | `false` | Ejecutar tests |
| `run-lint` | `true` | Ejecutar ruff |

### Rust

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| `toolchain` | `'stable'` | stable, beta, nightly |
| `run-tests` | `false` | Ejecutar tests |
| `run-clippy` | `true` | Ejecutar clippy |
| `run-fmt` | `true` | Verificar formato |

## Ejemplo Completo

### Proyecto Java con Docker

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

---
# .github/workflows/release.yml
name: Release

on:
  push:
    tags: ['v*.*.*']

jobs:
  docker:
    uses: JNZader/project-starter-framework/.github/workflows/reusable-docker.yml@main
    with:
      dockerfile: './Dockerfile'
      platforms: 'linux/amd64,linux/arm64'
```

## Consumo Estimado

Los templates ejecutan CI en dos escenarios:

| Evento | Qué ejecuta | Minutos aprox |
|--------|-------------|---------------|
| Push a main | Build + lint | ~1-2 min |
| Pull Request | Build + lint + tests | ~3-5 min |
| Release (tag) | Docker build & push | ~8 min |
| Manual (workflow_dispatch) | Configurable | Variable |

**Estrategia de triggers:**
- **Push a main**: Verificación rápida post-merge (build + lint únicamente)
- **Pull Requests**: CI completo para validación antes de merge
- **Tags**: Publicación de releases con Docker

**Free tier mensual:**
- GitHub: 2,000 min → ~600+ PRs (o ~1000+ pushes)
- GitLab: 400 min → ~130+ PRs
- Woodpecker: Self-hosted, sin limite de minutos

## Dependency Management

### Renovate

Para actualización automática de dependencias con Renovate:

```bash
cp templates/renovate.json renovate.json
```

Características:
- Updates semanales (lunes 9am)
- Automerge para patches
- Agrupa dependencias por ecosistema
- Alertas de vulnerabilidad con automerge

### Dependabot

Alternativa nativa de GitHub. Se configura automaticamente con `init-project.sh`:

```bash
# Automatico: init-project.sh genera dependabot.yml con el stack detectado
./scripts/init-project.sh

# Manual:
cp templates/dependabot.yml .github/dependabot.yml
# Descomentar secciones segun tu stack
```

### Dependabot Auto-Merge

Auto-aprueba y mergea PRs de Dependabot para patch updates:

```bash
cp templates/github/dependabot-automerge.yml .github/workflows/dependabot-automerge.yml
```

Requisito: habilitar "Allow auto-merge" en Settings > General del repo.

### Community Files (Issue/PR Templates)

`init-project.sh` copia automaticamente cuando se elige GitHub Actions:
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

## Semantic Release

### .releaserc

Configuración para semantic-release:

```bash
cp .releaserc tu-proyecto/.releaserc
```

Incluye:
- Conventional commits
- CHANGELOG automático
- Release notes generadas
- Tags semánticos

## Monorepo

Para proyectos con múltiples servicios:

```bash
cp templates/github/ci-monorepo.yml .github/workflows/ci.yml
```

Características:
- Detección de cambios por directorio
- Build selectivo (solo lo que cambió)
- Soporte para frontend + backend
- Trigger manual por servicio
