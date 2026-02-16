# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Modulo Engram para memoria persistente de agentes AI (MCP server)
- Modulo GHAGGA para code review automatizado multi-agente
- Reusable workflow para integracion GHAGGA
- Skill `ghagga-review` para patrones de code review AI
- Verificacion de checksum SHA256 en install-engram.sh
- Input `lint-fail-on-error` configurable en todos los build workflows
- Deteccion de `uv` como package manager Python en CI-Local
- Deteccion de staleness de imagenes Docker en CI-Local
- Trigger `push` en main para todos los CI templates de GitHub
- Trigger merge_request para todos los CI templates de GitLab
- GitLab CI templates for Go and Python
- PowerShell scripts: `add-skill.ps1`, `sync-skills.ps1`
- Security scanning workflow template
- Monorepo CI template with change detection
- Renovate and Dependabot configuration templates
- `.releaserc` for semantic versioning

### Fixed
- Vulnerabilidad de expression injection en reusable-ghagga-review.yml (CRITICAL)
- Vulnerabilidad de expression injection en todos los reusable build workflows
- Bug `local` keyword fuera de funcion en init-project.sh
- Path traversal en `remove_skill()` de add-skill.sh
- Compatibilidad bash 3.x en macOS (${var,,} y ${var^})
- Compatibilidad `sed -i` entre GNU y BSD (macOS)
- Conflicto `rules:` + `only:` en gitlab-ci-python.yml
- Symlinks en Windows (fallback a copy)
- Frontmatter YAML stripping incorrecto en sync-ai-config.sh
- Duplicado de header "Frontend" en sync-skills.sh
- Numeracion de pasos [0/3] a [1/3] en pre-commit hook
- PowerShell `-or` operator bugs in `ci-local.ps1` and `init-project.ps1`
- `local` keyword used outside function in `ci-local.sh`
- `grep -oP` portability issue for macOS
- Command injection risk in `ci-local.ps1`

### Changed
- Todos los reusable workflows ahora usan env vars en vez de inline ${{ inputs }}
- Agregado `permissions: contents: read` a todos los workflows
- Docker mount read-only en CI-Local (quick/full modes)
- Semgrep usa reglas locales (.ci-local/semgrep.yml) en vez de --config=auto
- Patrones de atribucion AI mas especificos para evitar falsos positivos
- Puertos Docker de GHAGGA bound a 127.0.0.1 solamente
- Password PostgreSQL requiere configuracion explicita
- golangci-lint pinned a v1.62
- Imagenes Docker de Rust pinned a 1.83-slim
- tagFormat explicito "v${version}" en .releaserc
- Made VibeKanban optional (moved to `optional/` directory)
- Improved CLAUDE.md with framework-specific instructions
- Enhanced `.gitignore.template` with more patterns
- Expanded Semgrep security rules

### Security
- Verificacion SHA256 de binarios descargados (install-engram.sh)
- Random delimiters para GITHUB_OUTPUT heredocs
- Retry logic con backoff en GHAGGA API calls
- Health checks en docker-compose de GHAGGA
- Credenciales en .gitignore alineadas con .gitignore.template

## [2.0.0] - 2024-02-10

### Added
- AI Config system with 78+ specialized agents
- 40+ reusable skills for multiple frameworks
- Auto-invoke skill loading based on file context
- Support for Claude Code, OpenCode, Cursor, Aider
- Windows PowerShell scripts for all tools
- Reusable GitHub Actions workflows (Java, Node, Python, Go, Rust, Docker, Release)
- GitLab CI templates (Java, Node, Rust)
- Interactive module selection in init-project script

### Changed
- Restructured to modular architecture
- Made VibeKanban optional
- Improved cross-platform compatibility

### Removed
- Forced VibeKanban dependency

## [1.0.0] - 2024-01-01

### Added
- Initial release
- CI-Local system with Docker simulation
- GitHub Actions templates
- GitLab CI templates
- VibeKanban integration
- Git hooks (pre-commit, commit-msg, pre-push)
- AI attribution blocker
