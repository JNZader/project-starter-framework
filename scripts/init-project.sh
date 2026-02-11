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
echo -e "${YELLOW}[1/7] Verificando repositorio Git...${NC}"
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
echo -e "${YELLOW}[2/7] Configurando git hooks...${NC}"
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
echo -e "${YELLOW}[3/7] Detectando stack tecnológico...${NC}"

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
echo -e "${YELLOW}[4/7] Verificando dependencias...${NC}"

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
echo -e "${YELLOW}[5/7] Verificando .gitignore...${NC}"
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
echo -e "${YELLOW}[6/7] Módulos opcionales...${NC}"

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
# 7. Actualizar CLAUDE.md
# =============================================================================
echo -e "${YELLOW}[7/7] Configurando CLAUDE.md...${NC}"

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
