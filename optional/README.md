# Optional Modules

> Modulos opcionales que puedes agregar a tu proyecto.

## Modulos Disponibles

| Modulo | Descripcion | Cuando usar |
|--------|-------------|-------------|
| `obsidian-brain/` | Vault Obsidian + Kanban + Dataview + memoria estructurada **(RECOMENDADO)** | Proyectos de cualquier tamano, workflow visual, queries automaticas |
| `vibekanban/` | Oleadas paralelas + memoria estructurada **(legacy)** | Proyectos existentes que ya lo usan |
| `memory-simple/` | Solo un archivo NOTES.md | Proyectos pequenos, solo necesitas notas |

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

## O ninguno

Si no necesitas memoria de proyecto, simplemente no copies nada de `optional/`.

El framework funciona perfectamente solo con:
- `.ci-local/` - CI local
- `.ai-config/` - Configuracion AI
- `templates/` - CI templates
