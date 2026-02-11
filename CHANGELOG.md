# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitLab CI templates for Go and Python
- PowerShell scripts: `add-skill.ps1`, `sync-skills.ps1`
- Security scanning workflow template
- Monorepo CI template with change detection
- Renovate and Dependabot configuration templates
- `.releaserc` for semantic versioning

### Fixed
- PowerShell `-or` operator bugs in `ci-local.ps1` and `init-project.ps1`
- `local` keyword used outside function in `ci-local.sh`
- `grep -oP` portability issue for macOS
- Command injection risk in `ci-local.ps1`

### Changed
- Made VibeKanban optional (moved to `optional/` directory)
- Improved CLAUDE.md with framework-specific instructions
- Enhanced `.gitignore.template` with more patterns
- Expanded Semgrep security rules

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
