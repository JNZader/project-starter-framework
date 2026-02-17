#!/bin/bash
# =============================================================================
# validate-framework.sh - Validates framework structure and consistency
# =============================================================================
# Usage: ./scripts/validate-framework.sh [--fix]
# =============================================================================

set -e

source "$(cd "$(dirname "$0")" && pwd)/../lib/common.sh"

FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FRAMEWORK_DIR"

errors=0
warnings=0

check_pass() { echo -e "${GREEN}  PASS: $1${NC}"; }
check_fail() { echo -e "${RED}  FAIL: $1${NC}"; errors=$((errors + 1)); }
check_warn() { echo -e "${YELLOW}  WARN: $1${NC}"; warnings=$((warnings + 1)); }

echo -e "${CYAN}=== Framework Validation ===${NC}"
echo ""

# --- Structure Checks ---
echo -e "${CYAN}[1/6] Core structure${NC}"
for dir in .ci-local .ai-config templates scripts lib; do
    [[ -d "$dir" ]] && check_pass "$dir/ exists" || check_fail "$dir/ missing"
done
for file in .framework-version .releaserc .gitignore.template CLAUDE.md; do
    [[ -f "$file" ]] && check_pass "$file exists" || check_fail "$file missing"
done

# --- Agent/Skill Validation ---
echo ""
echo -e "${CYAN}[2/6] AI Config${NC}"
agent_count=$(find .ai-config/agents -name "*.md" ! -name "_TEMPLATE.md" 2>/dev/null | wc -l)
skill_count=$(find .ai-config/skills -name "*.md" ! -name "_TEMPLATE.md" 2>/dev/null | wc -l)
echo -e "  Agents: $agent_count, Skills: $skill_count"

# Check agents have required frontmatter
for agent in $(find .ai-config/agents -name "*.md" ! -name "_TEMPLATE.md" 2>/dev/null); do
    if ! head -1 "$agent" | grep -q "^---"; then
        check_warn "No frontmatter: $agent"
    else
        grep -q "^name:" "$agent" || check_warn "Missing 'name:' in $agent"
        grep -q "^description:" "$agent" || check_warn "Missing 'description:' in $agent"
    fi
done

# Check skills have required frontmatter
for skill in $(find .ai-config/skills -name "*.md" ! -name "_TEMPLATE.md" 2>/dev/null); do
    if ! head -1 "$skill" | grep -q "^---"; then
        check_warn "No frontmatter: $skill"
    else
        grep -q "^name:" "$skill" || check_warn "Missing 'name:' in $skill"
        grep -q "^description:" "$skill" || check_warn "Missing 'description:' in $skill"
    fi
done

# --- Template Validation ---
echo ""
echo -e "${CYAN}[3/6] CI Templates${NC}"
for provider in github gitlab woodpecker; do
    count=$(find "templates/$provider" -name "*.yml" 2>/dev/null | wc -l)
    [[ $count -gt 0 ]] && check_pass "templates/$provider/: $count templates" || check_warn "No templates for $provider"
done

# --- Workflow Validation ---
echo ""
echo -e "${CYAN}[4/6] Reusable Workflows${NC}"
for workflow in .github/workflows/reusable-*.yml; do
    [[ -f "$workflow" ]] || continue
    basename_wf=$(basename "$workflow")
    # Check has workflow_call trigger
    grep -q "workflow_call:" "$workflow" && check_pass "$basename_wf has workflow_call" || check_fail "$basename_wf missing workflow_call trigger"
    # Check has permissions
    grep -q "permissions:" "$workflow" && check_pass "$basename_wf has permissions" || check_warn "$basename_wf missing permissions block"
done

# --- Script Validation ---
echo ""
echo -e "${CYAN}[5/6] Scripts${NC}"
for script in scripts/*.sh; do
    [[ -f "$script" ]] || continue
    basename_sc=$(basename "$script")
    # Check sources lib/common.sh
    grep -q "lib/common.sh" "$script" && check_pass "$basename_sc sources lib/common.sh" || check_warn "$basename_sc doesn't source shared library"
    # Check has set -e
    grep -q "set -e" "$script" && check_pass "$basename_sc has set -e" || check_warn "$basename_sc missing set -e"
done

# --- Bash/PowerShell Parity ---
echo ""
echo -e "${CYAN}[6/6] Bash/PowerShell Parity${NC}"
for script in scripts/*.sh; do
    [[ -f "$script" ]] || continue
    ps1="${script%.sh}.ps1"
    basename_sc=$(basename "$script")
    [[ -f "$ps1" ]] && check_pass "$basename_sc has PS1 counterpart" || check_warn "$basename_sc missing PS1 counterpart"
done

# --- Summary ---
echo ""
echo -e "${CYAN}================================${NC}"
if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
    echo -e "${GREEN}All checks passed!${NC}"
elif [[ $errors -eq 0 ]]; then
    echo -e "${YELLOW}Passed with $warnings warnings${NC}"
else
    echo -e "${RED}$errors errors, $warnings warnings${NC}"
    exit 1
fi
