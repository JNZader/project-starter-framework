#!/bin/bash
# =============================================================================
# collect-skills.sh — Importa skills desde herramientas AI hacia .ai-config/
# =============================================================================
# Uso:
#   ./scripts/collect-skills.sh <source-dir> [category]
#   ./scripts/collect-skills.sh list-targets
#
# Ejemplos:
#   ./scripts/collect-skills.sh ~/my-project/.ai-config/skills backend
#   ./scripts/collect-skills.sh /tmp/new-skills
#   ./scripts/collect-skills.sh list-targets
# =============================================================================

set -e

source "$(cd "$(dirname "$0")" && pwd)/../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AI_CONFIG_DIR="$PROJECT_DIR/.ai-config"
SKILLS_DIR="$AI_CONFIG_DIR/skills"

echo -e "${CYAN}=== Collect Skills ===${NC}"
echo ""

# Known external skill locations per AI tool
declare -A TOOL_SKILL_DIRS=(
    ["claude"]="$HOME/.claude/skills"
    ["opencode"]="$HOME/.opencode/skills"
    ["cursor"]="$HOME/.cursor/skills"
    ["gemini"]="$HOME/.gemini/skills"
)

# -----------------------------------------------------------------------------
# Listar targets conocidos
# -----------------------------------------------------------------------------
list_targets() {
    echo -e "${GREEN}Targets conocidos:${NC}"
    echo ""
    printf "  %-12s %s\n" "TARGET" "RUTA"
    printf "  %-12s %s\n" "------" "----"
    for tool in "${!TOOL_SKILL_DIRS[@]}"; do
        local dir="${TOOL_SKILL_DIRS[$tool]}"
        local status="${RED}(no encontrado)${NC}"
        [[ -d "$dir" ]] && status="${GREEN}(existe)${NC}"
        printf "  %-12s %s " "$tool" "$dir"
        echo -e "$status"
    done
    echo ""
    echo -e "Uso: $0 <ruta> [categoria]"
    echo -e "     $0 --from <target-name> [categoria]"
}

# -----------------------------------------------------------------------------
# Importar un SKILL.md desde una ruta
# -----------------------------------------------------------------------------
import_skill_file() {
    local src_file="$1"
    local category="$2"

    if [[ ! -f "$src_file" ]]; then
        echo -e "${RED}Error: No existe $src_file${NC}"
        return 1
    fi

    # Extraer nombre del skill desde frontmatter
    local skill_name
    skill_name=$(grep "^name:" "$src_file" | head -1 | sed 's/name: *//')

    if [[ -z "$skill_name" ]]; then
        echo -e "${YELLOW}  Skipping $(basename "$src_file"): no 'name' in frontmatter${NC}"
        return 0
    fi

    # Determinar categoría: explícita > de frontmatter > "imported"
    if [[ -z "$category" ]]; then
        category=$(grep "^  category:" "$src_file" 2>/dev/null | head -1 | sed 's/.*category: *//')
        category="${category:-imported}"
    fi

    local dest_dir="$SKILLS_DIR/$category/$skill_name"
    local dest_file="$dest_dir/SKILL.md"

    if [[ -f "$dest_file" ]]; then
        echo -e "${YELLOW}  [EXISTS] $category/$skill_name — ¿Sobreescribir? [y/N]${NC}"
        read -r OVERWRITE
        if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]]; then
            echo -e "${YELLOW}  Skipped: $category/$skill_name${NC}"
            return 0
        fi
        # Backup before overwrite
        cp "$dest_file" "${dest_file}.bak"
        echo -e "${YELLOW}  Backup: ${dest_file}.bak${NC}"
    fi

    mkdir -p "$dest_dir"
    cp "$src_file" "$dest_file"
    echo -e "${GREEN}  [IMPORTED] $category/$skill_name${NC}"
}

# -----------------------------------------------------------------------------
# Importar desde un directorio (recursivo)
# -----------------------------------------------------------------------------
import_from_dir() {
    local src_dir="$1"
    local category="$2"
    local imported=0
    local skipped=0

    if [[ ! -d "$src_dir" ]]; then
        echo -e "${RED}Error: Directorio no encontrado: $src_dir${NC}"
        exit 1
    fi

    echo -e "${BLUE}Importando skills desde: $src_dir${NC}"
    [[ -n "$category" ]] && echo -e "${BLUE}Categoría destino: $category${NC}"
    echo ""

    while IFS= read -r -d '' skill_file; do
        if import_skill_file "$skill_file" "$category"; then
            imported=$((imported + 1))
        else
            skipped=$((skipped + 1))
        fi
    done < <(find "$src_dir" -type f -name "SKILL.md" -print0)

    # Also pick up flat .md files that are not SKILL.md (legacy format)
    while IFS= read -r -d '' skill_file; do
        [[ "$(basename "$skill_file")" == "_TEMPLATE.md" ]] && continue
        if import_skill_file "$skill_file" "$category"; then
            imported=$((imported + 1))
        else
            skipped=$((skipped + 1))
        fi
    done < <(find "$src_dir" -maxdepth 2 -type f -name "*.md" ! -name "SKILL.md" ! -name "_TEMPLATE.md" -print0 2>/dev/null)

    echo ""
    echo -e "${GREEN}Importados: $imported | Saltados: $skipped${NC}"
    echo ""
    echo -e "${CYAN}Próximos pasos:${NC}"
    echo "  1. Revisa los skills importados: ls $SKILLS_DIR/$category/"
    echo "  2. Valida el formato: ./scripts/sync-skills.sh validate"
    echo "  3. Regenera la config: ./scripts/sync-ai-config.sh"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
case "${1:-help}" in
    list-targets|targets)
        list_targets
        ;;
    --from)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: especifica un target. Ej: $0 --from claude${NC}"
            exit 1
        fi
        tool_dir="${TOOL_SKILL_DIRS[$2]}"
        if [[ -z "$tool_dir" ]]; then
            echo -e "${RED}Target desconocido: $2${NC}"
            list_targets
            exit 1
        fi
        import_from_dir "$tool_dir" "${3:-}"
        ;;
    help|--help|-h)
        echo "Uso: $0 <source-dir> [categoria]"
        echo "     $0 --from <target-name> [categoria]"
        echo "     $0 list-targets"
        echo ""
        echo "Argumentos:"
        echo "  source-dir   Directorio con SKILL.md files a importar"
        echo "  categoria    Categoría destino (ej: backend, frontend). Default: 'imported'"
        echo "  --from       Importar desde un target AI conocido (claude, opencode, etc.)"
        echo "  list-targets Listar targets AI conocidos y sus rutas"
        echo ""
        echo "Ejemplos:"
        echo "  $0 ~/shared-skills backend"
        echo "  $0 --from claude workflow"
        echo "  $0 /tmp/new-skill"
        ;;
    *)
        # Assume first arg is a directory path
        if [[ -d "$1" ]]; then
            import_from_dir "$1" "${2:-}"
        elif [[ -f "$1" ]]; then
            import_skill_file "$1" "${2:-}"
        else
            echo -e "${RED}Error: '$1' no es un directorio ni archivo válido${NC}"
            echo ""
            echo "Uso: $0 <source-dir> [categoria]"
            echo "     $0 --from <target-name>"
            echo "     $0 list-targets"
            exit 1
        fi
        ;;
esac
