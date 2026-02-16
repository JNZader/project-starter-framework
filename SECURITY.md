# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| 1.x.x   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please create a private security advisory via GitHub's security tab or email the maintainer directly.

Include in your report:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You should receive a response within 48 hours.

## Security Best Practices

When using this framework:

### 1. Sensitive Files
- Keep `.env` files out of git (already in `.gitignore.template`)
- Never commit secrets to CLAUDE.md or other AI config files
- Review `.gitignore` before first commit

### 2. Git Hooks
- Review `.ci-local/hooks/` before installation
- Hooks execute local scripts with your permissions
- Can be bypassed with `--no-verify` (by design for emergencies)

### 3. Docker
- CI-Local builds Docker images locally
- Images are based on official language images
- Review generated Dockerfiles in `.ci-local/docker/`

### 4. Dependencies
- Enable Renovate or Dependabot for automatic updates
- Review dependency changes before merging
- Use `npm audit`, `pip-audit`, or equivalent for your stack

### 5. AI Configuration
- CLAUDE.md and similar files may contain project information
- These files are git-ignored by default
- Never include API keys or tokens in AI config files

### 6. Modulos Opcionales

#### Engram (MCP Server)
- Engram corre como servidor MCP local con acceso a archivos del proyecto
- Usa tags `<private>` para redactar contenido sensible
- La base de datos se almacena en `.engram/` (git-ignored)
- Revisar la variable `ENGRAM_PROJECT` antes de compartir configs

#### GHAGGA (Code Review)
- Requiere GitHub App con acceso al repositorio
- El webhook recibe todo el contenido del PR (revisar implicaciones de privacidad)
- Los proveedores LLM reciben fragmentos de codigo (verificar politicas de retencion)
- Usar deployment self-hosted para proyectos sensibles
- Configurar `GHAGGA_URL` y `GHAGGA_TOKEN` como secrets, nunca en codigo

## Known Security Considerations

### Git Hooks Execution
Git hooks run with your user permissions. The hooks in this framework:
- `pre-commit`: Runs linting and security checks
- `commit-msg`: Validates commit message format
- `pre-push`: Runs full CI simulation in Docker

### Docker Permissions
The CI-Local Docker containers:
- Run as non-root user `runner`
- Mount your project directory read-write
- Have network access (required for dependency downloads)

### Semgrep Security Scanning
The included Semgrep rules check for:
- Hardcoded secrets and credentials
- SQL injection patterns
- Command injection patterns
- Insecure cryptography usage

To add more rules, edit `.ci-local/semgrep.yml`.

## Security Checklist for New Projects

- [ ] Copied `.gitignore.template` to `.gitignore`
- [ ] No secrets in committed files
- [ ] Reviewed git hooks before enabling
- [ ] Enabled dependency update automation
- [ ] CI/CD secrets stored securely (not in code)
