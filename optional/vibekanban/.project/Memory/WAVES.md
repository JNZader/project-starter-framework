# Oleadas de Trabajo

> Registro de oleadas de tareas paralelas ejecutadas con VibeKanban

---

## Oleada Actual

**Numero:** 0
**Estado:** Ninguna activa
**Tareas:** -
**Branches:** -
**Inicio:** -

---

## Cómo usar oleadas

### 1. Analizar dependencias

```
Tareas disponibles:
- T-001: Setup monorepo          (sin deps)
- T-002: Configurar CI           (depende de T-001)
- T-003: Agregar linters         (depende de T-001)
- T-004: Docker compose          (sin deps)
- T-005: Integrar linters en CI  (depende de T-002, T-003)
```

### 2. Agrupar en oleadas

```
Oleada 1: T-001, T-004  (sin dependencias entre sí)
Oleada 2: T-002, T-003  (dependen solo de T-001)
Oleada 3: T-005         (depende de oleada 2)
```

### 3. Ejecutar

```bash
# Crear oleada
./scripts/new-wave.sh "T-001 T-004"

# Crear branches
./scripts/new-wave.sh --create-branches

# Trabajar en paralelo...

# Completar y merge
./scripts/new-wave.sh --complete
```

---

## Historial

| # | Tareas | Inicio | Fin | Estado |
|---|--------|--------|-----|--------|
| - | - | - | - | - |

---

## Tips

- **Máximo recomendado:** 5-7 tareas por oleada para mantener foco
- **Sin límite técnico:** El sistema soporta cualquier cantidad
- **Merge order:** Mergear a develop cuando todas las tareas de la oleada estén listas
- **Conflictos:** Si hay conflictos entre branches de la misma oleada, revisar dependencias

---

*Última actualización: [FECHA]*
