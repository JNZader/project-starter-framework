# Optional Modules

> Módulos opcionales que puedes agregar a tu proyecto.

## Módulos Disponibles

| Módulo | Descripción | Cuándo usar |
|--------|-------------|-------------|
| `vibekanban/` | Oleadas paralelas + memoria estructurada | Proyectos grandes, equipos, metodología estricta |
| `memory-simple/` | Solo un archivo NOTES.md | Proyectos pequeños, solo necesitas notas |

## Instalación

### VibeKanban (completo)

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
- `.ai-config/` - Configuración AI
- `templates/` - CI templates
