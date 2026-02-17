#!/usr/bin/env bats
# =============================================================================
# tests/framework.bats - Basic framework regression tests
# =============================================================================
# Run: bats tests/framework.bats
# Install: npm install -g bats  OR  brew install bats-core
# =============================================================================

setup() {
    FRAMEWORK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    source "$FRAMEWORK_DIR/lib/common.sh"
}

# =============================================================================
# Library Tests
# =============================================================================

@test "lib/common.sh exists and is sourceable" {
    [ -f "$FRAMEWORK_DIR/lib/common.sh" ]
    # Re-source to verify it handles double-sourcing gracefully
    source "$FRAMEWORK_DIR/lib/common.sh"
}

@test "detect_stack detects java-gradle" {
    cd "$(mktemp -d)"
    touch build.gradle
    detect_stack
    [ "$STACK_TYPE" = "java-gradle" ]
    [ "$BUILD_TOOL" = "gradle" ]
}

@test "detect_stack detects java-gradle with kotlin DSL" {
    cd "$(mktemp -d)"
    touch build.gradle.kts
    detect_stack
    [ "$STACK_TYPE" = "java-gradle" ]
    [ "$BUILD_TOOL" = "gradle" ]
}

@test "detect_stack detects java-maven" {
    cd "$(mktemp -d)"
    touch pom.xml
    detect_stack
    [ "$STACK_TYPE" = "java-maven" ]
    [ "$BUILD_TOOL" = "maven" ]
}

@test "detect_stack detects node with npm" {
    cd "$(mktemp -d)"
    touch package.json
    detect_stack
    [ "$STACK_TYPE" = "node" ]
    [ "$BUILD_TOOL" = "npm" ]
}

@test "detect_stack detects node with pnpm" {
    cd "$(mktemp -d)"
    touch package.json pnpm-lock.yaml
    detect_stack
    [ "$STACK_TYPE" = "node" ]
    [ "$BUILD_TOOL" = "pnpm" ]
}

@test "detect_stack detects node with yarn" {
    cd "$(mktemp -d)"
    touch package.json yarn.lock
    detect_stack
    [ "$STACK_TYPE" = "node" ]
    [ "$BUILD_TOOL" = "yarn" ]
}

@test "detect_stack detects python with pip" {
    cd "$(mktemp -d)"
    touch pyproject.toml
    detect_stack
    [ "$STACK_TYPE" = "python" ]
    [ "$BUILD_TOOL" = "pip" ]
}

@test "detect_stack detects python with uv" {
    cd "$(mktemp -d)"
    touch pyproject.toml uv.lock
    detect_stack
    [ "$STACK_TYPE" = "python" ]
    [ "$BUILD_TOOL" = "uv" ]
}

@test "detect_stack detects python with poetry" {
    cd "$(mktemp -d)"
    touch pyproject.toml poetry.lock
    detect_stack
    [ "$STACK_TYPE" = "python" ]
    [ "$BUILD_TOOL" = "poetry" ]
}

@test "detect_stack detects go" {
    cd "$(mktemp -d)"
    touch go.mod
    detect_stack
    [ "$STACK_TYPE" = "go" ]
    [ "$BUILD_TOOL" = "go" ]
}

@test "detect_stack detects rust" {
    cd "$(mktemp -d)"
    touch Cargo.toml
    detect_stack
    [ "$STACK_TYPE" = "rust" ]
    [ "$BUILD_TOOL" = "cargo" ]
}

@test "detect_stack returns unknown for empty directory" {
    cd "$(mktemp -d)"
    detect_stack
    [ "$STACK_TYPE" = "unknown" ]
}

@test "sed_inplace modifies file in place" {
    local tmpfile="$(mktemp)"
    echo "hello world" > "$tmpfile"
    sed_inplace "s/hello/goodbye/" "$tmpfile"
    grep -q "goodbye world" "$tmpfile"
    rm -f "$tmpfile"
}

@test "escape_sed escapes special characters" {
    local result
    result=$(escape_sed "foo/bar&baz")
    echo "$result" | grep -qF 'foo\/bar\&baz'
}

@test "backup_if_exists creates .bak file" {
    local tmpfile="$(mktemp)"
    echo "original" > "$tmpfile"
    backup_if_exists "$tmpfile"
    [ -f "${tmpfile}.bak" ]
    grep -q "original" "${tmpfile}.bak"
    rm -f "$tmpfile" "${tmpfile}.bak"
}

@test "backup_if_exists does nothing for missing file" {
    local tmpfile="/tmp/bats-nonexistent-$$"
    rm -f "$tmpfile" "${tmpfile}.bak"
    backup_if_exists "$tmpfile"
    [ ! -f "${tmpfile}.bak" ]
}

# =============================================================================
# Structure Tests
# =============================================================================

@test "core directories exist" {
    [ -d "$FRAMEWORK_DIR/.ci-local" ]
    [ -d "$FRAMEWORK_DIR/.ai-config" ]
    [ -d "$FRAMEWORK_DIR/templates" ]
    [ -d "$FRAMEWORK_DIR/scripts" ]
    [ -d "$FRAMEWORK_DIR/lib" ]
}

@test "framework version file exists and is not empty" {
    [ -f "$FRAMEWORK_DIR/.framework-version" ]
    [ -s "$FRAMEWORK_DIR/.framework-version" ]
}

@test "framework version follows semver format" {
    local version
    version=$(cat "$FRAMEWORK_DIR/.framework-version" | tr -d '[:space:]')
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "all bash scripts source lib/common.sh" {
    for script in "$FRAMEWORK_DIR"/scripts/*.sh; do
        [ -f "$script" ] || continue
        grep -q "lib/common.sh" "$script" || {
            echo "Missing lib/common.sh source in: $(basename "$script")"
            return 1
        }
    done
}

@test "all bash scripts have set -e" {
    for script in "$FRAMEWORK_DIR"/scripts/*.sh; do
        [ -f "$script" ] || continue
        grep -q "set -e" "$script" || {
            echo "Missing set -e in: $(basename "$script")"
            return 1
        }
    done
}

@test "all agents have frontmatter" {
    local missing=0
    while IFS= read -r agent; do
        [ -f "$agent" ] || continue
        [[ "$(basename "$agent")" == "_TEMPLATE.md" ]] && continue
        head -1 "$agent" | grep -q "^---" || {
            echo "Missing frontmatter: $agent"
            missing=$((missing + 1))
        }
    done < <(find "$FRAMEWORK_DIR/.ai-config/agents" -name "*.md" 2>/dev/null)
    [ "$missing" -eq 0 ]
}

@test "all skills have frontmatter" {
    local missing=0
    while IFS= read -r skill; do
        [ -f "$skill" ] || continue
        [[ "$(basename "$skill")" == "_TEMPLATE.md" ]] && continue
        head -1 "$skill" | grep -q "^---" || {
            echo "Missing frontmatter: $skill"
            missing=$((missing + 1))
        }
    done < <(find "$FRAMEWORK_DIR/.ai-config/skills" -name "*.md" 2>/dev/null)
    [ "$missing" -eq 0 ]
}

# --- New: stricter frontmatter checks ---
@test "agents have required frontmatter fields (name & description)" {
    local errors=0
    while IFS= read -r agent; do
        [ -f "$agent" ] || continue
        [[ "$(basename "$agent")" == "_TEMPLATE.md" ]] && continue
        if ! grep -q "^name:\s*" "$agent"; then
            echo "Missing 'name' in agent: $agent"
            errors=$((errors + 1))
        fi
        if ! grep -q "^description:\s*" "$agent"; then
            echo "Missing 'description' in agent: $agent"
            errors=$((errors + 1))
        fi
        # name should be kebab-case
        name=$(grep "^name:" "$agent" | head -1 | sed 's/name:\s*//')
        if [ -n "$name" ] && ! echo "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
            echo "Invalid agent name (should be kebab-case): $agent -> $name"
            errors=$((errors + 1))
        fi
    done < <(find "$FRAMEWORK_DIR/.ai-config/agents" -name "*.md" 2>/dev/null)
    [ "$errors" -eq 0 ]
}

@test "skills have required frontmatter fields (name & description)" {
    local errors=0
    while IFS= read -r skill; do
        [ -f "$skill" ] || continue
        [[ "$(basename "$skill")" == "_TEMPLATE.md" ]] && continue
        if ! grep -q "^name:\s*" "$skill"; then
            echo "Missing 'name' in skill: $skill"
            errors=$((errors + 1))
        fi
        if ! grep -q "^description:\s*" "$skill"; then
            echo "Missing 'description' in skill: $skill"
            errors=$((errors + 1))
        fi
        # name should be kebab-case
        name=$(grep "^name:" "$skill" | head -1 | sed 's/name:\s*//')
        if [ -n "$name" ] && ! echo "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
            echo "Invalid skill name (should be kebab-case): $skill -> $name"
            errors=$((errors + 1))
        fi
    done < <(find "$FRAMEWORK_DIR/.ai-config/skills" -name "*.md" 2>/dev/null)
    [ "$errors" -eq 0 ]
}

@test "validate-frontmatter.py accepts multi-line description and valid name" {
    tmpfile=$(mktemp)
    cat > "$tmpfile" <<'EOF'
---
name: valid-name
description: |
  First line
  Second line
---
EOF
    python3 scripts/validate-frontmatter.py "$tmpfile"
    [ $? -eq 0 ]
    rm -f "$tmpfile"
}

@test "validate-frontmatter.py rejects invalid name" {
    tmpfile=$(mktemp)
    cat > "$tmpfile" <<'EOF'
---
name: Bad_Name
description: Example
---
EOF
    run python3 scripts/validate-frontmatter.py "$tmpfile"
    [ "$status" -ne 0 ]
    rm -f "$tmpfile"
}

@test "reusable workflows have workflow_call trigger" {
    for wf in "$FRAMEWORK_DIR"/.github/workflows/reusable-*.yml; do
        [ -f "$wf" ] || continue
        grep -q "workflow_call:" "$wf" || {
            echo "Missing workflow_call in: $(basename "$wf")"
            return 1
        }
    done
}

@test "reusable workflows have permissions block" {
    for wf in "$FRAMEWORK_DIR"/.github/workflows/reusable-*.yml; do
        [ -f "$wf" ] || continue
        grep -q "permissions:" "$wf" || {
            echo "Missing permissions in: $(basename "$wf")"
            return 1
        }
    done
}

@test "no expression injection in workflow run blocks" {
    local violations=0
    for wf in "$FRAMEWORK_DIR"/.github/workflows/reusable-*.yml; do
        [ -f "$wf" ] || continue
        # Check for ${{ github.event in run: blocks (simplified check)
        if awk '/run: \|/,/^[[:space:]]*-/' "$wf" | grep -q '\${{.*github\.event'; then
            echo "Possible injection in: $(basename "$wf")"
            violations=$((violations + 1))
        fi
    done
    [ "$violations" -eq 0 ]
}

@test "template providers have at least one template" {
    for provider in github gitlab woodpecker; do
        local count
        count=$(find "$FRAMEWORK_DIR/templates/$provider" -name "*.yml" 2>/dev/null | wc -l)
        [ "$count" -gt 0 ] || {
            echo "No templates for provider: $provider"
            return 1
        }
    done
}

@test "sync-ai-config 'merge' mode appends generated section instead of overwriting custom content" {
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/.ai-config/agents"
    mkdir -p "$tmpdir/scripts"
    mkdir -p "$tmpdir/lib"

    # create a minimal agent
    cat > "$tmpdir/.ai-config/agents/test-agent.md" <<'EOF'
---
name: test-agent
description: Test agent
---
EOF

    # create an existing CLAUDE.md with custom content
    cat > "$tmpdir/CLAUDE.md" <<'EOF'
# Project manual instructions

Do not overwrite this section.
EOF

    # copy the sync script AND shared library
    cp "$FRAMEWORK_DIR/scripts/sync-ai-config.sh" "$tmpdir/scripts/sync-ai-config.sh"
    cp "$FRAMEWORK_DIR/lib/common.sh" "$tmpdir/lib/common.sh"
    chmod +x "$tmpdir/scripts/sync-ai-config.sh"
    (cd "$tmpdir" && ./scripts/sync-ai-config.sh claude merge)

    # verify CLAUDE.md still contains custom header and has auto-generated block
    grep -q "Project manual instructions" "$tmpdir/CLAUDE.md"
    grep -q "test-agent" "$tmpdir/CLAUDE.md"

    rm -rf "$tmpdir"
}

@test "validate-framework fails on invalid agent name (frontmatter schema)" {
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/.ai-config/agents" "$tmpdir/lib" "$tmpdir/scripts"

    # copy minimal runtime pieces
    cp "$FRAMEWORK_DIR/lib/common.sh" "$tmpdir/lib/common.sh"
    cp "$FRAMEWORK_DIR/scripts/validate-framework.sh" "$tmpdir/scripts/validate-framework.sh"
    chmod +x "$tmpdir/scripts/validate-framework.sh"

    # invalid agent name (not kebab-case)
    cat > "$tmpdir/.ai-config/agents/bad-agent.md" <<'EOF'
---
name: Bad_Name
description: Example
---
EOF

    (cd "$tmpdir" && ./scripts/validate-framework.sh) && {
        echo "validate-framework should have failed for invalid agent name"
        rm -rf "$tmpdir"
        return 1
    } || true

    rm -rf "$tmpdir"
}

# =============================================================================
# Hook Tests
# =============================================================================

@test "hook files exist and are executable" {
    for hook in pre-commit commit-msg pre-push; do
        [ -f "$FRAMEWORK_DIR/.ci-local/hooks/$hook" ] || {
            echo "Missing hook file: $hook"
            return 1
        }
        head -1 "$FRAMEWORK_DIR/.ci-local/hooks/$hook" | grep -q "#!/bin/bash" || {
            echo "Missing #!/bin/bash shebang in: $hook"
            return 1
        }
    done
}

@test "pre-commit blocks AI attribution in staged content" {
    tmpdir=$(mktemp -d)
    git -C "$tmpdir" init
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    # copy hooks and lib
    cp -r "$FRAMEWORK_DIR/.ci-local" "$tmpdir/.ci-local"
    cp -r "$FRAMEWORK_DIR/lib" "$tmpdir/lib"

    # Create a file with AI attribution and stage it
    echo "Co-Authored-By: Claude" > "$tmpdir/bad-file.txt"
    git -C "$tmpdir" add bad-file.txt

    # Run pre-commit hook — should exit non-zero
    cd "$tmpdir"
    run bash "$tmpdir/.ci-local/hooks/pre-commit"
    [ "$status" -ne 0 ]

    rm -rf "$tmpdir"
}

@test "pre-commit passes clean files" {
    tmpdir=$(mktemp -d)
    git -C "$tmpdir" init
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    # copy hooks and lib
    cp -r "$FRAMEWORK_DIR/.ci-local" "$tmpdir/.ci-local"
    cp -r "$FRAMEWORK_DIR/lib" "$tmpdir/lib"

    # Create a clean file (no AI attribution, no code extensions to trigger semgrep/compile)
    echo "Hello world" > "$tmpdir/clean-file.txt"
    git -C "$tmpdir" add clean-file.txt

    # Run pre-commit hook — should exit zero
    cd "$tmpdir"
    run bash "$tmpdir/.ci-local/hooks/pre-commit"
    [ "$status" -eq 0 ]

    rm -rf "$tmpdir"
}

@test "commit-msg blocks AI attribution in message" {
    tmpdir=$(mktemp -d)
    git -C "$tmpdir" init
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    # copy hooks and lib
    cp -r "$FRAMEWORK_DIR/.ci-local" "$tmpdir/.ci-local"
    cp -r "$FRAMEWORK_DIR/lib" "$tmpdir/lib"

    # Write a commit message file with AI attribution
    echo "Generated by Claude" > "$tmpdir/COMMIT_EDITMSG"

    # Run commit-msg hook — should exit non-zero
    run bash "$tmpdir/.ci-local/hooks/commit-msg" "$tmpdir/COMMIT_EDITMSG"
    [ "$status" -ne 0 ]

    rm -rf "$tmpdir"
}

@test "commit-msg passes clean message" {
    tmpdir=$(mktemp -d)
    git -C "$tmpdir" init
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    # copy hooks and lib
    cp -r "$FRAMEWORK_DIR/.ci-local" "$tmpdir/.ci-local"
    cp -r "$FRAMEWORK_DIR/lib" "$tmpdir/lib"

    # Write a clean commit message file
    echo "feat(core): add new feature" > "$tmpdir/COMMIT_EDITMSG"

    # Run commit-msg hook — should exit zero
    run bash "$tmpdir/.ci-local/hooks/commit-msg" "$tmpdir/COMMIT_EDITMSG"
    [ "$status" -eq 0 ]

    rm -rf "$tmpdir"
}

@test "lib/Common.psm1 exists as PowerShell counterpart" {
    [ -f "$FRAMEWORK_DIR/lib/Common.psm1" ]
}
