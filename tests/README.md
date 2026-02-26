# Tests

## Requisitos

- [Bats](https://github.com/bats-core/bats-core) para tests bash (81 tests)
- [Pester](https://pester.dev/) para tests PowerShell (cross-platform)
- Python 3 (para tests de JSON merge y frontmatter)

## Instalar Bats

```bash
# Opción 1: Via npm
npm install -g bats

# Opción 2: Desde source (sin npm)
git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
/tmp/bats-core/install.sh ~/.local
```

## Ejecutar

```bash
# Todos los tests (81 total)
bats tests/

# Framework tests (45 tests)
bats tests/framework.bats

# Setup-global tests (36 tests)
bats tests/setup-global.bats

# Validar estructura del framework
./scripts/validate-framework.sh
```

## Suites de test

### `framework.bats` (45 tests)

| Categoría | Tests | Qué valida |
|-----------|-------|------------|
| Library | 6 | `detect_stack`, `sed_inplace`, `escape_sed`, `backup_if_exists` |
| Stack detection | 7 | Java/Gradle, Maven, Node (npm/pnpm/yarn), Python (pip/uv/poetry), Go, Rust |
| Structure | 4 | Directorios core, version file, semver format |
| Scripts | 2 | `lib/common.sh` sourcing, `set -e` en todos los scripts |
| Frontmatter | 4 | Agents + skills: YAML válido, `name` kebab-case, `description` requerido |
| Workflows | 3 | `workflow_call` trigger, permissions block, expression injection |
| Templates | 1 | Cada provider tiene al menos un template |
| sync-ai-config | 4 | Merge mode, config.yaml targets, .skillignore, commands sync |
| validate-framework | 2 | Invalid agent name detection, SKILL.md scope |
| Hooks | 6 | Hook files existence, AI attribution blocking, clean commit |
| PowerShell | 1 | `lib/Common.psm1` counterpart |

### `setup-global.bats` (36 tests)

| Categoría | Tests | Qué valida |
|-----------|-------|------------|
| Help & flags | 2 | `--help`, unknown flags |
| Templates | 4 | Files existence, TOML structure, JSON validity |
| Dry-run | 2 | No side effects, no backups |
| CLI filtering | 6 | `--clis=claude`, `--clis=gemini`, etc., multiple CLIs |
| Feature filtering | 2 | `--features=sdd`, `--features=commands` |
| JSON merge | 4 | Create from template, preserve + add keys, hook dedup, backups |
| Markdown merge | 3 | New file, replace marker, append |
| Codex create-if-absent | 2 | Create new, skip existing |
| SDD content | 3 | 8 commands, copilot agent, gemini commands |
| Idempotency | 2 | No duplicates on re-run, no duplicate fileNames |
| Smoke | 3 | Full run creates dirs, shows summary, doctor passes |
