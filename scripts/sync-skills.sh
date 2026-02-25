#!/bin/bash
# sync-skills.sh - Sincroniza skills con AUTO_INVOKE.md y genera symlinks multi-IDE
# Inspirado en la arquitectura de Alan (Gentleman Programming / Prowler)

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AI_CONFIG="$PROJECT_ROOT/.ai-config"
SKILLS_DIR="$AI_CONFIG/skills"

echo -e "${BLUE}=== Skill Sync Tool ===${NC}"
echo ""

# Funcion: Listar todos los skills con metadata
list_skills() {
    echo -e "${GREEN}Skills disponibles:${NC}"
    echo ""
    printf "%-35s %-50s\n" "SKILL" "DESCRIPTION"
    printf "%-35s %-50s\n" "-----" "-----------"

    while IFS= read -r -d '' skill_file; do
        skill_base="$(basename "$skill_file")"
        [ "$skill_base" = "_TEMPLATE.md" ] && continue

        skill_rel="${skill_file#$SKILLS_DIR/}"
        # SKILL.md in folder → use parent dir name; flat .md → strip extension
        if [ "$skill_base" = "SKILL.md" ]; then
            skill_name="${skill_rel%/SKILL.md}"
        else
            skill_name="${skill_rel%.md}"
        fi

        # Extraer descripcion del frontmatter
        description=$(sed -n '/^description:/,/^[a-z]/p' "$skill_file" | head -5 | grep -v "^description:" | grep -v "^[a-z]" | tr '\n' ' ' | cut -c1-50)

        printf "%-35s %-50s\n" "$skill_name" "${description:-No description}"
    done < <(find "$SKILLS_DIR" -type f \( -name "SKILL.md" -o -name "*.md" \) -print0 | sort -z)
}

# Funcion: Agregar scope a un skill
add_scope() {
    local skill_name="$1"
    local scope="$2"
    local skill_file="$SKILLS_DIR/$skill_name.md"

    if [ ! -f "$skill_file" ]; then
        if [ -f "$SKILLS_DIR/$skill_name/SKILL.md" ]; then
            skill_file="$SKILLS_DIR/$skill_name/SKILL.md"
        else
            skill_file=$(find "$SKILLS_DIR" -type f \( -name "$skill_name.md" -o -path "*/$skill_name/SKILL.md" \) | head -n 1)
        fi
    fi

    if [ -z "$skill_file" ] || [ ! -f "$skill_file" ]; then
        echo -e "${RED}Error: Skill '$skill_name' no encontrado${NC}"
        return 1
    fi

    # Verificar si ya tiene scope
    if grep -q "^scope:" "$skill_file"; then
        echo -e "${YELLOW}Skill '$skill_name' ya tiene scope definido${NC}"
        return 0
    fi

    # Agregar scope despues de metadata
    sed_inplace "/^metadata:/a\\  scope: [$scope]" "$skill_file"
    echo -e "${GREEN}Scope agregado a '$skill_name': $scope${NC}"
}

# Funcion: Generar symlinks para multiples IDEs
setup_symlinks() {
    echo -e "${BLUE}Generando symlinks multi-IDE...${NC}"

    local agents_md="$PROJECT_ROOT/AGENTS.md"
    local claude_md="$PROJECT_ROOT/CLAUDE.md"
    local gemini_md="$PROJECT_ROOT/GEMINI.md"
    local copilot_md="$PROJECT_ROOT/.github/copilot-instructions.md"

    # Crear AGENTS.md si no existe (fuente principal)
    if [ ! -f "$agents_md" ]; then
        echo -e "${YELLOW}Creando AGENTS.md base...${NC}"
        cat > "$agents_md" << 'EOF'
# Project Instructions for AI Agents

> This file is the source of truth for all AI assistants.

## Architecture

See `.ai-config/README.md` for full documentation.

## Available Skills

Load skills from `.ai-config/skills/` based on the task.

## Auto-Invoke Rules

See `.ai-config/AUTO_INVOKE.md` for action-to-skill mapping.

## Quick Reference

- **Frontend:** frontend-web, mantine-ui, tanstack-query
- **Backend Go:** chi-router, pgx-postgres, go-backend
- **Backend Python:** fastapi, jwt-auth
- **Rust/IoT:** rust-systems, tokio-async, mqtt-rumqttc
- **Databases:** timescaledb, redis-cache, sqlite-embedded
- **DevOps:** kubernetes, docker-containers, devops-infra
- **AI/ML:** langchain, ai-ml, pytorch, vector-db
EOF
    fi

    # Crear symlinks (with Windows fallback)
    if [ ! -f "$claude_md" ] || [ -L "$claude_md" ]; then
        rm -f "$claude_md" 2>/dev/null || true
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            cp "$agents_md" "$claude_md"
            echo -e "${GREEN}  CLAUDE.md <- AGENTS.md (copied, Windows fallback)${NC}"
        else
            ln -sf "AGENTS.md" "$claude_md"
            echo -e "${GREEN}  CLAUDE.md -> AGENTS.md${NC}"
        fi
    fi

    if [ ! -f "$gemini_md" ] || [ -L "$gemini_md" ]; then
        rm -f "$gemini_md" 2>/dev/null || true
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            cp "$agents_md" "$gemini_md"
            echo -e "${GREEN}  GEMINI.md <- AGENTS.md (copied, Windows fallback)${NC}"
        else
            ln -sf "AGENTS.md" "$gemini_md"
            echo -e "${GREEN}  GEMINI.md -> AGENTS.md${NC}"
        fi
    fi

    mkdir -p "$PROJECT_ROOT/.github"
    if [ ! -f "$copilot_md" ] || [ -L "$copilot_md" ]; then
        rm -f "$copilot_md" 2>/dev/null || true
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            cp "$agents_md" "$copilot_md"
            echo -e "${GREEN}  .github/copilot-instructions.md <- AGENTS.md (copied, Windows fallback)${NC}"
        else
            ln -sf "../AGENTS.md" "$copilot_md"
            echo -e "${GREEN}  .github/copilot-instructions.md -> AGENTS.md${NC}"
        fi
    fi

    echo -e "${GREEN}Symlinks creados exitosamente${NC}"
}

# Funcion: Validar skills (formato correcto)
validate_skills() {
    echo -e "${BLUE}Validando skills...${NC}"
    local errors=0

    while IFS= read -r -d '' skill_file; do
        skill_base="$(basename "$skill_file")"
        [ "$skill_base" = "_TEMPLATE.md" ] && continue

        skill_rel="${skill_file#$SKILLS_DIR/}"
        if [ "$skill_base" = "SKILL.md" ]; then
            skill_name="${skill_rel%/SKILL.md}"
        else
            skill_name="${skill_rel%.md}"
        fi

        # Verificar frontmatter
        if ! head -1 "$skill_file" | grep -q "^---"; then
            echo -e "${RED}  [$skill_name] Falta frontmatter YAML${NC}"
            errors=$((errors + 1))
            continue
        fi

        # Verificar campos requeridos
        if ! grep -q "^name:" "$skill_file"; then
            echo -e "${RED}  [$skill_name] Falta campo 'name'${NC}"
            errors=$((errors + 1))
        fi

        if ! grep -q "^description:" "$skill_file"; then
            echo -e "${RED}  [$skill_name] Falta campo 'description'${NC}"
            errors=$((errors + 1))
        fi

        # Verificar Related Skills
        if ! grep -q "^## Related Skills" "$skill_file"; then
            echo -e "${YELLOW}  [$skill_name] Falta seccion 'Related Skills'${NC}"
        fi
    done < <(find "$SKILLS_DIR" -type f -name "SKILL.md" -print0)

    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}Todos los skills son validos${NC}"
    else
        echo -e "${RED}Se encontraron $errors errores${NC}"
    fi
}

# Funcion: Generar resumen de skills para AGENTS.md
generate_summary() {
    echo -e "${BLUE}Generando resumen de skills...${NC}"

    local summary_file="$AI_CONFIG/SKILLS_SUMMARY.md"

    cat > "$summary_file" << 'EOF'
# Skills Summary

> Auto-generated. Do not edit manually.

## By Category
EOF

    for category in "frontend" "backend" "database" "infrastructure" "ai-ml" "testing" "mobile" "other"; do
        echo "" >> "$summary_file"
        category_title="$(echo "${category:0:1}" | tr '[:lower:]' '[:upper:]')${category:1}"
        echo "### $category_title" >> "$summary_file"

        case $category in
            frontend) pattern="frontend|mantine|astro|tanstack|zod|zustand" ;;
            backend) pattern="chi|pgx|go-backend|fastapi|jwt" ;;
            database) pattern="timescale|redis|sqlite|duckdb|postgres" ;;
            infrastructure) pattern="kubernetes|docker|devops|traefik|opentelemetry" ;;
            ai-ml) pattern="langchain|ai-ml|onnx|pytorch|scikit|mlflow|vector" ;;
            testing) pattern="playwright|vitest|test" ;;
            mobile) pattern="ionic|capacitor|mobile" ;;
            other) pattern="git|technical|power" ;;
        esac

        local count=0
        while IFS= read -r -d '' skill_file; do
            skill_rel="${skill_file#$SKILLS_DIR/}"
            skill_name="${skill_rel%/SKILL.md}"
            skill_base=$(basename "$skill_name")

            if echo "$skill_base" | grep -qE "$pattern"; then
                desc=$(grep -A2 "^description:" "$skill_file" | tail -1 | sed 's/^  //' | cut -c1-60)
                echo "- \`$skill_name\`: $desc" >> "$summary_file"
                count=$((count + 1))
            fi
        done < <(find "$SKILLS_DIR" -type f -name "SKILL.md" -print0)
    done

    echo -e "${GREEN}Resumen generado: $summary_file${NC}"
}

# Main
case "${1:-help}" in
    list)
        list_skills
        ;;
    validate)
        validate_skills
        ;;
    symlinks|setup)
        setup_symlinks
        ;;
    summary)
        generate_summary
        ;;
    scope)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Uso: $0 scope <skill-name> <scope>"
            echo "Ejemplo: $0 scope mantine-ui 'src/,components/'"
            exit 1
        fi
        add_scope "$2" "$3"
        ;;
    all)
        validate_skills
        echo ""
        generate_summary
        echo ""
        setup_symlinks
        ;;
    help|*)
        echo "Uso: $0 <comando>"
        echo ""
        echo "Comandos:"
        echo "  list      - Listar todos los skills disponibles"
        echo "  validate  - Validar formato de skills"
        echo "  symlinks  - Crear symlinks multi-IDE (CLAUDE.md, GEMINI.md, etc.)"
        echo "  summary   - Generar resumen de skills"
        echo "  scope     - Agregar scope a un skill"
        echo "  all       - Ejecutar validate + summary + symlinks"
        echo ""
        echo "Ejemplos:"
        echo "  $0 list"
        echo "  $0 validate"
        echo "  $0 scope mantine-ui 'src/,components/'"
        echo "  $0 all"
        ;;
esac
