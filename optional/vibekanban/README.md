# VibeKanban Integration

> Metodología de oleadas paralelas con VibeKanban.

## Instalación

```bash
# Copiar a tu proyecto
cp -r optional/vibekanban/.project /path/to/your/project/
cp optional/vibekanban/new-wave.sh /path/to/your/project/scripts/
cp optional/vibekanban/new-wave.ps1 /path/to/your/project/scripts/
```

## Estructura

```
.project/
├── Memory/
│   ├── CONTEXT.md      # Estado actual (leer al inicio de sesión)
│   ├── DECISIONS.md    # ADRs (decisiones de arquitectura)
│   ├── BLOCKERS.md     # Problemas conocidos y soluciones
│   └── WAVES.md        # Oleadas de trabajo
└── Sessions/
    └── TEMPLATE.md     # Template para sesiones diarias
```

## Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PLANIFICACIÓN                               │
│  VibeKanban: Lista de tareas → Análisis dependencias → Oleadas      │
└─────────────────────────────────────────────────────────────────────┘
                                   ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      EJECUCIÓN POR OLEADAS                          │
│  Oleada 1: [T-001] [T-002] [T-003]  (paralelo, sin dependencias)   │
│                        ↓ merge all → develop                        │
│  Oleada 2: [T-004] [T-005]          (dependen de oleada 1)         │
│                        ↓ merge all → develop                        │
│  Release: develop → main                                            │
└─────────────────────────────────────────────────────────────────────┘
```

## Comandos

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

## Integración con AI CLIs

Al inicio de cada sesión, el AI debe leer:
1. `.project/Memory/CONTEXT.md` - Estado actual
2. `.project/Memory/WAVES.md` - Oleada en progreso

Agregar a tu CLAUDE.md:
```markdown
## Memoria del Proyecto

Leer al inicio de cada sesión:
- `.project/Memory/CONTEXT.md` - Estado actual
- `.project/Memory/WAVES.md` - Oleadas de trabajo
```
