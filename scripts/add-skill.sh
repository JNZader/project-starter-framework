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

source "$(cd "$(dirname "$0")" && pwd)/../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_DIR/.ai-config/skills"
GENTLEMAN_REPO="https://github.com/Gentleman-Programming/Gentleman-Skills.git"
TEMP_DIR="${TMPDIR:-/tmp}/gentleman-skills-$(id -u)"

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
    if [[ -d "$TEMP_DIR" ]]; then
        # Re-clone if cache older than 1 hour
        local age_minutes
        if [[ "$(uname)" == "Darwin" ]]; then
            age_minutes=$(( ($(date +%s) - $(stat -f %m "$TEMP_DIR")) / 60 ))
        else
            age_minutes=$(( ($(date +%s) - $(date -r "$TEMP_DIR" +%s)) / 60 ))
        fi
        if [[ $age_minutes -lt 60 ]]; then
            echo -e "${CYAN}  Using cached Gentleman-Skills (${age_minutes}m old)${NC}"
            return 0
        fi
        rm -rf "$TEMP_DIR"
    fi
    echo -e "${CYAN}  Cloning Gentleman-Skills...${NC}"
    git clone --depth 1 "$GENTLEMAN_REPO" "$TEMP_DIR" 2>/dev/null || {
        echo -e "${RED}Error: Could not clone Gentleman-Skills repository${NC}"
        exit 1
    }
}

list_available() {
    clone_gentleman
    echo -e "${CYAN}=== Available Skills ===${NC}"
    echo ""
    echo -e "${GREEN}Curated (official):${NC}"
    local found=false
    for f in "$TEMP_DIR/curated/"*; do
        [[ -e "$f" ]] || continue
        [[ "$(basename "$f")" == README* ]] && continue
        basename "$f"
        found=true
    done
    [[ "$found" == true ]] || echo "  (none)"
    echo ""
    echo -e "${GREEN}Community:${NC}"
    found=false
    for f in "$TEMP_DIR/community/"*; do
        [[ -e "$f" ]] || continue
        [[ "$(basename "$f")" == README* ]] && continue
        basename "$f"
        found=true
    done
    [[ "$found" == true ]] || echo "  (none)"
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

    echo -e "${GREEN}Skill '$skill_name' installed${NC}"
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
        echo -e "${GREEN}Removed skill: $skill_name${NC}"
        return 0
    elif [[ -f "$skill_path.md" ]]; then
        rm -f "$skill_path.md"
        echo -e "${GREEN}Removed skill: $skill_name${NC}"
        return 0
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
            echo -e "${GREEN}Removed skill: $skill_name${NC}"
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
