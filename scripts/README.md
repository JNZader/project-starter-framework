# Scripts

> Scripts de automatización del proyecto

---

## Disponibles

| Script | Descripción | Windows |
|--------|-------------|---------|
| `init-project.sh/ps1` | Setup inicial del proyecto | ✓ |
| `sync-ai-config.sh/ps1` | Sincroniza config de AI CLIs | ✓ |
| `add-skill.sh/ps1` | Agrega skills de Gentleman-Skills | ✓ |
| `sync-skills.sh/ps1` | Valida y sincroniza skills | ✓ |

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
# Para Claude Code
./scripts/sync-ai-config.sh claude

# Para OpenCode
./scripts/sync-ai-config.sh opencode

# Para Cursor
./scripts/sync-ai-config.sh cursor

# Para Aider
./scripts/sync-ai-config.sh aider

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

## sync-skills

Valida formato de skills y genera archivos multi-IDE:

```bash
# Listar todos los skills
./scripts/sync-skills.sh list

# Validar formato
./scripts/sync-skills.sh validate

# Generar archivos multi-IDE (CLAUDE.md, AGENTS.md, etc.)
./scripts/sync-skills.sh symlinks

# Generar resumen de skills
./scripts/sync-skills.sh summary

# Todo junto
./scripts/sync-skills.sh all
```

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
