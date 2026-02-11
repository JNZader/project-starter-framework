# Project Memory

> Archivos de memoria persistente para Claude Code y documentación del proyecto.

## Estructura

```
Memory/
├── CONTEXT.md    ← Estado actual del proyecto (leer al inicio)
├── DECISIONS.md  ← ADRs (Architecture Decision Records)
├── BLOCKERS.md   ← Problemas encontrados y soluciones
└── README.md     ← Este archivo
```

## Flujo de Trabajo

### Al iniciar sesión:
1. Leer `CONTEXT.md` para recordar estado
2. Revisar `BLOCKERS.md` para issues pendientes
3. Crear sesión en `../Sessions/YYYY-MM-DD.md`

### Durante la sesión:
4. Trabajar en tareas (VibeKanban)
5. Documentar blockers si aparecen
6. Registrar decisiones importantes como ADRs

### Al finalizar:
7. Actualizar `CONTEXT.md`
8. Completar sesión del día

## Compatible con Obsidian

Estos archivos usan links `[[archivo]]` compatibles con Obsidian para navegación.
