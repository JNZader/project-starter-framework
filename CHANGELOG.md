## [1.0.1](https://github.com/JNZader/project-starter-framework/compare/v1.0.0...v1.0.1) (2026-02-17)

### Bug Fixes

* critical run_in_ci injection, shared logging, script hardening and docs ([e2fadaa](https://github.com/JNZader/project-starter-framework/commit/e2fadaae7c94786c138e2bd245b1b4a66fb87f2a))

## 1.0.0 (2026-02-17)

### ⚠ BREAKING CHANGES

* VibeKanban moved to optional/

Structure changes:
- Move .project/ to optional/vibekanban/.project/
- Move new-wave.sh/ps1 to optional/vibekanban/
- Add optional/memory-simple/ as lightweight alternative
- Add optional/README.md with installation instructions

Core components (always included):
- .ci-local/ - Local CI simulation
- .ai-config/ - AI CLI configuration (78+ agents)
- .github/workflows/ - Reusable CI workflows
- templates/ - CI templates for projects

Optional modules:
- vibekanban/ - Wave-based parallel workflow
- memory-simple/ - Simple NOTES.md only

Updated:
- README.md - New modular structure, version 2.0.0
- CLAUDE.md - Removed VibeKanban-specific content

### Features

* add doctor, dry-run, agents catalog, auto-versioning and Semgrep Docker fallback ([c02b7c8](https://github.com/JNZader/project-starter-framework/commit/c02b7c8ec940784e06259175b5fb956648b7d5f6))
* add monorepo template, semantic-release, and dependency management ([f9deb8a](https://github.com/JNZader/project-starter-framework/commit/f9deb8a5ffd6e93ccb13653234fb8918de06076c))
* **ci:** add reusable GitHub Actions workflows and templates ([de72bc6](https://github.com/JNZader/project-starter-framework/commit/de72bc63a7c8d23ca6dae5ae9409770c4aebd96d))
* comprehensive improvements from multi-agent analysis ([83674fc](https://github.com/JNZader/project-starter-framework/commit/83674fc370cdb9505b25db220be2e410a73a0f7e))
* **optional:** add Engram and GHAGGA integration modules ([609eff9](https://github.com/JNZader/project-starter-framework/commit/609eff9e45f3d80983897518a9d63fcd6a1fbe2c))
* **optional:** add obsidian-brain module with Kanban, Dataview and Templater ([c244ba2](https://github.com/JNZader/project-starter-framework/commit/c244ba29905c65a9101a9bb7b026f1a7cd6e14b4))
* **templates:** add Dependabot with auto-merge and community files ([48a16f7](https://github.com/JNZader/project-starter-framework/commit/48a16f7b560432dac87b196e66819c2de49958b7))
* **templates:** add Woodpecker CI support ([715b3f2](https://github.com/JNZader/project-starter-framework/commit/715b3f23f7e5e6aa84106904c0e3021dc19b22ce))

### Bug Fixes

* framework consistency fixes and missing templates ([c141d87](https://github.com/JNZader/project-starter-framework/commit/c141d879d0223e96d56793b2c47f6e7a4f4190a9))
* **obsidian-brain:** add missing configs and improve documentation ([f7ad8e0](https://github.com/JNZader/project-starter-framework/commit/f7ad8e09824a8a07d61abb85eda88f88e1914f2b))
* resolve critical bugs, harden CI defaults and improve robustness ([8a2b280](https://github.com/JNZader/project-starter-framework/commit/8a2b280a03e6a8ffb7f3f9c0db9224c6ee3e5e2b))
* resolve onboarding gate, PS1 parity, security validation and docs alignment ([a56430b](https://github.com/JNZader/project-starter-framework/commit/a56430b99b56e91a5a24e8501da9d3af9c0135cb))
* **security:** harden workflows, scripts and CI against injection and portability issues ([9811e62](https://github.com/JNZader/project-starter-framework/commit/9811e622bb4ed816edaecfa83c98a5b7d0733dcb))

### Refactoring

* **ai-config:** fix naming conventions, add missing metadata, sync inventory ([b1c100d](https://github.com/JNZader/project-starter-framework/commit/b1c100df7f2f19ae54d942a429b9c58e01379af9))
* extract shared libraries, add validation and test framework ([f0242fd](https://github.com/JNZader/project-starter-framework/commit/f0242fd6954fdc16725605bfb63349266c9ab202))
* modularize framework - make VibeKanban optional ([714b60a](https://github.com/JNZader/project-starter-framework/commit/714b60ad8a10fc9dda313fe318f2d83b3f0bf82b))
* reorganize skills by topic folders and agents to match structure ([08d12d5](https://github.com/JNZader/project-starter-framework/commit/08d12d59e932db2df3834bec1d496bd5110c3d6e))
* **skills:** remove apigen references and codegen-patterns skill ([97d4698](https://github.com/JNZader/project-starter-framework/commit/97d4698d87d34e6196264ff18c0a63f436627155))

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
