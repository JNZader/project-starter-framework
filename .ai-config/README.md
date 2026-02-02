# AI Configuration (Agnóstico)

> Configuración centralizada de agentes, skills y hooks para múltiples AI CLIs.

---

## Compatibilidad

| CLI | Soporte | Configuración |
|-----|---------|---------------|
| **Claude Code** | ✅ Completo | `.claude/` auto-generado |
| **OpenCode** | ✅ Completo | `AGENTS.md` auto-generado |
| **Aider** | ✅ Parcial | `.aider.conf.yml` |
| **Cursor** | ✅ Parcial | `.cursorrules` |
| **Continue.dev** | ✅ Parcial | `config.json` |

---

## Estructura

```
.ai-config/
├── README.md                    # Esta documentación
│
├── agents/                      # 70+ Agentes organizados por categoría
│   ├── _TEMPLATE.md             # Template para crear agentes
│   ├── business/                # Análisis de negocio y producto (6 agentes)
│   ├── creative/                # Diseño y UX (1 agente)
│   ├── data-ai/                 # Data Science y AI (6 agentes)
│   ├── development/             # Desarrollo de software (14+ agentes)
│   ├── infrastructure/          # DevOps e Infraestructura (7 agentes)
│   ├── quality/                 # Testing y Calidad (8+ agentes)
│   ├── specialized/             # Especializados (20+ agentes)
│   └── orchestrator.md          # Orquestador central
│
├── skills/                      # Skills (Gentleman-Skills compatible)
│   ├── _TEMPLATE.md             # Template para crear skills
│   ├── frontend/                # UI/Frontend
│   ├── backend/                 # Backend & APIs
│   ├── database/                # Databases & Storage
│   ├── infrastructure/          # DevOps/Infra
│   ├── data-ai/                 # Data/AI/ML
│   ├── testing/                 # Testing & QA
│   ├── mobile/                  # Mobile
│   ├── workflow/                # Workflow & Tools
│   ├── docs/                    # Documentation & Templates
│   ├── other/                   # Misc/IoT/Systems
│   └── references/              # Documentación de referencia
│       ├── hooks-patterns.md
│       ├── mcp-servers.md
│       ├── plugins-reference.md
│       ├── skills-reference.md
│       └── subagent-templates.md
│
├── hooks/                       # Hooks de eventos
│   ├── _TEMPLATE.md             # Template para crear hooks
│   └── block-dangerous-commands.md # Bloqueo de comandos peligrosos
│
└── prompts/                     # System prompts reutilizables
    └── base.md                  # Prompt base del proyecto
```

---

## Auto-Invoke System (Arquitectura Alan/Prowler)

Basado en la arquitectura propuesta por [Gentleman Programming](https://github.com/Gentleman-Programming/Gentleman-Skills).

### Componentes

| Archivo | Propósito |
|---------|-----------|
| `AUTO_INVOKE.md` | Tabla de mapeo acción → skill (cuándo cargar qué) |
| `SKILLS_SUMMARY.md` | Resumen auto-generado de skills disponibles |
| `sync-skills.sh` | Script para sincronizar skills y crear symlinks |

### Cómo funciona

1. **Detección automática**: Cuando el usuario pide algo, el orquestador consulta `AUTO_INVOKE.md`
2. **Carga de skill**: Se carga el skill correspondiente según la acción y carpeta (scope)
3. **Cross-references**: Cada skill tiene `## Related Skills` para cargar skills complementarios

### Ejemplo

```
Usuario: "Crea un componente de tabla con paginación"

Orquestador:
1. Detecta "componente" → Carga frontend-web
2. Detecta "tabla" → Carga mantine-ui (tiene DataTable)
3. Si hay data fetching → Carga tanstack-query
4. Ejecuta con contexto de los 3 skills
```

### Scripts disponibles

```bash
# Listar skills con metadata
./scripts/sync-skills.sh list

# Validar formato de skills
./scripts/sync-skills.sh validate

# Crear symlinks multi-IDE (CLAUDE.md, GEMINI.md, etc.)
./scripts/sync-skills.sh symlinks

# Generar resumen de skills
./scripts/sync-skills.sh summary

# Todo junto
./scripts/sync-skills.sh all
```

---

## Quick Start

### 1. Sincronizar con tu CLI

```bash
# Generar configuración para tu CLI
./scripts/sync-ai-config.sh claude    # Para Claude Code
./scripts/sync-ai-config.sh opencode  # Para OpenCode
./scripts/sync-ai-config.sh all       # Para todos
```

### 2. Agregar skill de Gentleman-Skills

```bash
# Listar skills disponibles
./scripts/add-skill.sh list

# Instalar skill específico
./scripts/add-skill.sh gentleman react-19
./scripts/add-skill.sh gentleman typescript
```

### 3. Crear agente personalizado

```bash
# Copiar template
cp .ai-config/agents/_TEMPLATE.md .ai-config/agents/mi-agente.md

# Editar y sincronizar
./scripts/sync-ai-config.sh
```

---

## Agentes por Categoría

### Business (6 agentes)
| Agente | Uso |
|--------|-----|
| `api-designer` | Diseño REST, GraphQL, OpenAPI |
| `business-analyst` | Análisis de procesos y workflows |
| `product-strategist` | Estrategia y roadmap de producto |
| `project-manager` | Sprint planning y coordinación |
| `requirements-analyst` | Requisitos y user stories |
| `technical-writer` | Documentación técnica |

### Development (14 agentes)
| Agente | Lenguaje/Framework |
|--------|-------------------|
| `angular-expert` | Angular 17+ |
| `backend-architect` | Arquitectura backend |
| `database-specialist` | SQL/NoSQL |
| `frontend-specialist` | Frontend general |
| `fullstack-engineer` | Full-stack |
| `golang-pro` | Go |
| `java-enterprise` | Java/Spring Boot |
| `javascript-pro` | JavaScript/Node.js |
| `nextjs-pro` | Next.js 14+ |
| `python-pro` | Python |
| `react-pro` | React |
| `rust-pro` | Rust |
| `typescript-pro` | TypeScript |
| `vue-specialist` | Vue.js 3 |

### Infrastructure (7 agentes)
| Agente | Uso |
|--------|-----|
| `cloud-architect` | AWS, GCP, Azure |
| `deployment-manager` | Deployments y releases |
| `devops-engineer` | CI/CD, containers |
| `incident-responder` | Troubleshooting producción |
| `kubernetes-expert` | K8s y cloud-native |
| `monitoring-specialist` | Observabilidad |
| `performance-engineer` | Optimización |

### Quality (7 agentes)
| Agente | Uso |
|--------|-----|
| `accessibility-auditor` | WCAG compliance |
| `code-reviewer` | Code review sistemático |
| `dependency-manager` | Seguridad de dependencias |
| `e2e-test-specialist` | Playwright/Cypress |
| `performance-tester` | Load testing |
| `security-auditor` | Seguridad OWASP |
| `test-engineer` | Testing general |

### Data & AI (6 agentes)
| Agente | Uso |
|--------|-----|
| `ai-engineer` | LLMs, ML production |
| `analytics-engineer` | dbt, data modeling |
| `data-engineer` | ETL, pipelines |
| `data-scientist` | ML, estadística |
| `mlops-engineer` | ML pipelines |
| `prompt-engineer` | Prompt optimization |

### Specialized (12+ agentes)
Incluye blockchain, mobile, game dev, healthcare, fintech, e-commerce, y más.

---

## Skills Incluidos

| Skill | Descripción |
|-------|-------------|
| `frontend-design` | Diseño frontend con estética distintiva, evita "AI slop" |
| `claude-md-improver` | Auditoría y mejora de archivos CLAUDE.md |
| `claude-automation-recommender` | Recomendaciones de automatización para Claude Code |
| `ci-local-guide` | Guía completa de CI-Local |
| `wave-workflow` | Flujo de trabajo con oleadas paralelas |
| `git-workflow` | Guía de Git workflow y branching |

---

## Gentleman-Skills Integration

Compatible con [Gentleman-Skills](https://github.com/Gentleman-Programming/Gentleman-Skills):

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

### Skills Populares (Gentleman-Skills)

| Skill | Uso |
|-------|-----|
| `react-19` | React 19 patterns |
| `typescript` | TypeScript best practices |
| `playwright` | E2E testing |
| `angular` | Angular patterns |
| `vercel-ai-sdk-5` | AI integrations |
| `tailwindcss-4` | Tailwind CSS |

---

## Crear Contenido

### Agentes

Ver `.ai-config/agents/_TEMPLATE.md` para el formato completo.

```markdown
---
name: mi-agente
description: Descripción del agente
trigger: Cuándo usar este agente
tools: [Bash, Read, Write, Edit]
config:
  model: sonnet
  max_turns: 10
---

# Instrucciones del agente
...
```

### Skills

Compatible con Gentleman-Skills format:

```markdown
---
name: mi-skill
description: >
  Descripción.
  Trigger: contexto de uso
metadata:
  author: tu-usuario
  version: "1.0"
---

## When to Use
- Condición 1
- Condición 2

## Critical Patterns
...
```

### Hooks

```markdown
---
event: PreToolUse | PostToolUse | Stop
tools: [Bash, Write]  # opcional: filtrar por herramienta
---

# Lógica del hook
...
```

---

## Sincronización Automática

El script `sync-ai-config.sh` genera archivos específicos para cada CLI:

| CLI | Archivo generado |
|-----|------------------|
| Claude Code | `CLAUDE.md` |
| OpenCode | `AGENTS.md` |
| Aider | `.aider.conf.yml` |
| Cursor | `.cursorrules` |

---

*Compatible con Gentleman-Skills v1.0 • 78+ agentes incluidos*
