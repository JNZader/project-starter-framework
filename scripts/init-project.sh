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
echo "║           PROJECT STARTER FRAMEWORK                        ║"
echo "║                  Init Project                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

cd "$PROJECT_DIR"

# =============================================================================
# 1. Verificar que es un repo git
# =============================================================================
echo -e "${YELLOW}[1/6] Verificando repositorio Git...${NC}"
if [[ ! -d ".git" ]]; then
    echo -e "${YELLOW}  No es un repo git. Inicializando...${NC}"
    git init
    git checkout -b main
    git checkout -b develop
    echo -e "${GREEN}  ✓ Repo inicializado con branches main y develop${NC}"
else
    echo -e "${GREEN}  ✓ Repo git existente${NC}"
fi

# =============================================================================
# 2. Configurar git hooks
# =============================================================================
echo -e "${YELLOW}[2/6] Configurando git hooks...${NC}"
git config core.hooksPath .ci-local/hooks
chmod +x .ci-local/hooks/* 2>/dev/null || true
chmod +x .ci-local/*.sh 2>/dev/null || true
echo -e "${GREEN}  ✓ Hooks configurados${NC}"

# =============================================================================
# 3. Detectar stack
# =============================================================================
echo -e "${YELLOW}[3/6] Detectando stack tecnológico...${NC}"

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
echo -e "${YELLOW}[4/6] Verificando dependencias...${NC}"

# Docker
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo -e "${GREEN}  ✓ Docker: disponible${NC}"
else
    echo -e "${YELLOW}  ⚠ Docker: no disponible (requerido para CI-Local)${NC}"
fi

# Semgrep
if command -v semgrep &> /dev/null; then
    echo -e "${GREEN}  ✓ Semgrep: $(semgrep --version 2>/dev/null | head -1)${NC}"
else
    echo -e "${YELLOW}  ⚠ Semgrep: no instalado (pip install semgrep)${NC}"
fi

# =============================================================================
# 5. Crear .gitignore si no existe
# =============================================================================
echo -e "${YELLOW}[5/6] Verificando .gitignore...${NC}"
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
EOF
    echo -e "${GREEN}  ✓ .gitignore creado${NC}"
else
    echo -e "${GREEN}  ✓ .gitignore existente${NC}"
fi

# =============================================================================
# 6. Actualizar CONTEXT.md
# =============================================================================
echo -e "${YELLOW}[6/6] Preparando memoria del proyecto...${NC}"

PROJECT_NAME=$(basename "$PROJECT_DIR")
TODAY=$(date +%Y-%m-%d)

# Actualizar nombre en CONTEXT.md
sed -i "s/\[NOMBRE_PROYECTO\]/$PROJECT_NAME/g" .project/Memory/CONTEXT.md 2>/dev/null || true
sed -i "s/\[FECHA\]/$TODAY/g" .project/Memory/CONTEXT.md 2>/dev/null || true

echo -e "${GREEN}  ✓ Memoria preparada${NC}"

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
echo -e "  ./scripts/new-wave.sh           # Crear oleada de tareas"
echo -e ""
echo -e "${GREEN}Próximos pasos:${NC}"
echo -e "  1. Editar .project/Memory/CONTEXT.md con info del proyecto"
echo -e "  2. Crear tareas en VibeKanban"
echo -e "  3. Empezar a trabajar!"
echo -e ""
