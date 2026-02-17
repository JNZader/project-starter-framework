#!/bin/bash
# =============================================================================
# INIT-PROJECT: Setup inicial para nuevo proyecto
# =============================================================================
# Configura git hooks, detecta stack, prepara entorno
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source shared library
source "$SCRIPT_DIR/../lib/common.sh"

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           PROJECT STARTER FRAMEWORK v2.0                   ║"
echo "║                  Init Project                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

cd "$PROJECT_DIR"

# =============================================================================
# 1. Verificar que es un repo git
# =============================================================================
echo -e "${YELLOW}[1/8] Verificando repositorio Git...${NC}"
if [[ ! -d ".git" ]]; then
    echo -e "${YELLOW}  No es un repo git. Inicializando...${NC}"
    git init
    git checkout -b main
    echo -e "${GREEN}  ✓ Repo inicializado con branch main${NC}"
else
    echo -e "${GREEN}  ✓ Repo git existente${NC}"
fi

# =============================================================================
# 2. Configurar git hooks
# =============================================================================
echo -e "${YELLOW}[2/8] Configurando git hooks...${NC}"
if [[ -d ".ci-local/hooks" ]]; then
    git config core.hooksPath .ci-local/hooks
    chmod +x .ci-local/hooks/* 2>/dev/null || true
    chmod +x .ci-local/*.sh 2>/dev/null || true
    echo -e "${GREEN}  ✓ Hooks configurados${NC}"
else
    echo -e "${YELLOW}  ⚠ .ci-local/hooks no encontrado${NC}"
fi

# =============================================================================
# 3. Detectar stack
# =============================================================================
echo -e "${YELLOW}[3/8] Detectando stack tecnológico...${NC}"

detect_stack "."
STACK="$STACK_TYPE"

if [[ "$STACK" != "unknown" ]]; then
    echo -e "${GREEN}  ✓ Detectado: $STACK${NC}"
else
    echo -e "${YELLOW}  ⚠ No se detectó stack. Configura manualmente.${NC}"
fi

# =============================================================================
# 4. Verificar dependencias
# =============================================================================
echo -e "${YELLOW}[4/8] Verificando dependencias...${NC}"

# Docker
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo -e "${GREEN}  ✓ Docker: disponible${NC}"
else
    echo -e "${YELLOW}  ⚠ Docker: no disponible (opcional para CI-Local full)${NC}"
fi

# Semgrep
if command -v semgrep &> /dev/null; then
    echo -e "${GREEN}  ✓ Semgrep: disponible${NC}"
else
    echo -e "${YELLOW}  ⚠ Semgrep: no instalado (pip install semgrep)${NC}"
fi

# =============================================================================
# 5. Crear .gitignore si no existe
# =============================================================================
echo -e "${YELLOW}[5/8] Verificando .gitignore...${NC}"
if [[ ! -f ".gitignore" ]]; then
    cat > .gitignore << 'EOF'
# CI Local
.ci-local/docker/
.ci-local-image-built
semgrep-report.json
semgrep-results.json

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db

# Env
.env
.env.local
.env.*.local
*.env

# Credentials
.npmrc
credentials.json
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore
.aws/
.ssh/
.gcp/
service-account*.json

# Build
*.log
coverage/
dist/
build/
target/
node_modules/
__pycache__/
.pytest_cache/

# AI config (generated, not committed)
CLAUDE.md
AGENTS.md
GEMINI.md
.cursorrules
.aider.conf.yml
.continue/
EOF
    echo -e "${GREEN}  ✓ .gitignore creado${NC}"
else
    echo -e "${GREEN}  ✓ .gitignore existente${NC}"
fi

# =============================================================================
# 6. Módulos opcionales
# =============================================================================
echo -e "${YELLOW}[6/8] Módulos opcionales...${NC}"

detect_framework

if [[ -n "$FRAMEWORK_DIR" ]]; then
    # Copy shared library to target project
    mkdir -p lib
    cp "$FRAMEWORK_DIR/lib/common.sh" lib/common.sh
    echo -e "${GREEN}  lib/common.sh copied${NC}"

    if [[ "$HAS_OPTIONAL" == true ]]; then
        echo -e "  ${CYAN}¿Instalar módulo de memoria del proyecto?${NC}"
        echo -e "    1) obsidian-brain  - Vault Obsidian + Kanban + memoria estructurada (RECOMENDADO)"
        echo -e "    2) vibekanban      - Oleadas paralelas + memoria (legacy)"
        echo -e "    3) simple          - Solo un archivo NOTES.md"
        echo -e "    4) engram          - Memoria persistente para agentes AI (MCP server)"
        echo -e "    5) ninguno         - Sin memoria de proyecto"
        echo -e ""
        echo -e "  ${YELLOW}Nota: engram complementa a obsidian-brain (pueden usarse juntos)${NC}"
        echo -e ""
        read -p "  Opción [1/2/3/4/5]: " MEMORY_CHOICE

        case "$MEMORY_CHOICE" in
            1)
                if [[ -d "$FRAMEWORK_DIR/optional/obsidian-brain/.project" ]]; then
                    cp -r "$FRAMEWORK_DIR/optional/obsidian-brain/.project" .
                    cp -r "$FRAMEWORK_DIR/optional/obsidian-brain/.obsidian" .
                    backup_if_exists "scripts/new-wave.sh"
                    cp "$FRAMEWORK_DIR/optional/obsidian-brain/new-wave.sh" scripts/ 2>/dev/null || true
                    backup_if_exists "scripts/new-wave.ps1"
                    cp "$FRAMEWORK_DIR/optional/obsidian-brain/new-wave.ps1" scripts/ 2>/dev/null || true
                    chmod +x scripts/new-wave.sh 2>/dev/null || true
                    # Append gitignore snippet
                    if [[ -f "$FRAMEWORK_DIR/optional/obsidian-brain/.obsidian-gitignore-snippet.txt" ]]; then
                        echo "" >> .gitignore
                        cat "$FRAMEWORK_DIR/optional/obsidian-brain/.obsidian-gitignore-snippet.txt" >> .gitignore
                    fi
                    echo -e "${GREEN}  ✓ Obsidian Brain instalado${NC}"
                    echo -e "  ${CYAN}Nota: Instala plugins Kanban, Dataview y Templater desde Obsidian${NC}"
                fi
                ;;
            2)
                if [[ -d "$FRAMEWORK_DIR/optional/vibekanban/.project" ]]; then
                    cp -r "$FRAMEWORK_DIR/optional/vibekanban/.project" .
                    backup_if_exists "scripts/new-wave.sh"
                    cp "$FRAMEWORK_DIR/optional/vibekanban/new-wave.sh" scripts/ 2>/dev/null || true
                    backup_if_exists "scripts/new-wave.ps1"
                    cp "$FRAMEWORK_DIR/optional/vibekanban/new-wave.ps1" scripts/ 2>/dev/null || true
                    chmod +x scripts/new-wave.sh 2>/dev/null || true
                    echo -e "${GREEN}  ✓ VibeKanban instalado (legacy)${NC}"
                fi
                ;;
            3)
                if [[ -d "$FRAMEWORK_DIR/optional/memory-simple/.project" ]]; then
                    cp -r "$FRAMEWORK_DIR/optional/memory-simple/.project" .
                    echo -e "${GREEN}  ✓ Memory simple instalado${NC}"
                fi
                ;;
            4)
                if [[ -d "$FRAMEWORK_DIR/optional/engram" ]]; then
                    # Copiar config MCP
                    project_name=$(basename "$(pwd)")
                    escaped_name=$(escape_sed "$project_name")
                    if [[ -f "$FRAMEWORK_DIR/optional/engram/.mcp-config-snippet.json" ]]; then
                        if [[ ! -f ".mcp.json" ]]; then
                            sed "s/__PROJECT_NAME__/$escaped_name/g" \
                                "$FRAMEWORK_DIR/optional/engram/.mcp-config-snippet.json" > .mcp.json
                        else
                            echo -e "${YELLOW}  .mcp.json ya existe - agrega engram manualmente${NC}"
                            echo -e "  Ver: optional/engram/.mcp-config-snippet.json"
                        fi
                    fi
                    # Copiar script de instalacion
                    backup_if_exists "scripts/install-engram.sh"
                    cp "$FRAMEWORK_DIR/optional/engram/install-engram.sh" scripts/ 2>/dev/null || true
                    backup_if_exists "scripts/install-engram.ps1"
                    cp "$FRAMEWORK_DIR/optional/engram/install-engram.ps1" scripts/ 2>/dev/null || true
                    chmod +x scripts/install-engram.sh 2>/dev/null || true
                    # Append gitignore snippet
                    if [[ -f "$FRAMEWORK_DIR/optional/engram/.gitignore-snippet.txt" ]]; then
                        echo "" >> .gitignore
                        cat "$FRAMEWORK_DIR/optional/engram/.gitignore-snippet.txt" >> .gitignore
                    fi
                    echo -e "${GREEN}  ✓ Engram configurado${NC}"
                    echo -e "  ${CYAN}Ejecuta: ./scripts/install-engram.sh para instalar el binario${NC}"
                fi
                ;;
            *)
                echo -e "${GREEN}  ✓ Sin módulo de memoria${NC}"
                ;;
        esac

        # Preguntar por engram adicional si eligieron obsidian-brain
        if [[ "$MEMORY_CHOICE" == "1" && -d "$FRAMEWORK_DIR/optional/engram" ]]; then
            echo -e ""
            read -p "  ¿Agregar también Engram para memoria de agentes AI? [y/N]: " ADD_ENGRAM
            if [[ "$ADD_ENGRAM" == "y" || "$ADD_ENGRAM" == "Y" ]]; then
                project_name=$(basename "$(pwd)")
                escaped_name=$(escape_sed "$project_name")
                if [[ ! -f ".mcp.json" ]]; then
                    sed "s/__PROJECT_NAME__/$escaped_name/g" \
                        "$FRAMEWORK_DIR/optional/engram/.mcp-config-snippet.json" > .mcp.json
                fi
                backup_if_exists "scripts/install-engram.sh"
                cp "$FRAMEWORK_DIR/optional/engram/install-engram.sh" scripts/ 2>/dev/null || true
                backup_if_exists "scripts/install-engram.ps1"
                cp "$FRAMEWORK_DIR/optional/engram/install-engram.ps1" scripts/ 2>/dev/null || true
                chmod +x scripts/install-engram.sh 2>/dev/null || true
                if [[ -f "$FRAMEWORK_DIR/optional/engram/.gitignore-snippet.txt" ]]; then
                    echo "" >> .gitignore
                    cat "$FRAMEWORK_DIR/optional/engram/.gitignore-snippet.txt" >> .gitignore
                fi
                echo -e "${GREEN}  ✓ Engram agregado (complementa Obsidian Brain)${NC}"
                echo -e "  ${CYAN}Ejecuta: ./scripts/install-engram.sh para instalar el binario${NC}"
            fi
        fi
    else
        # Framework detected but optional/ dir not present - create basic memory structure
        echo -e "  ${YELLOW}optional/ no disponible. Creando estructura básica de memoria...${NC}"
        mkdir -p .project/Memory
        touch .project/Memory/CONTEXT.md
        touch .project/Memory/DECISIONS.md
        touch .project/Memory/BLOCKERS.md
        touch .project/Memory/KANBAN.md
        echo -e "${GREEN}  ✓ Estructura básica .project/Memory/ creada${NC}"
    fi
else
    echo -e "${GREEN}  ✓ Módulos ya configurados o no disponibles${NC}"
fi

# =============================================================================
# Helper: Generate dependabot.yml based on detected stack
# =============================================================================
generate_dependabot_yml() {
    local stack="$1"
    cat << 'HEADER'
version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      # timezone: "UTC"  # Change to your timezone
    labels:
      - "dependencies"
      - "github-actions"
    commit-message:
      prefix: "chore(deps)"
    groups:
      actions:
        patterns:
          - "*"
HEADER

    case "$stack" in
        java-gradle)
            cat << 'GRADLE'

  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "java"
    commit-message:
      prefix: "chore(deps)"
    groups:
      java-dependencies:
        patterns:
          - "*"
GRADLE
            ;;
        java-maven)
            cat << 'MAVEN'

  - package-ecosystem: "maven"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "java"
    commit-message:
      prefix: "chore(deps)"
    groups:
      maven-dependencies:
        patterns:
          - "*"
MAVEN
            ;;
        node)
            cat << 'NODE'

  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "javascript"
    commit-message:
      prefix: "chore(deps)"
    groups:
      npm-dependencies:
        patterns:
          - "*"
        exclude-patterns:
          - "@types/*"
      npm-types:
        patterns:
          - "@types/*"
NODE
            ;;
        python)
            cat << 'PYTHON'

  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "python"
    commit-message:
      prefix: "chore(deps)"
PYTHON
            ;;
        go)
            cat << 'GO'

  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "go"
    commit-message:
      prefix: "chore(deps)"
    groups:
      go-dependencies:
        patterns:
          - "*"
GO
            ;;
        rust)
            cat << 'RUST'

  - package-ecosystem: "cargo"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "rust"
    commit-message:
      prefix: "chore(deps)"
RUST
            ;;
    esac
}

# =============================================================================
# 7. CI Provider
# =============================================================================
echo -e "${YELLOW}[7/8] Configurando CI remoto...${NC}"

# Map stack to template suffix
TEMPLATE_SUFFIX=""
case "$STACK" in
    java-gradle|java-maven) TEMPLATE_SUFFIX="java" ;;
    node)                   TEMPLATE_SUFFIX="node" ;;
    python)                 TEMPLATE_SUFFIX="python" ;;
    go)                     TEMPLATE_SUFFIX="go" ;;
    rust)                   TEMPLATE_SUFFIX="rust" ;;
esac

if [[ -n "$FRAMEWORK_DIR" && -n "$TEMPLATE_SUFFIX" ]]; then
    echo -e "  ${CYAN}¿Qué CI remoto usar?${NC}"
    echo -e "    1) GitHub Actions"
    echo -e "    2) GitLab CI"
    echo -e "    3) Woodpecker CI"
    echo -e "    4) Solo CI-Local (sin CI remoto)"
    echo -e ""
    read -p "  Opción [1/2/3/4]: " CI_CHOICE

    case "$CI_CHOICE" in
        1)
            mkdir -p .github/workflows
            mkdir -p .github/ISSUE_TEMPLATE

            # CI workflow
            if [[ -f "$FRAMEWORK_DIR/templates/github/ci-${TEMPLATE_SUFFIX}.yml" ]]; then
                backup_if_exists ".github/workflows/ci.yml"
                cp "$FRAMEWORK_DIR/templates/github/ci-${TEMPLATE_SUFFIX}.yml" .github/workflows/ci.yml
                echo -e "${GREEN}  ✓ GitHub Actions configurado (.github/workflows/ci.yml)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Template github/ci-${TEMPLATE_SUFFIX}.yml no encontrado${NC}"
            fi

            # Dependabot auto-merge workflow
            if [[ -f "$FRAMEWORK_DIR/templates/github/dependabot-automerge.yml" ]]; then
                backup_if_exists ".github/workflows/dependabot-automerge.yml"
                cp "$FRAMEWORK_DIR/templates/github/dependabot-automerge.yml" .github/workflows/dependabot-automerge.yml
                echo -e "${GREEN}  ✓ Dependabot auto-merge configurado${NC}"
            fi

            # Generate dependabot.yml with detected stack
            backup_if_exists ".github/dependabot.yml"
            generate_dependabot_yml "$STACK" > .github/dependabot.yml
            echo -e "${GREEN}  ✓ Dependabot configurado (.github/dependabot.yml)${NC}"

            # Issue and PR templates
            if [[ -d "$FRAMEWORK_DIR/.github/ISSUE_TEMPLATE" ]]; then
                cp "$FRAMEWORK_DIR/.github/ISSUE_TEMPLATE/"*.md .github/ISSUE_TEMPLATE/ 2>/dev/null || true
                echo -e "${GREEN}  ✓ Issue templates copiados${NC}"
            fi
            if [[ -f "$FRAMEWORK_DIR/.github/PULL_REQUEST_TEMPLATE.md" ]]; then
                backup_if_exists ".github/PULL_REQUEST_TEMPLATE.md"
                cp "$FRAMEWORK_DIR/.github/PULL_REQUEST_TEMPLATE.md" .github/PULL_REQUEST_TEMPLATE.md
                echo -e "${GREEN}  ✓ PR template copiado${NC}"
            fi

            # GHAGGA AI Code Review (optional)
            if [[ -d "$FRAMEWORK_DIR/optional/ghagga" ]]; then
                echo -e ""
                read -p "  ¿Agregar AI code review con GHAGGA? [y/N]: " ADD_GHAGGA
                if [[ "$ADD_GHAGGA" == "y" || "$ADD_GHAGGA" == "Y" ]]; then
                    cp "$FRAMEWORK_DIR/.github/workflows/reusable-ghagga-review.yml" .github/workflows/ 2>/dev/null || true
                    bash "$FRAMEWORK_DIR/optional/ghagga/setup-ghagga.sh" --workflow 2>/dev/null || {
                        # Fallback: copiar workflow directamente
                        cat > .github/workflows/ghagga-review.yml << 'GHAGGA_WF'
name: AI Code Review
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main, develop]
concurrency:
  group: ghagga-${{ github.event.pull_request.number }}
  cancel-in-progress: true
jobs:
  review:
    uses: JNZader/project-starter-framework/.github/workflows/reusable-ghagga-review.yml@main
    with:
      ghagga-url: ${{ vars.GHAGGA_URL }}
      review-mode: simple
    secrets:
      ghagga-token: ${{ secrets.GHAGGA_TOKEN }}
GHAGGA_WF
                    }
                    echo -e "${GREEN}  ✓ GHAGGA AI review configurado${NC}"
                    echo -e "  ${CYAN}Configura GHAGGA_URL (variable) y GHAGGA_TOKEN (secret) en repo settings${NC}"
                fi
            fi
            ;;
        2)
            if [[ -f "$FRAMEWORK_DIR/templates/gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml" ]]; then
                backup_if_exists ".gitlab-ci.yml"
                cp "$FRAMEWORK_DIR/templates/gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml" .gitlab-ci.yml
                echo -e "${GREEN}  ✓ GitLab CI configurado (.gitlab-ci.yml)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Template gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml no encontrado${NC}"
            fi
            ;;
        3)
            if [[ -f "$FRAMEWORK_DIR/templates/woodpecker/woodpecker-${TEMPLATE_SUFFIX}.yml" ]]; then
                backup_if_exists ".woodpecker.yml"
                cp "$FRAMEWORK_DIR/templates/woodpecker/woodpecker-${TEMPLATE_SUFFIX}.yml" .woodpecker.yml
                echo -e "${GREEN}  ✓ Woodpecker CI configurado (.woodpecker.yml)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Template woodpecker/woodpecker-${TEMPLATE_SUFFIX}.yml no encontrado${NC}"
            fi
            ;;
        *)
            echo -e "${GREEN}  ✓ Solo CI-Local (sin CI remoto)${NC}"
            ;;
    esac
elif [[ -z "$TEMPLATE_SUFFIX" ]]; then
    echo -e "${YELLOW}  ⚠ Stack no detectado, configura CI remoto manualmente${NC}"
else
    echo -e "${GREEN}  ✓ CI remoto ya configurado o no disponible${NC}"
fi

# =============================================================================
# 8. Actualizar CLAUDE.md
# =============================================================================
echo -e "${YELLOW}[8/8] Configurando CLAUDE.md...${NC}"

PROJECT_NAME=$(basename "$PROJECT_DIR")
escaped_name=$(escape_sed "$PROJECT_NAME")

if [[ -f "CLAUDE.md" ]]; then
    sed_inplace "s/\[NOMBRE_PROYECTO\]/$escaped_name/g" CLAUDE.md 2>/dev/null || true
    sed_inplace "s/\[STACK\]/$STACK/g" CLAUDE.md 2>/dev/null || true
    echo -e "${GREEN}  ✓ CLAUDE.md actualizado${NC}"
else
    echo -e "${YELLOW}  ⚠ CLAUDE.md no encontrado${NC}"
fi

# Actualizar CONTEXT.md si existe
if [[ -f ".project/Memory/CONTEXT.md" ]]; then
    TODAY=$(date +%Y-%m-%d)
    sed_inplace "s/\[NOMBRE_PROYECTO\]/$escaped_name/g" .project/Memory/CONTEXT.md 2>/dev/null || true
    sed_inplace "s/\[FECHA\]/$TODAY/g" .project/Memory/CONTEXT.md 2>/dev/null || true
fi

# =============================================================================
# Resumen
# =============================================================================
echo -e ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   Setup Completado!                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e ""
echo -e "${GREEN}Proyecto:${NC} $PROJECT_NAME"
echo -e "${GREEN}Stack:${NC} $STACK"
echo -e ""
echo -e "${GREEN}Hooks habilitados:${NC}"
echo -e "  • pre-commit: AI attribution check + lint + security"
echo -e "  • commit-msg: Valida mensaje sin AI attribution"
echo -e "  • pre-push:   CI simulation en Docker"
echo -e ""
if [[ -f ".github/dependabot.yml" ]]; then
echo -e "${GREEN}Dependabot:${NC}"
echo -e "  • Updates semanales (lunes 9am)"
echo -e "  • Auto-merge de patches habilitado"
echo -e "  • Habilitar 'Allow auto-merge' en Settings > General"
echo -e ""
fi
echo -e "${GREEN}Comandos útiles:${NC}"
echo -e "  ./.ci-local/ci-local.sh quick   # Check rápido"
echo -e "  ./.ci-local/ci-local.sh full    # CI completo"
echo -e "  ./.ci-local/ci-local.sh shell   # Shell en entorno CI"
echo -e ""
