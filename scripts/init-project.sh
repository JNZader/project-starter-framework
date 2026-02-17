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

# =============================================================================
# Argument parsing
# =============================================================================
DRY_RUN=false
NON_INTERACTIVE=false
OPT_MEMORY=""
OPT_CI=""
OPT_ENGRAM=false
OPT_GHAGGA=false

show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Setup inicial para nuevo proyecto."
    echo ""
    echo "Options:"
    echo "  --dry-run             Show what would be done without making changes"
    echo "  --non-interactive     Run without prompts (use defaults or --memory/--ci flags)"
    echo "  --memory=N            Memory module choice: 1=obsidian-brain, 2=vibekanban, 3=memory-simple, 4=engram, 5=none"
    echo "  --ci=N                CI provider: 1=github, 2=gitlab, 3=woodpecker, 4=none"
    echo "  --engram              Add Engram module (when using --memory=1)"
    echo "  --ghagga              Add GHAGGA integration (when using --ci=1)"
    echo "  --help                Show this help message"
    echo ""
}

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            ;;
        --memory=*)
            OPT_MEMORY="${arg#--memory=}"
            ;;
        --ci=*)
            OPT_CI="${arg#--ci=}"
            ;;
        --engram)
            OPT_ENGRAM=true
            ;;
        --ghagga)
            OPT_GHAGGA=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
    esac
done

# =============================================================================
# Dry-run helpers
# =============================================================================
# Tracks actions that would be performed in dry-run mode
DRY_RUN_ACTIONS=()

# run_cmd - Execute a command or print what would be executed
# Usage: run_cmd <description> <command> [args...]
run_cmd() {
    local desc="$1"
    shift
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN] Would execute: $*${NC}"
        DRY_RUN_ACTIONS+=("$desc")
    else
        "$@"
    fi
}

# run_copy - Copy a file/directory or print what would be copied
# Usage: run_copy <source> <dest> [cp flags...]
run_copy() {
    local src="$1"
    local dest="$2"
    shift 2
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN] Would copy: $src -> $dest${NC}"
        DRY_RUN_ACTIONS+=("Copy $src -> $dest")
    else
        cp "$@" "$src" "$dest"
    fi
}

# run_mkdir - Create directory or print what would be created
# Usage: run_mkdir <path>
run_mkdir() {
    local dir="$1"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN] Would create directory: $dir${NC}"
        DRY_RUN_ACTIONS+=("Create directory $dir")
    else
        mkdir -p "$dir"
    fi
}

# run_write - Write content to a file or print what would be written
# Usage: echo "content" | run_write <dest> [description]
run_write() {
    local dest="$1"
    local desc="${2:-$dest}"
    if [[ "$DRY_RUN" == true ]]; then
        cat > /dev/null  # consume stdin
        echo -e "  ${CYAN}[DRY-RUN] Would write file: $dest${NC}"
        DRY_RUN_ACTIONS+=("Write $desc")
    else
        cat > "$dest"
    fi
}

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}=== DRY-RUN MODE: No changes will be made ===${NC}"
    echo ""
fi

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
    run_cmd "Initialize git repo" git init
    run_cmd "Create main branch" git checkout -b main
    echo -e "${GREEN}  ✓ Repo inicializado con branch main${NC}"
else
    echo -e "${GREEN}  ✓ Repo git existente${NC}"
fi

# =============================================================================
# 2. Configurar git hooks
# =============================================================================
echo -e "${YELLOW}[2/8] Configurando git hooks...${NC}"
if [[ -d ".ci-local/hooks" ]]; then
    run_cmd "Set git hooks path" git config core.hooksPath .ci-local/hooks
    run_cmd "Make hooks executable" chmod +x .ci-local/hooks/* 2>/dev/null || true
    run_cmd "Make ci-local scripts executable" chmod +x .ci-local/*.sh 2>/dev/null || true
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
    cat << 'EOF' | run_write ".gitignore"
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
# Reusable function: Install Engram module
# =============================================================================
# Installs the Engram memory module (MCP server config, install scripts,
# gitignore snippet). Called from memory choice "4" and from the secondary
# prompt when adding Engram alongside obsidian-brain.
# =============================================================================
install_engram_module() {
    local framework_dir="$1"

    echo -e "${GREEN}  Installing Engram module...${NC}"

    local project_name
    project_name=$(basename "$(pwd)")
    local escaped_name
    escaped_name=$(escape_sed "$project_name")

    if [[ -f "$framework_dir/optional/engram/.mcp-config-snippet.json" ]]; then
        if [[ ! -f ".mcp.json" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "  ${CYAN}[DRY-RUN] Would generate .mcp.json from template${NC}"
                DRY_RUN_ACTIONS+=("Generate .mcp.json")
            else
                sed "s/__PROJECT_NAME__/$escaped_name/g" \
                    "$framework_dir/optional/engram/.mcp-config-snippet.json" > .mcp.json
            fi
        else
            echo -e "${YELLOW}  .mcp.json ya existe - agrega engram manualmente${NC}"
            echo -e "  Ver: optional/engram/.mcp-config-snippet.json"
        fi
    fi

    backup_if_exists "scripts/install-engram.sh"
    run_copy "$framework_dir/optional/engram/install-engram.sh" "scripts/" 2>/dev/null || true
    backup_if_exists "scripts/install-engram.ps1"
    run_copy "$framework_dir/optional/engram/install-engram.ps1" "scripts/" 2>/dev/null || true
    run_cmd "Make install-engram.sh executable" chmod +x scripts/install-engram.sh 2>/dev/null || true

    if [[ -f "$framework_dir/optional/engram/.gitignore-snippet.txt" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${CYAN}[DRY-RUN] Would append engram gitignore snippet${NC}"
            DRY_RUN_ACTIONS+=("Append engram gitignore snippet")
        else
            echo "" >> .gitignore
            cat "$framework_dir/optional/engram/.gitignore-snippet.txt" >> .gitignore
        fi
    fi

    echo -e "${GREEN}  Engram module installed${NC}"
}

# =============================================================================
# 6. Módulos opcionales
# =============================================================================
echo -e "${YELLOW}[6/8] Módulos opcionales...${NC}"

detect_framework

if [[ -n "$FRAMEWORK_DIR" ]]; then
    # Copy shared library to target project
    run_mkdir "lib"
    run_copy "$FRAMEWORK_DIR/lib/common.sh" "lib/common.sh"
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
        if [[ "$NON_INTERACTIVE" == true ]]; then
            MEMORY_CHOICE="${OPT_MEMORY:-5}"
        else
            read -p "  Opción [1/2/3/4/5]: " MEMORY_CHOICE
        fi

        case "$MEMORY_CHOICE" in
            1)
                if [[ -d "$FRAMEWORK_DIR/optional/obsidian-brain/.project" ]]; then
                    run_copy "$FRAMEWORK_DIR/optional/obsidian-brain/.project" "." -r
                    run_copy "$FRAMEWORK_DIR/optional/obsidian-brain/.obsidian" "." -r
                    backup_if_exists "scripts/new-wave.sh"
                    run_copy "$FRAMEWORK_DIR/optional/obsidian-brain/new-wave.sh" "scripts/" 2>/dev/null || true
                    backup_if_exists "scripts/new-wave.ps1"
                    run_copy "$FRAMEWORK_DIR/optional/obsidian-brain/new-wave.ps1" "scripts/" 2>/dev/null || true
                    run_cmd "Make new-wave.sh executable" chmod +x scripts/new-wave.sh 2>/dev/null || true
                    # Append gitignore snippet
                    if [[ -f "$FRAMEWORK_DIR/optional/obsidian-brain/.obsidian-gitignore-snippet.txt" ]]; then
                        if [[ "$DRY_RUN" == true ]]; then
                            echo -e "  ${CYAN}[DRY-RUN] Would append .obsidian-gitignore-snippet.txt to .gitignore${NC}"
                            DRY_RUN_ACTIONS+=("Append obsidian gitignore snippet")
                        else
                            echo "" >> .gitignore
                            cat "$FRAMEWORK_DIR/optional/obsidian-brain/.obsidian-gitignore-snippet.txt" >> .gitignore
                        fi
                    fi
                    echo -e "${GREEN}  ✓ Obsidian Brain instalado${NC}"
                    echo -e "  ${CYAN}Nota: Instala plugins Kanban, Dataview y Templater desde Obsidian${NC}"
                fi
                ;;
            2)
                if [[ -d "$FRAMEWORK_DIR/optional/vibekanban/.project" ]]; then
                    run_copy "$FRAMEWORK_DIR/optional/vibekanban/.project" "." -r
                    backup_if_exists "scripts/new-wave.sh"
                    run_copy "$FRAMEWORK_DIR/optional/vibekanban/new-wave.sh" "scripts/" 2>/dev/null || true
                    backup_if_exists "scripts/new-wave.ps1"
                    run_copy "$FRAMEWORK_DIR/optional/vibekanban/new-wave.ps1" "scripts/" 2>/dev/null || true
                    run_cmd "Make new-wave.sh executable" chmod +x scripts/new-wave.sh 2>/dev/null || true
                    echo -e "${GREEN}  ✓ VibeKanban instalado (legacy)${NC}"
                fi
                ;;
            3)
                if [[ -d "$FRAMEWORK_DIR/optional/memory-simple/.project" ]]; then
                    run_copy "$FRAMEWORK_DIR/optional/memory-simple/.project" "." -r
                    echo -e "${GREEN}  ✓ Memory simple instalado${NC}"
                fi
                ;;
            4)
                if [[ -d "$FRAMEWORK_DIR/optional/engram" ]]; then
                    install_engram_module "$FRAMEWORK_DIR"
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
            if [[ "$NON_INTERACTIVE" == true ]]; then
                if [[ "$OPT_ENGRAM" == true ]]; then
                    ADD_ENGRAM="y"
                else
                    ADD_ENGRAM="N"
                fi
            else
                read -p "  ¿Agregar también Engram para memoria de agentes AI? [y/N]: " ADD_ENGRAM
            fi
            if [[ "$ADD_ENGRAM" == "y" || "$ADD_ENGRAM" == "Y" ]]; then
                install_engram_module "$FRAMEWORK_DIR"
                echo -e "${GREEN}  ✓ Engram agregado (complementa Obsidian Brain)${NC}"
                echo -e "  ${CYAN}Ejecuta: ./scripts/install-engram.sh para instalar el binario${NC}"
            fi
        fi
    else
        # Framework detected but optional/ dir not present - create basic memory structure
        echo -e "  ${YELLOW}optional/ no disponible. Creando estructura básica de memoria...${NC}"
        run_mkdir ".project/Memory"
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${CYAN}[DRY-RUN] Would create CONTEXT.md, DECISIONS.md, BLOCKERS.md, KANBAN.md${NC}"
            DRY_RUN_ACTIONS+=("Create basic memory files")
        else
            touch .project/Memory/CONTEXT.md
            touch .project/Memory/DECISIONS.md
            touch .project/Memory/BLOCKERS.md
            touch .project/Memory/KANBAN.md
        fi
        echo -e "${GREEN}  ✓ Estructura básica .project/Memory/ creada${NC}"
    fi
else
    echo -e "${GREEN}  ✓ Módulos ya configurados o no disponibles${NC}"
fi

# =============================================================================
# Helper: Assemble dependabot.yml from template files
# =============================================================================
# Reads template fragments from templates/common/dependabot/ and concatenates
# them based on the detected stack.
# =============================================================================
generate_dependabot_yml() {
    local stack="$1"
    local template_dir="$FRAMEWORK_DIR/templates/common/dependabot"

    # Header (version + updates key)
    if [[ -f "$template_dir/header.yml" ]]; then
        cat "$template_dir/header.yml"
    else
        echo "version: 2"
        echo ""
        echo "updates:"
    fi

    # GitHub Actions ecosystem (always included)
    if [[ -f "$template_dir/github-actions.yml" ]]; then
        cat "$template_dir/github-actions.yml"
    fi

    # Stack-specific ecosystem
    local ecosystem_file=""
    case "$stack" in
        java-gradle) ecosystem_file="gradle.yml" ;;
        java-maven)  ecosystem_file="maven.yml" ;;
        node)        ecosystem_file="npm.yml" ;;
        python)      ecosystem_file="pip.yml" ;;
        go)          ecosystem_file="gomod.yml" ;;
        rust)        ecosystem_file="cargo.yml" ;;
    esac

    if [[ -n "$ecosystem_file" && -f "$template_dir/$ecosystem_file" ]]; then
        cat "$template_dir/$ecosystem_file"
    fi
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
    if [[ "$NON_INTERACTIVE" == true ]]; then
        CI_CHOICE="${OPT_CI:-4}"
    else
        read -p "  Opción [1/2/3/4]: " CI_CHOICE
    fi

    case "$CI_CHOICE" in
        1)
            run_mkdir ".github/workflows"
            run_mkdir ".github/ISSUE_TEMPLATE"

            # CI workflow
            if [[ -f "$FRAMEWORK_DIR/templates/github/ci-${TEMPLATE_SUFFIX}.yml" ]]; then
                backup_if_exists ".github/workflows/ci.yml"
                run_copy "$FRAMEWORK_DIR/templates/github/ci-${TEMPLATE_SUFFIX}.yml" ".github/workflows/ci.yml"
                echo -e "${GREEN}  ✓ GitHub Actions configurado (.github/workflows/ci.yml)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Template github/ci-${TEMPLATE_SUFFIX}.yml no encontrado${NC}"
            fi

            # Dependabot auto-merge workflow
            if [[ -f "$FRAMEWORK_DIR/templates/github/dependabot-automerge.yml" ]]; then
                backup_if_exists ".github/workflows/dependabot-automerge.yml"
                run_copy "$FRAMEWORK_DIR/templates/github/dependabot-automerge.yml" ".github/workflows/dependabot-automerge.yml"
                echo -e "${GREEN}  ✓ Dependabot auto-merge configurado${NC}"
            fi

            # Assemble dependabot.yml from template fragments
            backup_if_exists ".github/dependabot.yml"
            generate_dependabot_yml "$STACK" | run_write ".github/dependabot.yml" "dependabot.yml (assembled from templates)"
            echo -e "${GREEN}  ✓ Dependabot configurado (.github/dependabot.yml)${NC}"

            # Issue and PR templates
            if [[ -d "$FRAMEWORK_DIR/.github/ISSUE_TEMPLATE" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo -e "  ${CYAN}[DRY-RUN] Would copy issue templates from $FRAMEWORK_DIR/.github/ISSUE_TEMPLATE/${NC}"
                    DRY_RUN_ACTIONS+=("Copy issue templates")
                else
                    cp "$FRAMEWORK_DIR/.github/ISSUE_TEMPLATE/"*.md .github/ISSUE_TEMPLATE/ 2>/dev/null || true
                fi
                echo -e "${GREEN}  ✓ Issue templates copiados${NC}"
            fi
            if [[ -f "$FRAMEWORK_DIR/.github/PULL_REQUEST_TEMPLATE.md" ]]; then
                backup_if_exists ".github/PULL_REQUEST_TEMPLATE.md"
                run_copy "$FRAMEWORK_DIR/.github/PULL_REQUEST_TEMPLATE.md" ".github/PULL_REQUEST_TEMPLATE.md"
                echo -e "${GREEN}  ✓ PR template copiado${NC}"
            fi

            # GHAGGA AI Code Review (optional)
            if [[ -d "$FRAMEWORK_DIR/optional/ghagga" ]]; then
                echo -e ""
                if [[ "$NON_INTERACTIVE" == true ]]; then
                    if [[ "$OPT_GHAGGA" == true ]]; then
                        ADD_GHAGGA="y"
                    else
                        ADD_GHAGGA="N"
                    fi
                else
                    read -p "  ¿Agregar AI code review con GHAGGA? [y/N]: " ADD_GHAGGA
                fi
                if [[ "$ADD_GHAGGA" == "y" || "$ADD_GHAGGA" == "Y" ]]; then
                    run_copy "$FRAMEWORK_DIR/.github/workflows/reusable-ghagga-review.yml" ".github/workflows/" 2>/dev/null || true
                    if [[ "$DRY_RUN" == true ]]; then
                        echo -e "  ${CYAN}[DRY-RUN] Would run setup-ghagga.sh or create fallback workflow${NC}"
                        DRY_RUN_ACTIONS+=("Setup GHAGGA review workflow")
                    else
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
                    fi
                    echo -e "${GREEN}  ✓ GHAGGA AI review configurado${NC}"
                    echo -e "  ${CYAN}Configura GHAGGA_URL (variable) y GHAGGA_TOKEN (secret) en repo settings${NC}"
                fi
            fi
            ;;
        2)
            if [[ -f "$FRAMEWORK_DIR/templates/gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml" ]]; then
                backup_if_exists ".gitlab-ci.yml"
                run_copy "$FRAMEWORK_DIR/templates/gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml" ".gitlab-ci.yml"
                echo -e "${GREEN}  ✓ GitLab CI configurado (.gitlab-ci.yml)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Template gitlab/gitlab-ci-${TEMPLATE_SUFFIX}.yml no encontrado${NC}"
            fi
            ;;
        3)
            if [[ -f "$FRAMEWORK_DIR/templates/woodpecker/woodpecker-${TEMPLATE_SUFFIX}.yml" ]]; then
                backup_if_exists ".woodpecker.yml"
                run_copy "$FRAMEWORK_DIR/templates/woodpecker/woodpecker-${TEMPLATE_SUFFIX}.yml" ".woodpecker.yml"
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
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN] Would update CLAUDE.md with project name and stack${NC}"
        DRY_RUN_ACTIONS+=("Update CLAUDE.md placeholders")
    else
        sed_inplace "s/\[NOMBRE_PROYECTO\]/$escaped_name/g" CLAUDE.md 2>/dev/null || true
        sed_inplace "s/\[STACK\]/$STACK/g" CLAUDE.md 2>/dev/null || true
    fi
    echo -e "${GREEN}  ✓ CLAUDE.md actualizado${NC}"
else
    echo -e "${YELLOW}  ⚠ CLAUDE.md no encontrado${NC}"
fi

# Actualizar CONTEXT.md si existe
if [[ -f ".project/Memory/CONTEXT.md" ]]; then
    TODAY=$(date +%Y-%m-%d)
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN] Would update CONTEXT.md with project name and date${NC}"
        DRY_RUN_ACTIONS+=("Update CONTEXT.md placeholders")
    else
        sed_inplace "s/\[NOMBRE_PROYECTO\]/$escaped_name/g" .project/Memory/CONTEXT.md 2>/dev/null || true
        sed_inplace "s/\[FECHA\]/$TODAY/g" .project/Memory/CONTEXT.md 2>/dev/null || true
    fi
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
if [[ -f ".github/dependabot.yml" ]] || [[ "$DRY_RUN" == true && "$CI_CHOICE" == "1" ]]; then
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

# =============================================================================
# Dry-run summary
# =============================================================================
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║               DRY-RUN SUMMARY                              ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${YELLOW}The following ${#DRY_RUN_ACTIONS[@]} action(s) would have been performed:${NC}"
    for i in "${!DRY_RUN_ACTIONS[@]}"; do
        echo -e "  $((i+1)). ${DRY_RUN_ACTIONS[$i]}"
    done
    echo -e ""
    echo -e "${YELLOW}Run without --dry-run to apply these changes.${NC}"
    echo -e ""
fi
