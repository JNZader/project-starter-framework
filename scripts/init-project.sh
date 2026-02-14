#!/bin/bash
# =============================================================================
# INIT-PROJECT: Setup inicial para nuevo proyecto
# =============================================================================
# Configura git hooks, detecta stack, prepara entorno
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

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

STACK="unknown"
if [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
    STACK="java-gradle"
elif [[ -f "pom.xml" ]]; then
    STACK="java-maven"
elif [[ -f "go.mod" ]]; then
    STACK="go"
elif [[ -f "Cargo.toml" ]]; then
    STACK="rust"
elif [[ -f "package.json" ]]; then
    STACK="node"
elif [[ -f "pyproject.toml" || -f "requirements.txt" ]]; then
    STACK="python"
fi

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
*.env

# Build
*.log
coverage/
dist/
build/
target/
node_modules/
__pycache__/
.pytest_cache/

# Claude Code
CLAUDE.md
EOF
    echo -e "${GREEN}  ✓ .gitignore creado${NC}"
else
    echo -e "${GREEN}  ✓ .gitignore existente${NC}"
fi

# =============================================================================
# 6. Módulos opcionales
# =============================================================================
echo -e "${YELLOW}[6/8] Módulos opcionales...${NC}"

FRAMEWORK_DIR=""
# Detectar si estamos en el framework o en un proyecto que lo copió
if [[ -d "optional/vibekanban" ]]; then
    FRAMEWORK_DIR="."
fi

if [[ -n "$FRAMEWORK_DIR" ]]; then
    echo -e "  ${CYAN}¿Instalar módulo de memoria del proyecto?${NC}"
    echo -e "    1) vibekanban - Oleadas paralelas + memoria estructurada"
    echo -e "    2) simple     - Solo un archivo NOTES.md"
    echo -e "    3) ninguno    - Sin memoria de proyecto"
    echo -e ""
    read -p "  Opción [1/2/3]: " MEMORY_CHOICE

    case "$MEMORY_CHOICE" in
        1)
            if [[ -d "$FRAMEWORK_DIR/optional/vibekanban/.project" ]]; then
                cp -r "$FRAMEWORK_DIR/optional/vibekanban/.project" .
                cp "$FRAMEWORK_DIR/optional/vibekanban/new-wave.sh" scripts/ 2>/dev/null || true
                cp "$FRAMEWORK_DIR/optional/vibekanban/new-wave.ps1" scripts/ 2>/dev/null || true
                chmod +x scripts/new-wave.sh 2>/dev/null || true
                echo -e "${GREEN}  ✓ VibeKanban instalado${NC}"
            fi
            ;;
        2)
            if [[ -d "$FRAMEWORK_DIR/optional/memory-simple/.project" ]]; then
                cp -r "$FRAMEWORK_DIR/optional/memory-simple/.project" .
                echo -e "${GREEN}  ✓ Memory simple instalado${NC}"
            fi
            ;;
        *)
            echo -e "${GREEN}  ✓ Sin módulo de memoria${NC}"
            ;;
    esac
else
    echo -e "${GREEN}  ✓ Módulos ya configurados o no disponibles${NC}"
fi

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
            if [[ -f "$FRAMEWORK_DIR/templates/github/ci-${TEMPLATE_SUFFIX}.yml" ]]; then
                cp "$FRAMEWORK_DIR/templates/github/ci-${TEMPLATE_SUFFIX}.yml" .github/workflows/ci.yml
                echo -e "${GREEN}  ✓ GitHub Actions configurado (.github/workflows/ci.yml)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Template github/ci-${TEMPLATE_SUFFIX}.yml no encontrado${NC}"
            fi
            ;;
        2)
            if [[ -f "$FRAMEWORK_DIR/templates/gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml" ]]; then
                cp "$FRAMEWORK_DIR/templates/gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml" .gitlab-ci.yml
                echo -e "${GREEN}  ✓ GitLab CI configurado (.gitlab-ci.yml)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Template gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml no encontrado${NC}"
            fi
            ;;
        3)
            if [[ -f "$FRAMEWORK_DIR/templates/woodpecker/woodpecker-${TEMPLATE_SUFFIX}.yml" ]]; then
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

if [[ -f "CLAUDE.md" ]]; then
    sed -i "s/\[NOMBRE_PROYECTO\]/$PROJECT_NAME/g" CLAUDE.md 2>/dev/null || true
    sed -i "s/\[STACK\]/$STACK/g" CLAUDE.md 2>/dev/null || true
    echo -e "${GREEN}  ✓ CLAUDE.md actualizado${NC}"
else
    echo -e "${YELLOW}  ⚠ CLAUDE.md no encontrado${NC}"
fi

# Actualizar CONTEXT.md si existe
if [[ -f ".project/Memory/CONTEXT.md" ]]; then
    TODAY=$(date +%Y-%m-%d)
    sed -i "s/\[NOMBRE_PROYECTO\]/$PROJECT_NAME/g" .project/Memory/CONTEXT.md 2>/dev/null || true
    sed -i "s/\[FECHA\]/$TODAY/g" .project/Memory/CONTEXT.md 2>/dev/null || true
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
echo -e "${GREEN}Comandos útiles:${NC}"
echo -e "  ./.ci-local/ci-local.sh quick   # Check rápido"
echo -e "  ./.ci-local/ci-local.sh full    # CI completo"
echo -e "  ./.ci-local/ci-local.sh shell   # Shell en entorno CI"
echo -e ""
