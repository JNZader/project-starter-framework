#!/bin/bash
# =============================================================================
# doctor.sh - Diagnostic tool for project-starter-framework
# =============================================================================
# Checks environment, framework integrity, and project configuration.
# Complements validate-framework.sh (which checks content/consistency).
# This script checks runtime environment and operational readiness.
# =============================================================================
# Usage: ./scripts/doctor.sh [--help]
# =============================================================================

set -e

source "$(cd "$(dirname "$0")" && pwd)/../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_DIR="$(dirname "$SCRIPT_DIR")"

cd "$FRAMEWORK_DIR"

# =============================================================================
# Help
# =============================================================================
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: ./scripts/doctor.sh [--help]"
    echo ""
    echo "Diagnostic tool for project-starter-framework."
    echo "Checks environment dependencies, framework file integrity,"
    echo "and project-level configuration."
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Exit codes:"
    echo "  0    All checks passed (warnings are acceptable)"
    echo "  1    One or more checks failed"
    exit 0
fi

# =============================================================================
# Counters + wrappers that log AND count
# =============================================================================
pass_count=0
warn_count=0
fail_count=0

check_ok()   { log_ok "$1";   pass_count=$((pass_count + 1)); }
check_warn() { log_warn "$1"; warn_count=$((warn_count + 1)); }
check_fail() { log_fail "$1"; fail_count=$((fail_count + 1)); }
check_info() { log_info "$1"; }

# =============================================================================
# Header
# =============================================================================
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   Framework Doctor                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# 1. Environment Checks
# =============================================================================
echo -e "${CYAN}--- Environment ---${NC}"

# Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>/dev/null | head -1)
    check_ok "Git installed ($git_version)"
else
    check_fail "Git not installed"
fi

# Docker
if command -v docker &> /dev/null; then
    docker_version=$(docker --version 2>/dev/null | head -1)
    check_ok "Docker installed ($docker_version)"

    # Docker daemon running
    if docker info &> /dev/null; then
        check_ok "Docker daemon is running"
    else
        check_warn "Docker daemon is not running (needed for ci-local full)"
    fi
else
    check_warn "Docker not installed (needed for ci-local full)"
fi

# Semgrep (native or Docker fallback)
if command -v semgrep &> /dev/null; then
    semgrep_version=$(semgrep --version 2>/dev/null | head -1)
    check_ok "Semgrep installed natively ($semgrep_version)"
elif command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
    check_ok "Semgrep available via Docker (returntocorp/semgrep)"
else
    check_warn "Semgrep not available (install semgrep or Docker)"
fi

# Node.js / npm (optional, info only)
if command -v node &> /dev/null; then
    node_version=$(node --version 2>/dev/null)
    check_info "Node.js installed ($node_version)"
else
    check_info "Node.js not installed"
fi

if command -v npm &> /dev/null; then
    npm_version=$(npm --version 2>/dev/null)
    check_info "npm installed (v$npm_version)"
else
    check_info "npm not installed"
fi

# Python (optional, info only)
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>/dev/null | head -1)
    check_info "Python installed ($python_version)"
elif command -v python &> /dev/null; then
    python_version=$(python --version 2>/dev/null | head -1)
    check_info "Python installed ($python_version)"
else
    check_info "Python not installed"
fi

echo ""

# =============================================================================
# 2. Framework Integrity Checks
# =============================================================================
echo -e "${CYAN}--- Framework Integrity ---${NC}"

# lib/common.sh
if [[ -f "lib/common.sh" ]]; then
    check_ok "lib/common.sh exists"
else
    check_fail "lib/common.sh missing"
fi

# .ci-local/ci-local.sh
if [[ -f ".ci-local/ci-local.sh" ]]; then
    if [[ -x ".ci-local/ci-local.sh" ]]; then
        check_ok ".ci-local/ci-local.sh exists and is executable"
    else
        check_warn ".ci-local/ci-local.sh exists but is not executable"
    fi
else
    check_fail ".ci-local/ci-local.sh missing"
fi

# Hooks
for hook in pre-commit commit-msg pre-push; do
    if [[ -f ".ci-local/hooks/$hook" ]]; then
        check_ok ".ci-local/hooks/$hook exists"
    else
        check_fail ".ci-local/hooks/$hook missing"
    fi
done

# semgrep.yml
if [[ -f ".ci-local/semgrep.yml" ]]; then
    check_ok ".ci-local/semgrep.yml exists"
else
    check_fail ".ci-local/semgrep.yml missing"
fi

# .framework-version
if [[ -f ".framework-version" ]]; then
    fw_version=$(cat .framework-version | tr -d '[:space:]')
    check_ok ".framework-version exists (v$fw_version)"
else
    check_fail ".framework-version missing"
fi

echo ""

# =============================================================================
# 3. Project Checks (only when running OUTSIDE the framework repo)
# =============================================================================
# Detect if we are inside the framework itself: framework has templates/ + .ai-config/
is_framework=false
if [[ -d "templates" && -d ".ai-config" ]]; then
    is_framework=true
fi

if [[ "$is_framework" == false ]]; then
    echo -e "${CYAN}--- Project Configuration ---${NC}"

    # Git hooks path
    hooks_path=$(git config --get core.hooksPath 2>/dev/null || echo "")
    if [[ -n "$hooks_path" ]]; then
        if [[ "$hooks_path" == ".ci-local/hooks" ]]; then
            check_ok "Git hooks path configured ($hooks_path)"
        else
            check_warn "Git hooks path set to '$hooks_path' (expected .ci-local/hooks)"
        fi
    else
        check_fail "Git hooks path not configured (run: git config core.hooksPath .ci-local/hooks)"
    fi

    # .gitignore checks
    if [[ -f ".gitignore" ]]; then
        check_ok ".gitignore exists"
        for entry in ".env" "CLAUDE.md" "node_modules"; do
            if grep -qF "$entry" .gitignore 2>/dev/null; then
                check_ok ".gitignore contains '$entry'"
            else
                check_warn ".gitignore missing '$entry' entry"
            fi
        done
    else
        check_fail ".gitignore missing"
    fi

    # Stack detection
    detect_stack "."
    if [[ "$STACK_TYPE" != "unknown" ]]; then
        check_ok "Stack detected: $STACK_TYPE (build tool: $BUILD_TOOL)"
    else
        check_warn "No stack detected (unknown project type)"
    fi

    # Framework version alignment
    if [[ -f ".framework-version" ]]; then
        project_version=$(cat .framework-version | tr -d '[:space:]')
        # Try to find the framework's version for comparison
        # Look in common parent locations
        framework_version=""
        for candidate in "../project-starter-framework/.framework-version" "../../project-starter-framework/.framework-version"; do
            if [[ -f "$candidate" ]]; then
                framework_version=$(cat "$candidate" | tr -d '[:space:]')
                break
            fi
        done

        if [[ -n "$framework_version" ]]; then
            if [[ "$project_version" == "$framework_version" ]]; then
                check_ok "Framework version aligned (v$project_version)"
            else
                check_warn "Framework version mismatch: project v$project_version vs framework v$framework_version"
            fi
        else
            check_info "Project framework version: v$project_version (framework not found for comparison)"
        fi
    fi

    echo ""
else
    echo -e "${CYAN}--- Project Configuration ---${NC}"
    check_info "Running inside the framework repo (project checks skipped)"
    echo ""
fi

# =============================================================================
# Summary
# =============================================================================
total=$((pass_count + warn_count + fail_count))

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}Passed: $pass_count${NC}  ${YELLOW}Warnings: $warn_count${NC}  ${RED}Failures: $fail_count${NC}  (Total: $total)"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

if [[ $fail_count -eq 0 && $warn_count -eq 0 ]]; then
    echo -e "  ${GREEN}All checks passed!${NC}"
elif [[ $fail_count -eq 0 ]]; then
    echo -e "  ${YELLOW}Passed with $warn_count warning(s).${NC}"
else
    echo -e "  ${RED}$fail_count check(s) failed. Review the output above.${NC}"
fi

echo ""

if [[ $fail_count -gt 0 ]]; then
    exit 1
fi

exit 0
