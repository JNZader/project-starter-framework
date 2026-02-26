#!/bin/bash
# =============================================================================
# setup-global.sh - Automated Global CLI Setup
# =============================================================================
# Configures AI CLIs (Claude, OpenCode, Codex, Copilot, Gemini) at $HOME level.
# Installs CLIs, hooks, commands, skills, agents, SDD orchestration, MCP servers.
#
# Usage:
#   ./scripts/setup-global.sh                 # Interactive with smart defaults
#   ./scripts/setup-global.sh --auto          # Non-interactive, install everything
#   ./scripts/setup-global.sh --dry-run       # Preview without changes
#   ./scripts/setup-global.sh --clis=claude,gemini --features=hooks,sdd
#   ./scripts/setup-global.sh --skip-install  # Configure only
# =============================================================================

set -euo pipefail

# Resolve script and framework directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared library
# shellcheck source=../lib/common.sh
source "$FRAMEWORK_DIR/lib/common.sh"

TEMPLATES_DIR="$FRAMEWORK_DIR/templates/global"

# =============================================================================
# Argument Parsing
# =============================================================================
DRY_RUN=false
AUTO_MODE=false
SKIP_INSTALL=false
OPT_CLIS=""
OPT_FEATURES=""
DRY_RUN_ACTIONS=()

show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Automated Global CLI Setup — configures AI CLIs at \$HOME level."
    echo ""
    echo "Options:"
    echo "  --auto          Non-interactive (install + configure everything)"
    echo "  --dry-run       Preview without making changes"
    echo "  --clis=X,Y      Select specific CLIs (claude,opencode,codex,copilot,gemini)"
    echo "  --features=X,Y  Select features (hooks,commands,skills,agents,sdd,mcp)"
    echo "  --skip-install  Configure only, don't install CLIs"
    echo "  --help          Show this help message"
}

for arg in "$@"; do
    case "$arg" in
        --auto)        AUTO_MODE=true ;;
        --dry-run)     DRY_RUN=true ;;
        --skip-install) SKIP_INSTALL=true ;;
        --clis=*)      OPT_CLIS="${arg#--clis=}" ;;
        --features=*)  OPT_FEATURES="${arg#--features=}" ;;
        --help|-h)     show_help; exit 0 ;;
        *)             echo "Unknown option: $arg"; show_help; exit 1 ;;
    esac
done

# =============================================================================
# Dry-Run Helpers (same pattern as init-project.sh)
# =============================================================================
run_cmd() {
    local desc="$1"; shift
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would execute: $*"
        DRY_RUN_ACTIONS+=("$desc")
    else
        "$@"
    fi
}

run_copy() {
    local src="$1" dest="$2"; shift 2
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would copy: $src -> $dest"
        DRY_RUN_ACTIONS+=("Copy $src -> $dest")
    else
        cp "$@" "$src" "$dest"
    fi
}

run_mkdir() {
    local dir="$1"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would create directory: $dir"
        DRY_RUN_ACTIONS+=("Create directory $dir")
    else
        mkdir -p "$dir"
    fi
}

run_write() {
    local dest="$1" desc="${2:-$dest}"
    if [[ "$DRY_RUN" == true ]]; then
        cat > /dev/null  # consume stdin
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would write file: $dest"
        DRY_RUN_ACTIONS+=("Write $desc")
    else
        cat > "$dest"
    fi
}

# =============================================================================
# Detection — Check installed tools
# =============================================================================
declare -A TOOL_STATUS

detect_tools() {
    log_step "Detecting installed tools..."

    local tools=(node npm python3 docker engram claude opencode codex copilot gemini)
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            TOOL_STATUS[$tool]="installed"
        else
            TOOL_STATUS[$tool]="missing"
        fi
    done

    # Docker MCP check
    if command -v docker &>/dev/null && docker mcp version &>/dev/null 2>&1; then
        TOOL_STATUS[docker-mcp]="installed"
    else
        TOOL_STATUS[docker-mcp]="missing"
    fi
}

show_status_table() {
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║              Environment Status                          ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════╣${NC}"

    local categories=(
        "Prerequisites:node,npm,python3,docker"
        "AI CLIs:claude,opencode,codex,copilot,gemini"
        "MCP:engram,docker-mcp"
    )

    for category in "${categories[@]}"; do
        local label="${category%%:*}"
        local items="${category#*:}"
        echo -e "${YELLOW}║${NC}  ${CYAN}${label}${NC}"

        IFS=',' read -ra tool_list <<< "$items"
        for tool in "${tool_list[@]}"; do
            local status="${TOOL_STATUS[$tool]:-missing}"
            if [[ "$status" == "installed" ]]; then
                printf "  ${GREEN}●${NC} %-18s ${GREEN}installed${NC}\n" "$tool"
            else
                printf "  ${YELLOW}○${NC} %-18s ${YELLOW}missing${NC}\n" "$tool"
            fi
        done
    done

    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# =============================================================================
# Interactive Selection Menus
# =============================================================================
SELECTED_CLIS=()
SELECTED_FEATURES=()

select_clis() {
    if [[ -n "$OPT_CLIS" ]]; then
        IFS=',' read -ra SELECTED_CLIS <<< "$OPT_CLIS"
        return
    fi

    if [[ "$AUTO_MODE" == true ]]; then
        SELECTED_CLIS=(claude opencode codex copilot gemini)
        return
    fi

    echo -e "${CYAN}Select CLIs to configure:${NC}"
    echo -e "  1) All (claude, opencode, codex, copilot, gemini)"
    echo -e "  2) Claude Code only"
    echo -e "  3) Claude + OpenCode"
    echo -e "  4) Custom selection"
    echo ""
    read -rp "  Option [1]: " cli_choice
    cli_choice="${cli_choice:-1}"

    case "$cli_choice" in
        1) SELECTED_CLIS=(claude opencode codex copilot gemini) ;;
        2) SELECTED_CLIS=(claude) ;;
        3) SELECTED_CLIS=(claude opencode) ;;
        4)
            echo -e "  Enter CLIs separated by commas (claude,opencode,codex,copilot,gemini):"
            read -rp "  > " custom_clis
            IFS=',' read -ra SELECTED_CLIS <<< "$custom_clis"
            ;;
        *) SELECTED_CLIS=(claude opencode codex copilot gemini) ;;
    esac

    echo -e "  ${GREEN}Selected:${NC} ${SELECTED_CLIS[*]}"
    echo ""
}

select_features() {
    if [[ -n "$OPT_FEATURES" ]]; then
        IFS=',' read -ra SELECTED_FEATURES <<< "$OPT_FEATURES"
        return
    fi

    if [[ "$AUTO_MODE" == true ]]; then
        SELECTED_FEATURES=(hooks commands skills agents sdd mcp)
        return
    fi

    echo -e "${CYAN}Select features to configure:${NC}"
    echo -e "  1) All (hooks, commands, skills, agents, sdd, mcp)"
    echo -e "  2) Essential (hooks, commands, sdd)"
    echo -e "  3) Custom selection"
    echo ""
    read -rp "  Option [1]: " feat_choice
    feat_choice="${feat_choice:-1}"

    case "$feat_choice" in
        1) SELECTED_FEATURES=(hooks commands skills agents sdd mcp) ;;
        2) SELECTED_FEATURES=(hooks commands sdd) ;;
        3)
            echo -e "  Enter features separated by commas (hooks,commands,skills,agents,sdd,mcp):"
            read -rp "  > " custom_feats
            IFS=',' read -ra SELECTED_FEATURES <<< "$custom_feats"
            ;;
        *) SELECTED_FEATURES=(hooks commands skills agents sdd mcp) ;;
    esac

    echo -e "  ${GREEN}Selected:${NC} ${SELECTED_FEATURES[*]}"
    echo ""
}

has_feature() {
    local feature="$1"
    for f in "${SELECTED_FEATURES[@]}"; do
        [[ "$f" == "$feature" ]] && return 0
    done
    return 1
}

has_cli() {
    local cli="$1"
    for c in "${SELECTED_CLIS[@]}"; do
        [[ "$c" == "$cli" ]] && return 0
    done
    return 1
}

# =============================================================================
# Install Prerequisites
# =============================================================================
install_prerequisites() {
    if [[ "$SKIP_INSTALL" == true ]]; then
        log_info "Skipping installs (--skip-install)"
        return
    fi

    log_step "Installing prerequisites..."

    # Node.js via nvm
    if [[ "${TOOL_STATUS[node]}" == "missing" ]]; then
        log_info "Node.js not found — installing via nvm..."
        if ! command -v nvm &>/dev/null && [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
            run_cmd "Install nvm" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
        fi
        if [[ "$DRY_RUN" == false ]]; then
            export NVM_DIR="$HOME/.nvm"
            # shellcheck source=/dev/null
            [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
            run_cmd "Install Node.js LTS" nvm install --lts
        else
            DRY_RUN_ACTIONS+=("Install Node.js LTS via nvm")
        fi
    else
        log_ok "Node.js already installed"
    fi

    # Python3 check (no install — too platform-specific)
    if [[ "${TOOL_STATUS[python3]}" == "missing" ]]; then
        log_warn "python3 not found — needed for JSON merge. Install manually."
    else
        log_ok "python3 available"
    fi
}

# =============================================================================
# Install CLIs
# =============================================================================
install_clis() {
    if [[ "$SKIP_INSTALL" == true ]]; then
        log_info "Skipping CLI installs (--skip-install)"
        return
    fi

    log_step "Installing AI CLIs..."

    if has_cli claude && [[ "${TOOL_STATUS[claude]:-missing}" == "missing" ]]; then
        log_info "Installing Claude Code..."
        run_cmd "Install Claude Code" npm install -g @anthropic-ai/claude-code
    elif has_cli claude; then
        log_ok "Claude Code already installed"
    fi

    if has_cli opencode && [[ "${TOOL_STATUS[opencode]:-missing}" == "missing" ]]; then
        log_info "Installing OpenCode..."
        run_cmd "Install OpenCode" npm install -g opencode-ai
    elif has_cli opencode; then
        log_ok "OpenCode already installed"
    fi

    if has_cli codex && [[ "${TOOL_STATUS[codex]:-missing}" == "missing" ]]; then
        log_info "Installing Codex CLI..."
        run_cmd "Install Codex CLI" npm install -g @openai/codex
    elif has_cli codex; then
        log_ok "Codex CLI already installed"
    fi

    if has_cli copilot && [[ "${TOOL_STATUS[copilot]:-missing}" == "missing" ]]; then
        log_info "Installing GitHub Copilot CLI..."
        run_cmd "Install Copilot CLI" npm install -g @githubnext/github-copilot-cli
    elif has_cli copilot; then
        log_ok "Copilot CLI already installed"
    fi

    if has_cli gemini && [[ "${TOOL_STATUS[gemini]:-missing}" == "missing" ]]; then
        log_info "Installing Gemini CLI..."
        run_cmd "Install Gemini CLI" npm install -g @anthropic-ai/gemini-cli 2>/dev/null || \
            run_cmd "Install Gemini CLI (npm)" npm install -g gemini-cli 2>/dev/null || \
            log_warn "Could not install Gemini CLI automatically. Install manually."
    elif has_cli gemini; then
        log_ok "Gemini CLI already installed"
    fi
}

# =============================================================================
# Install Engram
# =============================================================================
install_engram() {
    if [[ "$SKIP_INSTALL" == true ]] || ! has_feature mcp; then
        return
    fi

    log_step "Installing Engram..."

    if [[ "${TOOL_STATUS[engram]:-missing}" == "installed" ]]; then
        log_ok "Engram already installed"
        return
    fi

    # Try brew first
    if command -v brew &>/dev/null; then
        log_info "Installing Engram via Homebrew..."
        run_cmd "Install Engram" brew install anthropics/tap/engram 2>/dev/null || {
            log_warn "Brew tap not found, trying binary download..."
            install_engram_binary
        }
    else
        install_engram_binary
    fi
}

install_engram_binary() {
    local os arch url
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        arm64)   arch="arm64" ;;
    esac

    url="https://github.com/anthropics/engram/releases/latest/download/engram-${os}-${arch}"
    log_info "Downloading Engram binary: $url"

    if [[ "$DRY_RUN" == true ]]; then
        DRY_RUN_ACTIONS+=("Download Engram binary from $url to /usr/local/bin/engram")
    else
        curl -fsSL "$url" -o /tmp/engram && chmod +x /tmp/engram
        if [[ -w /usr/local/bin ]]; then
            mv /tmp/engram /usr/local/bin/engram
        else
            sudo mv /tmp/engram /usr/local/bin/engram
        fi
        log_ok "Engram installed to /usr/local/bin/engram"
    fi
}

# =============================================================================
# JSON Merge via Python3
# =============================================================================
merge_json() {
    local template="$1" target="$2" merge_strategy="${3:-deep}"

    if [[ ! -f "$target" ]]; then
        # No existing file — just copy template
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${CYAN}[DRY-RUN]${NC} Would create: $target (from template)"
            DRY_RUN_ACTIONS+=("Create $target from template")
        else
            cp "$template" "$target"
            log_ok "Created $target"
        fi
        return
    fi

    if ! command -v python3 &>/dev/null; then
        log_warn "python3 not available — cannot merge JSON. Skipping $target"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would merge: $template -> $target (strategy: $merge_strategy)"
        DRY_RUN_ACTIONS+=("Merge $template into $target ($merge_strategy)")
        return
    fi

    backup_if_exists "$target"

    python3 << PYEOF
import json, sys

def deep_merge(base, override):
    """Deep merge override into base. Lists are unioned by value for permissions."""
    for key, val in override.items():
        if key in base:
            if isinstance(base[key], dict) and isinstance(val, dict):
                deep_merge(base[key], val)
            elif isinstance(base[key], list) and isinstance(val, list):
                # Union: add items not already present
                existing = set(str(x) for x in base[key])
                for item in val:
                    if str(item) not in existing:
                        base[key].append(item)
                        existing.add(str(item))
            else:
                base[key] = val
        else:
            base[key] = val
    return base

def hooks_merge(base, override):
    """Merge hooks by matcher dedup, permissions by union."""
    for key, val in override.items():
        if key == "hooks" and isinstance(val, dict) and isinstance(base.get("hooks"), dict):
            for event, hook_list in val.items():
                if event not in base["hooks"]:
                    base["hooks"][event] = hook_list
                    continue
                # Dedup by matcher
                existing_matchers = {}
                for i, entry in enumerate(base["hooks"][event]):
                    m = entry.get("matcher", "__default__")
                    existing_matchers[m] = i
                for entry in hook_list:
                    m = entry.get("matcher", "__default__")
                    if m not in existing_matchers:
                        base["hooks"][event].append(entry)
        elif key == "permissions" and isinstance(val, dict) and isinstance(base.get("permissions"), dict):
            for perm_type, perm_list in val.items():
                if perm_type not in base["permissions"]:
                    base["permissions"][perm_type] = perm_list
                elif isinstance(perm_list, list) and isinstance(base["permissions"][perm_type], list):
                    existing = set(base["permissions"][perm_type])
                    for item in perm_list:
                        if item not in existing:
                            base["permissions"][perm_type].append(item)
                            existing.add(item)
        elif key in base:
            if isinstance(base[key], dict) and isinstance(val, dict):
                deep_merge(base[key], val)
            else:
                base[key] = val
        else:
            base[key] = val
    return base

try:
    with open("$target", "r") as f:
        base = json.load(f)
    with open("$template", "r") as f:
        override = json.load(f)

    if "$merge_strategy" == "hooks":
        result = hooks_merge(base, override)
    else:
        result = deep_merge(base, override)

    with open("$target", "w") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print("  \033[0;32m[OK]\033[0m   Merged $target")
except Exception as e:
    print(f"  \033[0;31m[FAIL]\033[0m Failed to merge $target: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
}

# =============================================================================
# Markdown Marker Merge
# =============================================================================
# Merges generated content into a markdown file using a marker comment.
# Content above the marker is preserved. Content from marker to EOF is replaced.
# =============================================================================
merge_markdown() {
    local target="$1" generated_content="$2" marker="${3:-## Auto-generated by setup-global}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would merge markdown into: $target"
        DRY_RUN_ACTIONS+=("Merge generated section into $target")
        return
    fi

    if [[ ! -f "$target" ]]; then
        # New file — write marker + content
        {
            echo ""
            echo "$marker"
            echo ""
            echo "$generated_content"
        } > "$target"
        log_ok "Created $target"
        return
    fi

    backup_if_exists "$target"

    if grep -q "^${marker}$" "$target" 2>/dev/null; then
        # Replace from marker to EOF
        local tmpfile
        tmpfile="$(mktemp)"
        awk -v marker="$marker" 'BEGIN{p=1} $0==marker{p=0; exit} p{print}' "$target" > "$tmpfile"
        {
            cat "$tmpfile"
            echo "$marker"
            echo ""
            echo "$generated_content"
        } > "$target"
        rm -f "$tmpfile"
        log_ok "Updated generated section in $target"
    else
        # Append marker + content
        {
            echo ""
            echo "$marker"
            echo ""
            echo "$generated_content"
        } >> "$target"
        log_ok "Appended generated section to $target"
    fi
}

# =============================================================================
# Sync helpers
# =============================================================================
# Copy skills preserving directory structure
sync_skills_to_dir() {
    local src_dir="$1" dest_dir="$2"

    if [[ ! -d "$src_dir" ]]; then
        log_warn "Skills source not found: $src_dir"
        return
    fi

    run_mkdir "$dest_dir"

    if [[ "$DRY_RUN" == true ]]; then
        local count
        count=$(find "$src_dir" -type f -name "*.md" | wc -l)
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would copy $count skill files to $dest_dir"
        DRY_RUN_ACTIONS+=("Copy $count skill files to $dest_dir")
    else
        cp -r "$src_dir"/* "$dest_dir"/ 2>/dev/null || true
        log_ok "Synced skills to $dest_dir"
    fi
}

# Copy SDD skills (9 directories)
sync_sdd_skills() {
    local dest_dir="$1"
    local sdd_src="$FRAMEWORK_DIR/skills/workflow"

    if [[ ! -d "$sdd_src" ]]; then
        # Try alternate location
        sdd_src="$FRAMEWORK_DIR/skills"
    fi

    run_mkdir "$dest_dir"

    local sdd_phases=(sdd-init sdd-explore sdd-propose sdd-spec sdd-design sdd-tasks sdd-apply sdd-verify sdd-archive)
    local found=0

    for phase in "${sdd_phases[@]}"; do
        # Search in skills tree for the directory
        local skill_dir
        skill_dir=$(find "$FRAMEWORK_DIR/skills" -type d -name "$phase" 2>/dev/null | head -1)

        if [[ -n "$skill_dir" && -d "$skill_dir" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "  ${CYAN}[DRY-RUN]${NC} Would copy SDD skill: $phase"
                DRY_RUN_ACTIONS+=("Copy SDD skill $phase to $dest_dir/$phase")
            else
                cp -r "$skill_dir" "$dest_dir/$phase" 2>/dev/null || true
            fi
            found=$((found + 1))
        fi
    done

    if [[ $found -gt 0 ]]; then
        log_ok "Synced $found SDD skills to $dest_dir"
    else
        log_warn "No SDD skill directories found in $FRAMEWORK_DIR/skills"
    fi
}

# Flatten agents: category/agent.md -> prefix-agent.md
sync_agents_to_flat_dir() {
    local src_dir="$1" dest_dir="$2"

    if [[ ! -d "$src_dir" ]]; then
        log_warn "Agents source not found: $src_dir"
        return
    fi

    run_mkdir "$dest_dir"

    if [[ "$DRY_RUN" == true ]]; then
        local count
        count=$(find "$src_dir" -type f -name "*.md" ! -name "_TEMPLATE.md" | wc -l)
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would flatten $count agent files to $dest_dir"
        DRY_RUN_ACTIONS+=("Flatten $count agents to $dest_dir")
        return
    fi

    while IFS= read -r -d '' agent_file; do
        local rel_path="${agent_file#"$src_dir"/}"
        local category="${rel_path%%/*}"
        local filename="${rel_path##*/}"

        # Skip templates
        [[ "$filename" == "_TEMPLATE.md" ]] && continue

        if [[ "$rel_path" == */* ]]; then
            # Nested: category/agent.md -> category-agent.md
            cp "$agent_file" "$dest_dir/${category}-${filename}"
        else
            # Top-level agent
            cp "$agent_file" "$dest_dir/$filename"
        fi
    done < <(find "$src_dir" -type f -name "*.md" -print0)

    log_ok "Flattened agents to $dest_dir"
}

# =============================================================================
# Per-CLI Configuration Functions
# =============================================================================

configure_claude() {
    log_step "Configuring Claude Code (~/.claude/)..."
    local claude_dir="$HOME/.claude"
    run_mkdir "$claude_dir"

    # Settings merge (hooks by matcher dedup, permissions by union)
    if has_feature hooks; then
        merge_json "$TEMPLATES_DIR/claude-settings.json" "$claude_dir/settings.json" "hooks"
    fi

    # Commands
    if has_feature commands && [[ -d "$FRAMEWORK_DIR/commands" ]]; then
        run_mkdir "$claude_dir/commands"
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${CYAN}[DRY-RUN]${NC} Would copy commands to $claude_dir/commands/"
            DRY_RUN_ACTIONS+=("Copy commands to $claude_dir/commands/")
        else
            cp -r "$FRAMEWORK_DIR/commands"/* "$claude_dir/commands"/ 2>/dev/null || true
            log_ok "Synced commands to $claude_dir/commands/"
        fi
    fi

    # Skills
    if has_feature skills && [[ -d "$FRAMEWORK_DIR/skills" ]]; then
        sync_skills_to_dir "$FRAMEWORK_DIR/skills" "$claude_dir/skills"
    fi

    # SDD Skills
    if has_feature sdd; then
        sync_sdd_skills "$claude_dir/skills"

        # SDD orchestrator section in CLAUDE.md
        if [[ -f "$TEMPLATES_DIR/sdd-orchestrator-claude.md" ]]; then
            local sdd_content
            sdd_content=$(cat "$TEMPLATES_DIR/sdd-orchestrator-claude.md")
            merge_markdown "$claude_dir/CLAUDE.md" "$sdd_content" "## Spec-Driven Development (SDD) Orchestrator"
        fi
    fi

    log_ok "Claude Code configured"
}

configure_opencode() {
    log_step "Configuring OpenCode (~/.config/opencode/)..."
    local opencode_dir="$HOME/.config/opencode"
    run_mkdir "$opencode_dir"

    # JSON merge (MCP + agents + permissions)
    merge_json "$TEMPLATES_DIR/opencode-config.json" "$opencode_dir/opencode.json" "deep"

    # Agents (flatten category/agent.md -> prefix-agent.md)
    if has_feature agents && [[ -d "$FRAMEWORK_DIR/agents" ]]; then
        sync_agents_to_flat_dir "$FRAMEWORK_DIR/agents" "$opencode_dir/agents"
    fi

    # Skills (flatten with category prefix)
    if has_feature skills && [[ -d "$FRAMEWORK_DIR/skills" ]]; then
        sync_agents_to_flat_dir "$FRAMEWORK_DIR/skills" "$opencode_dir/skills"
    fi

    # AGENTS.md (overwrite — auto-generated)
    if has_feature agents || has_feature sdd; then
        local agents_content=""
        agents_content+="# OpenCode Agents & Skills\n\n"
        agents_content+="Auto-generated by setup-global.sh. Do not edit manually.\n\n"

        # Add agent catalog if script exists
        if [[ -f "$FRAMEWORK_DIR/scripts/generate-agents-catalog.sh" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                agents_content+="(Agent catalog would be generated here)\n"
            else
                local catalog
                catalog=$("$FRAMEWORK_DIR/scripts/generate-agents-catalog.sh" 2>/dev/null || echo "")
                if [[ -n "$catalog" ]]; then
                    agents_content+="$catalog\n"
                fi
            fi
        fi

        # Add SDD instructions
        if has_feature sdd && [[ -f "$TEMPLATES_DIR/sdd-instructions.md" ]]; then
            agents_content+="\n$(cat "$TEMPLATES_DIR/sdd-instructions.md")\n"
        fi

        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${CYAN}[DRY-RUN]${NC} Would write $opencode_dir/AGENTS.md"
            DRY_RUN_ACTIONS+=("Write $opencode_dir/AGENTS.md")
        else
            echo -e "$agents_content" > "$opencode_dir/AGENTS.md"
            log_ok "Generated $opencode_dir/AGENTS.md"
        fi
    fi

    log_ok "OpenCode configured"
}

configure_codex() {
    log_step "Configuring Codex (~/.codex/)..."
    local codex_dir="$HOME/.codex"
    run_mkdir "$codex_dir"

    # config.toml (create-if-absent only)
    if [[ ! -f "$codex_dir/config.toml" ]]; then
        run_copy "$TEMPLATES_DIR/codex-config.toml" "$codex_dir/config.toml"
        log_ok "Created $codex_dir/config.toml"
    else
        log_info "config.toml already exists — skipping (create-if-absent)"
    fi

    # AGENTS.md (overwrite — auto-generated)
    if has_feature agents || has_feature sdd; then
        local agents_content="# Codex Agents\n\n"
        agents_content+="Auto-generated by setup-global.sh.\n\n"

        # Base rules
        agents_content+="## Base Rules\n\n"
        agents_content+="- NO AI attribution in commits, PRs, code or documentation\n"
        agents_content+="- NO destructive commands without confirmation\n"
        agents_content+="- NO commit sensitive files (.env, credentials, secrets)\n"
        agents_content+="- ALWAYS read files before modifying them\n"
        agents_content+="- ALWAYS follow Conventional Commits: type(scope): description\n\n"

        # SDD
        if has_feature sdd && [[ -f "$TEMPLATES_DIR/sdd-instructions.md" ]]; then
            agents_content+="$(cat "$TEMPLATES_DIR/sdd-instructions.md")\n"
        fi

        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${CYAN}[DRY-RUN]${NC} Would write $codex_dir/AGENTS.md"
            DRY_RUN_ACTIONS+=("Write $codex_dir/AGENTS.md")
        else
            echo -e "$agents_content" > "$codex_dir/AGENTS.md"
            log_ok "Generated $codex_dir/AGENTS.md"
        fi
    fi

    log_ok "Codex configured"
}

configure_copilot() {
    log_step "Configuring Copilot (~/.copilot/)..."
    local copilot_dir="$HOME/.copilot"
    run_mkdir "$copilot_dir"
    run_mkdir "$copilot_dir/instructions"

    # Instructions (copy template instructions)
    if has_feature hooks; then
        if [[ -d "$TEMPLATES_DIR/copilot-instructions" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "  ${CYAN}[DRY-RUN]${NC} Would copy copilot instructions"
                DRY_RUN_ACTIONS+=("Copy copilot instructions to $copilot_dir/instructions/")
            else
                cp "$TEMPLATES_DIR/copilot-instructions"/*.md "$copilot_dir/instructions"/ 2>/dev/null || true
                log_ok "Synced copilot instructions"
            fi
        fi
    fi

    # copilot-instructions.md (marker-based merge)
    if has_feature agents || has_feature sdd; then
        local generated=""
        generated+="## Base Rules\n\n"
        generated+="- NO AI attribution in commits, PRs, code or documentation\n"
        generated+="- NO destructive commands without confirmation\n"
        generated+="- NO commit sensitive files (.env, credentials, secrets)\n"
        generated+="- ALWAYS read files before modifying them\n"
        generated+="- ALWAYS follow Conventional Commits: type(scope): description\n"

        if has_feature sdd && [[ -f "$TEMPLATES_DIR/sdd-instructions.md" ]]; then
            generated+="\n$(cat "$TEMPLATES_DIR/sdd-instructions.md")"
        fi

        merge_markdown "$copilot_dir/copilot-instructions.md" "$generated" "## Auto-generated by setup-global"
    fi

    # Agents (flatten)
    if has_feature agents && [[ -d "$FRAMEWORK_DIR/agents" ]]; then
        sync_agents_to_flat_dir "$FRAMEWORK_DIR/agents" "$copilot_dir/agents"
    fi

    # Skills (with dirs)
    if has_feature skills && [[ -d "$FRAMEWORK_DIR/skills" ]]; then
        sync_skills_to_dir "$FRAMEWORK_DIR/skills" "$copilot_dir/skills"
    fi

    # SDD agent
    if has_feature sdd && [[ -f "$TEMPLATES_DIR/sdd-orchestrator-copilot.md" ]]; then
        run_mkdir "$copilot_dir/agents"
        run_copy "$TEMPLATES_DIR/sdd-orchestrator-copilot.md" "$copilot_dir/agents/sdd-orchestrator.md"
    fi

    log_ok "Copilot configured"
}

configure_gemini() {
    log_step "Configuring Gemini (~/.gemini/)..."
    local gemini_dir="$HOME/.gemini"
    run_mkdir "$gemini_dir"

    # Settings JSON merge (context fileNames)
    merge_json "$TEMPLATES_DIR/gemini-settings.json" "$gemini_dir/settings.json" "deep"

    # Commands (copy TOML files)
    if has_feature commands && [[ -d "$TEMPLATES_DIR/gemini-commands" ]]; then
        run_mkdir "$gemini_dir/commands"
        if [[ "$DRY_RUN" == true ]]; then
            local count
            count=$(find "$TEMPLATES_DIR/gemini-commands" -name "*.toml" | wc -l)
            echo -e "  ${CYAN}[DRY-RUN]${NC} Would copy $count Gemini commands"
            DRY_RUN_ACTIONS+=("Copy $count Gemini command TOML files")
        else
            cp "$TEMPLATES_DIR/gemini-commands"/*.toml "$gemini_dir/commands"/ 2>/dev/null || true
            log_ok "Synced Gemini commands"
        fi
    fi

    # GEMINI.md (overwrite — auto-generated)
    if has_feature agents || has_feature sdd; then
        local gemini_content="# Gemini CLI Configuration\n\n"
        gemini_content+="Auto-generated by setup-global.sh.\n\n"
        gemini_content+="## Base Rules\n\n"
        gemini_content+="- NO AI attribution in commits, PRs, code or documentation\n"
        gemini_content+="- NO destructive commands without confirmation\n"
        gemini_content+="- NO commit sensitive files (.env, credentials, secrets)\n"
        gemini_content+="- ALWAYS read files before modifying them\n"
        gemini_content+="- ALWAYS follow Conventional Commits: type(scope): description\n"

        if has_feature sdd && [[ -f "$TEMPLATES_DIR/sdd-instructions.md" ]]; then
            gemini_content+="\n$(cat "$TEMPLATES_DIR/sdd-instructions.md")"
        fi

        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${CYAN}[DRY-RUN]${NC} Would write $gemini_dir/GEMINI.md"
            DRY_RUN_ACTIONS+=("Write $gemini_dir/GEMINI.md")
        else
            echo -e "$gemini_content" > "$gemini_dir/GEMINI.md"
            log_ok "Generated $gemini_dir/GEMINI.md"
        fi
    fi

    log_ok "Gemini configured"
}

# =============================================================================
# MCP Configuration
# =============================================================================
configure_mcp() {
    if ! has_feature mcp; then
        return
    fi

    log_step "Configuring MCP servers..."

    # Engram native setup
    if command -v engram &>/dev/null || [[ "$DRY_RUN" == true ]]; then
        local engram_clis=()
        has_cli claude && engram_clis+=(claude-code)
        has_cli opencode && engram_clis+=(opencode)
        has_cli codex && engram_clis+=(codex)
        has_cli gemini && engram_clis+=(gemini-cli)

        for cli in "${engram_clis[@]}"; do
            run_cmd "Setup Engram for $cli" engram setup "$cli" 2>/dev/null || true
        done
    else
        log_warn "Engram not installed — skipping native MCP setup"
    fi

    # Docker MCP Toolkit
    if [[ "${TOOL_STATUS[docker-mcp]:-missing}" == "installed" ]] || [[ "$DRY_RUN" == true ]]; then
        log_info "Configuring Docker MCP Toolkit..."
        run_cmd "Enable Context7 MCP server" docker mcp server enable context7 2>/dev/null || true

        local docker_clis=()
        has_cli claude && docker_clis+=(claude)
        has_cli opencode && docker_clis+=(opencode)
        has_cli codex && docker_clis+=(codex)
        has_cli gemini && docker_clis+=(gemini)

        for cli in "${docker_clis[@]}"; do
            run_cmd "Connect Docker MCP to $cli" docker mcp client connect "$cli" 2>/dev/null || true
        done
    else
        log_info "Docker MCP Toolkit not available — using remote MCP URLs in configs"
    fi
}

# =============================================================================
# Doctor Check
# =============================================================================
run_doctor() {
    log_step "Running doctor check..."
    echo ""

    local checks_passed=0
    local checks_failed=0

    doctor_check() {
        local desc="$1" path="$2"
        if [[ -e "$path" ]]; then
            log_ok "$desc"
            checks_passed=$((checks_passed + 1))
        else
            log_fail "$desc — not found: $path"
            checks_failed=$((checks_failed + 1))
        fi
    }

    # Claude
    if has_cli claude; then
        doctor_check "Claude settings.json" "$HOME/.claude/settings.json"
        has_feature commands && doctor_check "Claude commands/" "$HOME/.claude/commands"
        has_feature skills && doctor_check "Claude skills/" "$HOME/.claude/skills"
        has_feature sdd && doctor_check "Claude SDD skills" "$HOME/.claude/skills/sdd-init"
    fi

    # OpenCode
    if has_cli opencode; then
        doctor_check "OpenCode opencode.json" "$HOME/.config/opencode/opencode.json"
        has_feature agents && doctor_check "OpenCode agents/" "$HOME/.config/opencode/agents"
    fi

    # Codex
    if has_cli codex; then
        doctor_check "Codex config.toml" "$HOME/.codex/config.toml"
        has_feature agents && doctor_check "Codex AGENTS.md" "$HOME/.codex/AGENTS.md"
    fi

    # Copilot
    if has_cli copilot; then
        doctor_check "Copilot instructions/" "$HOME/.copilot/instructions"
        has_feature sdd && doctor_check "Copilot SDD agent" "$HOME/.copilot/agents/sdd-orchestrator.md"
    fi

    # Gemini
    if has_cli gemini; then
        doctor_check "Gemini settings.json" "$HOME/.gemini/settings.json"
        has_feature commands && doctor_check "Gemini commands/" "$HOME/.gemini/commands"
    fi

    # MCP
    if has_feature mcp; then
        command -v engram &>/dev/null && doctor_check "Engram binary" "$(command -v engram)"
    fi

    echo ""
    echo -e "  ${GREEN}Passed: $checks_passed${NC}  ${RED}Failed: $checks_failed${NC}"
    echo ""
}

# =============================================================================
# Summary
# =============================================================================
show_summary() {
    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║                  DRY-RUN SUMMARY                         ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}The following ${#DRY_RUN_ACTIONS[@]} action(s) would have been performed:${NC}"
        for i in "${!DRY_RUN_ACTIONS[@]}"; do
            echo -e "  $((i+1)). ${DRY_RUN_ACTIONS[$i]}"
        done
        echo ""
        echo -e "${YELLOW}Run without --dry-run to apply these changes.${NC}"
        echo ""
        return
    fi

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Setup Complete                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}CLIs configured:${NC}    ${SELECTED_CLIS[*]}"
    echo -e "  ${CYAN}Features enabled:${NC}   ${SELECTED_FEATURES[*]}"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo -e "    1. Review generated configs in each CLI directory"
    echo -e "    2. Run ${CYAN}setup-global.sh --dry-run${NC} to verify idempotency"
    has_cli claude && echo -e "    3. Start Claude Code: ${CYAN}claude${NC}"
    has_cli opencode && echo -e "    4. Start OpenCode: ${CYAN}opencode${NC}"
    echo ""
}

# =============================================================================
# Main Execution Flow
# =============================================================================
main() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       Global CLI Setup — project-starter-framework      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    [[ "$DRY_RUN" == true ]] && echo -e "${YELLOW}  ⚡ DRY-RUN MODE — no changes will be made${NC}" && echo ""

    # 1. Detect
    detect_tools

    # 2. Show state
    show_status_table

    # 3. Select CLIs
    select_clis

    # 4. Select features
    select_features

    # 5. Install prerequisites
    install_prerequisites

    # 6. Install CLIs
    install_clis

    # 7. Install Engram
    install_engram

    # 8. Configure each CLI
    echo ""
    log_step "Configuring CLIs..."
    echo ""

    has_cli claude   && configure_claude
    has_cli opencode && configure_opencode
    has_cli codex    && configure_codex
    has_cli copilot  && configure_copilot
    has_cli gemini   && configure_gemini

    # 9. Configure MCP
    configure_mcp

    # 10. Doctor check
    if [[ "$DRY_RUN" == false ]]; then
        run_doctor
    fi

    # 11. Summary
    show_summary
}

main "$@"
