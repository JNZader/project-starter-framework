#!/bin/bash
# =============================================================================
# ADD-SKILL: Agrega skills de Gentleman-Skills u otras fuentes
# =============================================================================
# Uso:
#   ./scripts/add-skill.sh gentleman react-19
#   ./scripts/add-skill.sh gentleman typescript
#   ./scripts/add-skill.sh list              # Listar skills disponibles
#   ./scripts/add-skill.sh installed         # Ver skills instalados
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_DIR/.ai-config/skills"
GENTLEMAN_REPO="https://github.com/Gentleman-Programming/Gentleman-Skills.git"
TEMP_DIR="${TMPDIR:-/tmp}/gentleman-skills-$(id -u)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    echo -e "${CYAN}ADD-SKILL: Agrega skills al proyecto${NC}"
    echo ""
    echo "Uso:"
    echo "  ./scripts/add-skill.sh gentleman <skill-name>  # Desde Gentleman-Skills"
    echo "  ./scripts/add-skill.sh list                    # Listar disponibles"
    echo "  ./scripts/add-skill.sh installed               # Ver instalados"
    echo "  ./scripts/add-skill.sh remove <skill-name>     # Remover skill"
    echo ""
    echo "Skills populares de Gentleman-Skills:"
    echo "  - react-19, typescript, playwright, angular"
    echo "  - vercel-ai-sdk-5, zustand-5, tailwindcss-4"
    echo ""
}

clone_gentleman() {
    if [[ ! -d "$TEMP_DIR" ]]; then
        echo -e "${YELLOW}Cloning Gentleman-Skills repository...${NC}"
        git clone --depth 1 "$GENTLEMAN_REPO" "$TEMP_DIR" || {
            echo -e "${RED}Failed to clone Gentleman-Skills repository${NC}"
            exit 1
        }
    else
        echo -e "${YELLOW}Updating Gentleman-Skills repository...${NC}"
        rm -rf "$TEMP_DIR"
        git clone --depth 1 "$GENTLEMAN_REPO" "$TEMP_DIR" || {
            echo -e "${RED}Failed to update Gentleman-Skills repository${NC}"
            exit 1
        }
    fi
}

list_available() {
    clone_gentleman
    echo -e "${CYAN}=== Available Skills ===${NC}"
    echo ""
    echo -e "${GREEN}Curated (official):${NC}"
    ls -1 "$TEMP_DIR/curated/" 2>/dev/null | grep -v "README" || echo "  (none)"
    echo ""
    echo -e "${GREEN}Community:${NC}"
    ls -1 "$TEMP_DIR/community/" 2>/dev/null | grep -v "README" || echo "  (none)"
}

list_installed() {
    echo -e "${CYAN}=== Installed Skills ===${NC}"
    echo ""
    # Skills tipo carpeta (Gentleman-Skills)
    find "$SKILLS_DIR" -type f -name "SKILL.md" | while read -r skill; do
        rel="${skill#$SKILLS_DIR/}"
        name="${rel%/SKILL.md}"
        [[ "$name" == "_TEMPLATE" ]] && continue
        echo "  - $name"
    done

    # Skills tipo archivo .md
    find "$SKILLS_DIR" -type f -name "*.md" ! -name "_TEMPLATE.md" ! -name "SKILL.md" | while read -r skill; do
        rel="${skill#$SKILLS_DIR/}"
        name="${rel%.md}"
        echo "  - $name"
    done
}

add_gentleman_skill() {
    local skill_name="$1"

    # Security: validate skill name to prevent path traversal
    if [[ ! "$skill_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid skill name format. Use only alphanumeric, dash, underscore.${NC}"
        exit 1
    fi

    clone_gentleman

    # Buscar en curated primero, luego community
    local source_path=""
    if [[ -d "$TEMP_DIR/curated/$skill_name" ]]; then
        source_path="$TEMP_DIR/curated/$skill_name"
    elif [[ -d "$TEMP_DIR/community/$skill_name" ]]; then
        source_path="$TEMP_DIR/community/$skill_name"
    else
        echo -e "${RED}Skill '$skill_name' not found in Gentleman-Skills${NC}"
        echo "Use './scripts/add-skill.sh list' to see available skills"
        exit 1
    fi

    # Copiar skill
    echo -e "${YELLOW}Installing skill: $skill_name${NC}"
    cp -r "$source_path" "$SKILLS_DIR/"

    echo -e "${GREEN}✓ Skill '$skill_name' installed${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review: $SKILLS_DIR/$skill_name/"
    echo "  2. Sync config: ./scripts/sync-ai-config.sh"
}

remove_skill() {
    local skill_name="$1"

    # Security: validate skill name to prevent path traversal
    if [[ ! "$skill_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid skill name format. Use only alphanumeric, dash, underscore.${NC}"
        exit 1
    fi

    local skill_path="$SKILLS_DIR/$skill_name"

    if [[ -d "$skill_path" ]]; then
        rm -rf "$skill_path"
        echo -e "${GREEN}✓ Removed skill: $skill_name${NC}"
    elif [[ -f "$skill_path.md" ]]; then
        rm -f "$skill_path.md"
        echo -e "${GREEN}✓ Removed skill: $skill_name${NC}"
    else
        # Buscar por nombre en subcarpetas
        local file_match
        file_match=$(find "$SKILLS_DIR" -type f \( -name "$skill_name.md" -o -path "*/$skill_name/SKILL.md" \) | head -n 1)
        if [[ -n "$file_match" ]]; then
            if [[ "$(basename "$file_match")" == "SKILL.md" ]]; then
                rm -rf "$(dirname "$file_match")"
            else
                rm -f "$file_match"
            fi
            echo -e "${GREEN}✓ Removed skill: $skill_name${NC}"
            return 0
        fi
    fi

    echo -e "${RED}Skill '$skill_name' not found${NC}"
    exit 1
}

# =============================================================================
# Main
# =============================================================================

case "${1:-help}" in
    gentleman|g)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Specify skill name${NC}"
            echo "Example: ./scripts/add-skill.sh gentleman react-19"
            exit 1
        fi
        add_gentleman_skill "$2"
        ;;
    list|ls)
        list_available
        ;;
    installed|i)
        list_installed
        ;;
    remove|rm)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Specify skill name to remove${NC}"
            exit 1
        fi
        remove_skill "$2"
        ;;
    help|--help|-h|*)
        show_help
        ;;
esac
