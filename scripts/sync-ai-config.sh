#!/bin/bash
# =============================================================================
# SYNC-AI-CONFIG: Genera configuracion para diferentes AI CLIs
# =============================================================================
# Uso:
#   ./scripts/sync-ai-config.sh claude            # Solo Claude Code
#   ./scripts/sync-ai-config.sh claude merge      # Merge safe (append/update generated section)
#   ./scripts/sync-ai-config.sh opencode          # Solo OpenCode
#   ./scripts/sync-ai-config.sh cursor            # Solo Cursor
#   ./scripts/sync-ai-config.sh all               # Todos
#   ./scripts/sync-ai-config.sh all merge         # Todos (Claude in merge mode)
# =============================================================================

set -e

source "$(cd "$(dirname "$0")" && pwd)/../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AI_CONFIG_DIR="$PROJECT_DIR/.ai-config"

echo -e "${CYAN}=== Sync AI Config ===${NC}"

# =============================================================================
# Funciones de generacion
# =============================================================================

generate_claude() {
    echo -e "${YELLOW}Generating Claude Code config...${NC}"

    # MODE: overwrite (default) or merge/append when caller passes 'merge' or '--merge'
    if [[ "$1" == "merge" || "$1" == "--merge" ]]; then
        MERGE_MODE=1
    else
        MERGE_MODE=0
    fi

    # Crear directorio .claude si no existe
    mkdir -p "$PROJECT_DIR/.claude"

    # If file exists and MERGE_MODE requested -> append/update generated section
    if [[ -f "$PROJECT_DIR/CLAUDE.md" && $MERGE_MODE -eq 1 ]]; then
        echo -e "${YELLOW}CLAUDE.md exists — performing safe merge (append/update generated section)${NC}"
        backup_if_exists "$PROJECT_DIR/CLAUDE.md"

        # Prepare generated snippet
        genfile="$(mktemp)"
        cat > "$genfile" << 'HEADER'

## Auto-generated from .ai-config/

HEADER
        if [[ -f "$AI_CONFIG_DIR/prompts/base.md" ]]; then
            sed -n '1,200p' "$AI_CONFIG_DIR/prompts/base.md" >> "$genfile" || true
            echo -e "\n---\n" >> "$genfile"
        fi

        echo -e "## Agentes Disponibles\n" >> "$genfile"
        while IFS= read -r -d '' agent; do
            [[ "$(basename "$agent")" == "_TEMPLATE.md" ]] && continue
            name=$(grep "^name:" "$agent" | head -1 | sed 's/name: *//')
            [[ -z "$name" ]] && continue
            desc=$(grep "^description:" "$agent" | head -1 | sed 's/description: *//')
            echo "- **$name**: $desc" >> "$genfile"
        done < <(find "$AI_CONFIG_DIR/agents" -type f -name "*.md" -print0)

        echo -e "\n## Skills Disponibles\n" >> "$genfile"
        while IFS= read -r -d '' skill; do
            name=$(grep "^name:" "$skill" | head -1 | sed 's/name: *//')
            [[ -z "$name" ]] && continue
            echo "- $name" >> "$genfile"
        done < <(find "$AI_CONFIG_DIR/skills" -type f -name "SKILL.md" -print0)

        # If existing file already contains our auto-generated marker, replace that section
        if grep -q "^## Auto-generated from \.ai-config/" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
            # Delete from marker to EOF, then append generated content
            awk 'BEGIN{p=1} /## Auto-generated from \.ai-config\//{p=0; exit} p{print}' "$PROJECT_DIR/CLAUDE.md" > "${PROJECT_DIR}/.claude.tmp" || true
            cat "${PROJECT_DIR}/.claude.tmp" > "$PROJECT_DIR/CLAUDE.md"
            cat "$genfile" >> "$PROJECT_DIR/CLAUDE.md"
            rm -f "${PROJECT_DIR}/.claude.tmp"
        else
            # Append generated section to the end (safe - won't overwrite custom content)
            cat "$genfile" >> "$PROJECT_DIR/CLAUDE.md"
        fi

        rm -f "$genfile"
        echo -e "${GREEN}Merged CLAUDE.md (auto-generated section updated)${NC}"
        return
    fi

    # Default behavior: overwrite (prompt if exists)
    if [[ -f "$PROJECT_DIR/CLAUDE.md" ]]; then
        echo -e "${YELLOW}CLAUDE.md already exists. Overwrite? [y/N]${NC}"
        read -r OVERWRITE
        if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]]; then
            echo -e "${GREEN}Skipping CLAUDE.md${NC}"
            return
        fi
    fi

    # Backup existing file before overwrite
    backup_if_exists "$PROJECT_DIR/CLAUDE.md"

    # Generar CLAUDE.md combinando prompts y agentes (overwrite)
    cat > "$PROJECT_DIR/CLAUDE.md" << 'HEADER'
# Claude Code Instructions

> Auto-generated from .ai-config/

HEADER

    # Agregar prompt base
    if [[ -f "$AI_CONFIG_DIR/prompts/base.md" ]]; then
        cat "$AI_CONFIG_DIR/prompts/base.md" >> "$PROJECT_DIR/CLAUDE.md"
        echo -e "\n---\n" >> "$PROJECT_DIR/CLAUDE.md"
    fi

    # Agregar agentes disponibles
    echo -e "## Agentes Disponibles\n" >> "$PROJECT_DIR/CLAUDE.md"
    while IFS= read -r -d '' agent; do
        [[ "$(basename "$agent")" == "_TEMPLATE.md" ]] && continue
        name=$(grep "^name:" "$agent" | head -1 | sed 's/name: *//')
        [[ -z "$name" ]] && continue
        desc=$(grep "^description:" "$agent" | head -1 | sed 's/description: *//')
        echo "- **$name**: $desc" >> "$PROJECT_DIR/CLAUDE.md"
    done < <(find "$AI_CONFIG_DIR/agents" -type f -name "*.md" -print0)

    # Agregar skills disponibles
    echo -e "\n## Skills Disponibles\n" >> "$PROJECT_DIR/CLAUDE.md"
    while IFS= read -r -d '' skill; do
        name=$(grep "^name:" "$skill" | head -1 | sed 's/name: *//')
        [[ -z "$name" ]] && continue
        echo "- $name" >> "$PROJECT_DIR/CLAUDE.md"
    done < <(find "$AI_CONFIG_DIR/skills" -type f -name "SKILL.md" -print0)

    echo -e "${GREEN}Generated CLAUDE.md${NC}"
}

generate_opencode() {
    echo -e "${YELLOW}Generating OpenCode config...${NC}"

    # Backup existing file before overwrite
    backup_if_exists "$PROJECT_DIR/AGENTS.md"

    # Header
    cat > "$PROJECT_DIR/AGENTS.md" << 'HEADER'
# AI Agents & Skills

> Auto-generated catalog. Do not edit manually.
> Run: ./scripts/sync-ai-config.sh opencode

HEADER

    # Base prompt (rules, workflow, etc.)
    if [[ -f "$AI_CONFIG_DIR/prompts/base.md" ]]; then
        cat "$AI_CONFIG_DIR/prompts/base.md" >> "$PROJECT_DIR/AGENTS.md"
        echo -e "\n---\n" >> "$PROJECT_DIR/AGENTS.md"
    fi

    # Agents catalog grouped by category
    echo -e "## Available Agents\n" >> "$PROJECT_DIR/AGENTS.md"
    local prev_cat=""
    while IFS= read -r -d '' agent; do
        [[ "$(basename "$agent")" == "_TEMPLATE.md" ]] && continue
        name=$(grep "^name:" "$agent" | head -1 | sed 's/name: *//')
        [[ -z "$name" ]] && continue
        desc=$(grep "^description:" "$agent" | head -1 | sed 's/description: *//')
        rel="${agent#$AI_CONFIG_DIR/agents/}"
        cat_dir=$(dirname "$rel")
        if [[ "$cat_dir" != "$prev_cat" ]]; then
            cat_label=$(echo "$cat_dir" | awk '{print toupper(substr($0,1,1)) substr($0,2)}' | tr '-' ' ')
            echo -e "\n### $cat_label\n" >> "$PROJECT_DIR/AGENTS.md"
            prev_cat="$cat_dir"
        fi
        echo "- **$name**: $desc" >> "$PROJECT_DIR/AGENTS.md"
    done < <(find "$AI_CONFIG_DIR/agents" -type f -name "*.md" -print0 | sort -z)

    # Skills catalog grouped by category
    echo -e "\n---\n\n## Available Skills\n" >> "$PROJECT_DIR/AGENTS.md"
    echo "> See \`.ai-config/AUTO_INVOKE.md\` for auto-loading rules." >> "$PROJECT_DIR/AGENTS.md"
    echo "" >> "$PROJECT_DIR/AGENTS.md"
    local prev_skill_cat=""
    while IFS= read -r -d '' skill; do
        name=$(grep "^name:" "$skill" | head -1 | sed 's/name: *//')
        [[ -z "$name" ]] && continue
        desc=$(grep "^description:" "$skill" | head -1 | sed 's/description: *//')
        rel="${skill#$AI_CONFIG_DIR/skills/}"
        cat_dir=$(echo "$rel" | cut -d'/' -f1)
        if [[ "$cat_dir" != "$prev_skill_cat" ]]; then
            cat_label=$(echo "$cat_dir" | awk '{print toupper(substr($0,1,1)) substr($0,2)}' | tr '-' ' ')
            echo -e "\n### $cat_label\n" >> "$PROJECT_DIR/AGENTS.md"
            prev_skill_cat="$cat_dir"
        fi
        echo "- **$name**: $desc" >> "$PROJECT_DIR/AGENTS.md"
    done < <(find "$AI_CONFIG_DIR/skills" -type f -name "SKILL.md" -print0 | sort -z)

    echo -e "${GREEN}Generated AGENTS.md${NC}"
}

generate_cursor() {
    echo -e "${YELLOW}Generating Cursor config...${NC}"

    # Backup existing file before overwrite
    backup_if_exists "$PROJECT_DIR/.cursorrules"

    # Generar .cursorrules
    cat > "$PROJECT_DIR/.cursorrules" << 'HEADER'
# Cursor Rules
# Auto-generated from .ai-config/

HEADER

    # Agregar prompt base
    if [[ -f "$AI_CONFIG_DIR/prompts/base.md" ]]; then
        # Extract the "Reglas Criticas" section until the next top-level heading
        awk '/^## Reglas Cr.ticas/,/^## [^R]/' "$AI_CONFIG_DIR/prompts/base.md" | sed '$d' >> "$PROJECT_DIR/.cursorrules"
    fi

    echo -e "${GREEN}Generated .cursorrules${NC}"
}

generate_aider() {
    echo -e "${YELLOW}Generating Aider config...${NC}"

    # Backup existing file before overwrite
    backup_if_exists "$PROJECT_DIR/.aider.conf.yml"

    # Generar .aider.conf.yml
    cat > "$PROJECT_DIR/.aider.conf.yml" << 'EOF'
# Aider Configuration
# Auto-generated from .ai-config/

# Model settings
model: claude-3-5-sonnet

# Git settings
auto-commits: false
dirty-commits: false

# Conventions
EOF

    # Agregar convenciones del prompt base
    echo "conventions:" >> "$PROJECT_DIR/.aider.conf.yml"
    echo "  - No AI attribution in commits" >> "$PROJECT_DIR/.aider.conf.yml"
    echo "  - Conventional commits format" >> "$PROJECT_DIR/.aider.conf.yml"
    echo "  - Run CI-Local before push" >> "$PROJECT_DIR/.aider.conf.yml"

    echo -e "${GREEN}Generated .aider.conf.yml${NC}"
}

generate_continue() {
    echo -e "${YELLOW}Generating Continue.dev config...${NC}"

    echo -e "${YELLOW}WARNING: This will modify $HOME/.continue/config.json (global config)${NC}"
    if [[ -f "$HOME/.continue/config.json" ]]; then
        echo -e "${YELLOW}  Existing config found. Skipping to avoid overwrite.${NC}"
        echo -e "${YELLOW}  Delete $HOME/.continue/config.json manually to regenerate.${NC}"
        return 0
    fi

    mkdir -p "$HOME/.continue"

    cat > "$HOME/.continue/config.json" << 'EOF'
{
  "models": [
    {
      "title": "Claude Sonnet",
      "provider": "anthropic",
      "model": "claude-3-5-sonnet-20241022"
    }
  ],
  "customCommands": [
    {
      "name": "review",
      "description": "Code review",
      "prompt": "Review this code for quality, security, and best practices."
    }
  ]
}
EOF
    echo -e "${GREEN}Generated ~/.continue/config.json${NC}"
}

# =============================================================================
# Main
# =============================================================================

case "${1:-all}" in
    claude)
        generate_claude "$2"
        ;;
    opencode)
        generate_opencode
        ;;
    cursor)
        generate_cursor
        ;;
    aider)
        generate_aider
        ;;
    continue)
        generate_continue
        ;;
    all)
        generate_claude "$2"
        generate_opencode
        generate_cursor
        generate_aider
        ;;
    *)
        echo "Usage: $0 {claude|opencode|cursor|aider|continue|all}"
        exit 1
        ;;
esac

echo -e ""
echo -e "${GREEN}AI config sync complete!${NC}"
echo -e ""
echo -e "Generated files:"
[[ -f "$PROJECT_DIR/CLAUDE.md" ]] && echo "  - CLAUDE.md (Claude Code)"
[[ -f "$PROJECT_DIR/AGENTS.md" ]] && echo "  - AGENTS.md (OpenCode)"
[[ -f "$PROJECT_DIR/.cursorrules" ]] && echo "  - .cursorrules (Cursor)"
[[ -f "$PROJECT_DIR/.aider.conf.yml" ]] && echo "  - .aider.conf.yml (Aider)"
echo ""
