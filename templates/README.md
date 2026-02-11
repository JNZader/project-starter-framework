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
| `github/ci-rust.yml` | Rust | `.github/workflows/ci.yml` |

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
| `gitlab/gitlab-ci-rust.yml` | Rust | `.gitlab-ci.yml` |

## Instalación Rápida

### Opción 1: Copiar template

```bash
# Java project
cp templates/github/ci-java.yml .github/workflows/ci.yml

# Editar para tu proyecto
```

### Opción 2: Script automático

```bash
# El script init-project.sh ya configura todo
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

Con esta configuración:

| Acción | Minutos |
|--------|---------|
| PR a main | ~3 min |
| Push a main | 0 min |
| Release (tag) | ~8 min |

**Free tier mensual:**
- GitHub: 2,000 min → ~600+ PRs
- GitLab: 400 min → ~130+ PRs
