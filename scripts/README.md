# Scripts

> Scripts de automatización del proyecto

---

## Disponibles

| Script | Descripción | Windows |
|--------|-------------|---------|
| `init-project.sh/ps1` | Setup inicial del proyecto | ✓ |
| `sync-ai-config.sh/ps1` | Sincroniza config de AI CLIs | ✓ |
| `add-skill.sh/ps1` | Agrega skills de Gentleman-Skills | ✓ |
| `collect-skills.sh` | Importa skills desde otras herramientas/repos | - |
| `sync-skills.sh/ps1` | Valida y sincroniza skills | ✓ |
| `doctor.sh/ps1` | Diagnóstico del entorno y framework | ✓ |
| `validate-framework.sh/ps1` | Valida estructura y consistencia del framework | ✓ |
| `generate-agents-catalog.sh/ps1` | Genera catálogo AGENTS.md desde frontmatter | ✓ |

---

## init-project

Configura un proyecto nuevo:
- Inicializa git (si no existe)
- Configura hooks de CI-Local
- Detecta stack tecnológico
- Prepara memoria del proyecto

```bash
./scripts/init-project.sh   # Linux/Mac
.\scripts\init-project.ps1  # Windows
```

---

## sync-ai-config

Genera configuración para diferentes AI CLIs desde `.ai-config/`:

```bash
# Sin argumentos: lee targets de .ai-config/config.yaml
./scripts/sync-ai-config.sh

# Para Claude Code
./scripts/sync-ai-config.sh claude
./scripts/sync-ai-config.sh claude merge   # Safe-merge: append/update only the auto-generated section

# Para OpenCode
./scripts/sync-ai-config.sh opencode

# Para Cursor
./scripts/sync-ai-config.sh cursor

# Para Aider
./scripts/sync-ai-config.sh aider

# Para Gemini
./scripts/sync-ai-config.sh gemini

# Sincronizar slash commands para Claude
./scripts/sync-ai-config.sh commands

# Para todos
./scripts/sync-ai-config.sh all
```

### Archivos Generados

| CLI | Archivo |
|-----|---------|
| Claude Code | `CLAUDE.md` |
| OpenCode | `AGENTS.md` |
| Cursor | `.cursorrules` |
| Aider | `.aider.conf.yml` |
| Gemini CLI | `GEMINI.md` |
| Claude Commands | `.claude/commands/*` |

---

## add-skill

Agrega skills de [Gentleman-Skills](https://github.com/Gentleman-Programming/Gentleman-Skills):

```bash
# Listar skills disponibles
./scripts/add-skill.sh list

# Instalar skill
./scripts/add-skill.sh gentleman react-19
./scripts/add-skill.sh gentleman typescript
./scripts/add-skill.sh gentleman playwright

# Ver instalados
./scripts/add-skill.sh installed

# Remover skill
./scripts/add-skill.sh remove react-19
```

### Skills Populares

| Skill | Uso |
|-------|-----|
| `react-19` | React 19 patterns |
| `typescript` | TypeScript best practices |
| `playwright` | E2E testing |
| `angular` | Angular patterns |
| `vercel-ai-sdk-5` | AI integrations |
| `tailwindcss-4` | Tailwind CSS |

---

## collect-skills

Importa skills desde directorios externos o paths conocidos de otras herramientas AI:

```bash
# Importar desde directorio
./scripts/collect-skills.sh /tmp/new-skills workflow

# Importar desde target conocido
./scripts/collect-skills.sh --from claude workflow

# Ver targets conocidos
./scripts/collect-skills.sh list-targets
```

---

## sync-skills

Valida formato de skills y genera archivos multi-IDE:

```bash
# Listar todos los skills
./scripts/sync-skills.sh list

# Validar formato
./scripts/sync-skills.sh validate

# Audit de seguridad (prompt injection/exfiltration patterns)
./scripts/sync-skills.sh audit

# Generar archivos multi-IDE (CLAUDE.md, AGENTS.md, etc.)
./scripts/sync-skills.sh symlinks

# Generar resumen de skills
./scripts/sync-skills.sh summary

# Todo junto
./scripts/sync-skills.sh all
```

---

## doctor

Diagnóstico del entorno y del framework. Verifica:
- Herramientas requeridas (Git, Docker, Semgrep)
- Integridad de la estructura del framework
- Configuración del proyecto actual (hooks instalados, stack detectado)
- Permisos de archivos ejecutables

```bash
./scripts/doctor.sh          # Linux/Mac
.\scripts\doctor.ps1         # Windows
```

---

## validate-framework

Valida la estructura y consistencia interna del framework. Comprueba:
- Que todos los archivos referenciados existen
- Que los templates tienen el formato correcto
- Que los agentes y skills cumplen el esquema requerido
- Que los workflows son YAML válido

`validate-framework` usa `scripts/validate-frontmatter.py` (si Python está disponible) para validar frontmatter YAML de agentes/skills.

```bash
./scripts/validate-framework.sh
```

---

## generate-agents-catalog

Genera el archivo `AGENTS.md` (catálogo de agentes para OpenCode y otros CLIs) leyendo el frontmatter de cada agente en `.ai-config/agents/`:

```bash
./scripts/generate-agents-catalog.sh    # Linux/Mac
.\scripts\generate-agents-catalog.ps1  # Windows
```

El archivo generado incluye nombre, descripción y trigger de cada agente, organizado por categoría.

---

## Oleadas (via módulos opcionales)

Los siguientes scripts se instalan cuando se elige un módulo opcional de memoria de proyecto:

| Script | Descripción | Instalado con |
|--------|-------------|---------------|
| `new-wave.sh` | Gestión de oleadas de tareas | `obsidian-brain` o `vibekanban` |
| `new-wave.ps1` | Versión PowerShell | `obsidian-brain` o `vibekanban` |

### Uso de new-wave (si está instalado)

```bash
# Ver oleada actual
./scripts/new-wave.sh --list

# Crear nueva oleada
./scripts/new-wave.sh "T-001 T-002 T-003"

# Crear branches para tareas
./scripts/new-wave.sh --create-branches

# Completar oleada
./scripts/new-wave.sh --complete
```

---

## Agregar nuevos scripts

1. Crear `script-name.sh` (Linux/Mac)
2. Crear `script-name.ps1` (Windows)
3. Agregar documentación aquí
4. Hacer ejecutable: `chmod +x script-name.sh`
