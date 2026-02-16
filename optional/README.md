# Optional Modules

> Modulos opcionales que puedes agregar a tu proyecto.

## Modulos Disponibles

### Memoria de Proyecto

| Modulo | Descripcion | Cuando usar |
|--------|-------------|-------------|
| `obsidian-brain/` | Vault Obsidian + Kanban + Dataview + memoria estructurada **(RECOMENDADO)** | Proyectos de cualquier tamano, workflow visual, queries automaticas |
| `engram/` | Memoria persistente para agentes AI via MCP server **(NUEVO)** | Agentes AI que necesitan recordar entre sesiones |
| `vibekanban/` | Oleadas paralelas + memoria estructurada **(legacy)** | Proyectos existentes que ya lo usan |
| `memory-simple/` | Solo un archivo NOTES.md | Proyectos pequenos, solo necesitas notas |

### Code Review

| Modulo | Descripcion | Cuando usar |
|--------|-------------|-------------|
| `ghagga/` | AI code review multi-agente para GitHub PRs **(NUEVO)** | Equipos que quieren review automatico con LLMs |

## Instalacion

### Obsidian Brain (recomendado)

```bash
# Copiar estructura de memoria y config Obsidian
cp -r optional/obsidian-brain/.project tu-proyecto/
cp -r optional/obsidian-brain/.obsidian tu-proyecto/

# Copiar scripts de oleadas
cp optional/obsidian-brain/new-wave.* tu-proyecto/scripts/

# Agregar lineas al .gitignore
cat optional/obsidian-brain/.obsidian-gitignore-snippet.txt >> tu-proyecto/.gitignore
```

Luego instalar plugins desde Obsidian: Kanban, Dataview, Templater.

### Engram (memoria AI)

```bash
# Instalar binario
./optional/engram/install-engram.sh

# Copiar config MCP (reemplazar __PROJECT_NAME__)
cp optional/engram/.mcp-config-snippet.json tu-proyecto/.mcp.json

# Agregar al .gitignore
cat optional/engram/.gitignore-snippet.txt >> tu-proyecto/.gitignore
```

Engram complementa a obsidian-brain: uno es para humanos (docs, kanban), el otro para agentes AI (patrones, bugfixes, contexto).

### GHAGGA (code review)

```bash
# Opcion 1: Solo workflow de GitHub Actions
./optional/ghagga/setup-ghagga.sh --workflow

# Opcion 2: Deploy local con Docker
./optional/ghagga/setup-ghagga.sh --docker

# Opcion 3: Setup interactivo
./optional/ghagga/setup-ghagga.sh
```

Requiere configurar `GHAGGA_URL` y `GHAGGA_TOKEN` en GitHub repo settings.

### VibeKanban (legacy)

```bash
# Copiar estructura de memoria
cp -r optional/vibekanban/.project tu-proyecto/

# Copiar scripts de oleadas
cp optional/vibekanban/new-wave.* tu-proyecto/scripts/
```

### Memory Simple

```bash
cp -r optional/memory-simple/.project tu-proyecto/
```

## Combinaciones Recomendadas

| Caso de uso | Modulos |
|-------------|---------|
| Solo developer | `obsidian-brain` + `engram` |
| Equipo pequeno | `obsidian-brain` + `engram` + `ghagga` |
| Proyecto minimo | `memory-simple` |
| Maximo AI | `obsidian-brain` + `engram` + `ghagga` |

## O ninguno

Si no necesitas modulos opcionales, simplemente no copies nada de `optional/`.

El framework funciona perfectamente solo con:
- `.ci-local/` - CI local
- `.ai-config/` - Configuracion AI
- `templates/` - CI templates
