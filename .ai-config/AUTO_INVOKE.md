# Auto-Invoke Rules

> Reglas de invocación automática de skills y agentes.
> **OBLIGATORIO:** Antes de realizar estas acciones, SIEMPRE carga la skill correspondiente.

---

## Skill Auto-Invoke Table

| Acción del Usuario | Skill a Cargar | Scope (Carpetas) |
|--------------------|----------------|------------------|
| Crear componente React/Astro | `frontend-web` | `src/`, `components/`, `pages/` |
| Crear componente Mantine UI | `mantine-ui` | `src/`, `components/` |
| Configurar Astro SSR | `astro-ssr` | `src/`, `astro.config.*` |
| Data fetching con React Query | `tanstack-query` | `src/`, `hooks/`, `api/` |
| Validar schemas/forms | `zod-validation` | `src/`, `schemas/`, `validators/` |
| Estado global Zustand | `zustand-state` | `src/`, `store/`, `stores/` |
| Crear endpoint Go/Chi | `chi-router` | `cmd/`, `internal/`, `api/` |
| Queries PostgreSQL con pgx | `pgx-postgres` | `internal/`, `repository/`, `db/` |
| Backend Go completo | `go-backend` | `cmd/`, `internal/`, `pkg/` |
| Crear endpoint FastAPI | `fastapi` | `src/`, `app/`, `api/` |
| Autenticación JWT | `jwt-auth` | `auth/`, `middleware/`, `security/` |
| Async Rust con Tokio | `tokio-async` | `src/`, `Cargo.toml` |
| IoT/MQTT messaging | `mqtt-rumqttc` | `src/`, `iot/`, `mqtt/` |
| Protocolo Modbus | `modbus-protocol` | `src/`, `industrial/`, `modbus/` |
| WebSockets real-time | `websockets` | `src/`, `ws/`, `realtime/` |
| Rust systems programming | `rust-systems` | `src/`, `Cargo.toml` |
| Time-series TimescaleDB | `timescaledb` | `db/`, `migrations/`, `sql/` |
| Cache Redis | `redis-cache` | `cache/`, `redis/`, `internal/` |
| SQLite embedded/mobile | `sqlite-embedded` | `db/`, `mobile/`, `offline/` |
| Analytics DuckDB | `duckdb-analytics` | `analytics/`, `data/`, `scripts/` |
| Deploy Kubernetes | `kubernetes` | `k8s/`, `deploy/`, `manifests/` |
| CI/CD DevOps | `devops-infra` | `.github/`, `ci/`, `docker/` |
| Docker containers | `docker-containers` | `Dockerfile*`, `docker-compose*` |
| Traefik routing | `traefik-proxy` | `traefik/`, `proxy/`, `ingress/` |
| Observability/tracing | `opentelemetry` | `observability/`, `telemetry/` |
| LangChain/LLM apps | `langchain` | `agents/`, `chains/`, `llm/` |
| AI/ML pipelines | `ai-ml` | `ml/`, `models/`, `training/` |
| ONNX model inference | `onnx-inference` | `models/`, `inference/`, `onnx/` |
| PyTorch training | `pytorch` | `training/`, `models/`, `nn/` |
| Scikit-learn ML | `scikit-learn` | `ml/`, `models/`, `sklearn/` |
| MLflow experiments | `mlflow` | `experiments/`, `mlruns/`, `mlflow/` |
| Vector databases/RAG | `vector-db` | `vectorstore/`, `embeddings/`, `rag/` |
| E2E tests Playwright | `playwright-e2e` | `tests/`, `e2e/`, `playwright/` |
| Unit tests Vitest | `vitest-testing` | `tests/`, `__tests__/`, `*.test.*` |
| Mobile Ionic/Capacitor | `mobile-ionic`, `ionic-capacitor` | `src/`, `mobile/`, `capacitor/` |
| Git workflow/branches | `git-workflow` | `.git/`, root |
| GitHub API/CLI | `git-github` | `.github/`, root |
| Technical documentation | `technical-docs` | `docs/`, `*.md` |
| Power BI reports | `powerbi` | `reports/`, `bi/`, `dashboards/` |

---

## Agent Auto-Invoke Table

| Contexto de Trabajo | Agente a Usar | Cuándo |
|---------------------|---------------|--------|
| Diseño de APIs | `api-designer` | Crear/diseñar REST, GraphQL, OpenAPI |
| Arquitectura backend | `backend-architect` | Diseño de servicios, microservicios |
| Frontend React | `react-pro` | Patterns avanzados React |
| Frontend Vue | `vue-specialist` | Vue 3, Composition API |
| Frontend Angular | `angular-expert` | Angular 17+, signals |
| TypeScript avanzado | `typescript-pro` | Tipos complejos, generics |
| Go development | `golang-pro` | Concurrencia, patterns Go |
| Rust systems | `rust-pro` | Memory safety, async Rust |
| Python development | `python-pro` | Async, type hints, FastAPI |
| Java/Spring | `java-enterprise` | Spring Boot, JPA |
| Code review | `code-reviewer` | Revisar PRs, quality checks |
| Testing strategy | `test-engineer` | Test planning, coverage |
| E2E testing | `e2e-test-specialist` | Playwright, Cypress |
| Security audit | `security-auditor` | OWASP, vulnerabilities |
| Performance | `performance-engineer` | Profiling, optimization |
| DevOps/CI-CD | `devops-engineer` | Pipelines, containers |
| Kubernetes | `kubernetes-expert` | K8s troubleshooting |
| Cloud architecture | `cloud-architect` | AWS, GCP, Azure design |
| Data engineering | `data-engineer` | ETL, data pipelines |
| ML/AI | `ai-engineer` | LLMs, ML production |
| Data science | `data-scientist` | Statistics, ML models |
| Documentation | `technical-writer` | Docs, guides, ADRs |

---

## Reglas de Invocación

### 1. Detección por Carpeta (Scope)
```
Si el archivo está en src/components/ → Cargar frontend-web, mantine-ui
Si el archivo está en internal/api/  → Cargar chi-router, go-backend
Si el archivo está en k8s/           → Cargar kubernetes, devops-infra
```

### 2. Detección por Extensión
```
*.tsx, *.jsx  → frontend-web, tanstack-query
*.go          → go-backend, chi-router
*.rs          → rust-systems, tokio-async
*.py          → fastapi, ai-ml
*.yaml (k8s)  → kubernetes
```

### 3. Detección por Contenido
```
import { useQuery }      → tanstack-query
import { z } from 'zod'  → zod-validation
from fastapi import      → fastapi
use tokio::              → tokio-async
```

---

## Ejemplo de Uso

**Usuario:** "Crea un componente de tabla con paginación"

**Proceso del Orquestador:**
1. Detecta: "componente" → Cargar `frontend-web`
2. Detecta: "tabla" → Cargar `mantine-ui` (tiene DataTable pattern)
3. Si hay data fetching → Cargar `tanstack-query`
4. Ejecutar con contexto de los 3 skills cargados

---

*Auto-generado. Mantener sincronizado con skills disponibles.*
