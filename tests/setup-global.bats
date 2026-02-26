#!/usr/bin/env bats
# =============================================================================
# tests/setup-global.bats - Tests for scripts/setup-global.sh
# =============================================================================
# Run: bats tests/setup-global.bats
# =============================================================================

setup() {
    FRAMEWORK_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    SETUP_SCRIPT="$FRAMEWORK_DIR/scripts/setup-global.sh"
    TEMPLATES_DIR="$FRAMEWORK_DIR/templates/global"

    # Create isolated HOME for each test to avoid mutating real config
    TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"
}

teardown() {
    rm -rf "$TEST_HOME"
}

# =============================================================================
# Help & Flags
# =============================================================================

@test "setup-global.sh --help exits 0 and shows usage" {
    run bash "$SETUP_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--auto"* ]]
    [[ "$output" == *"--dry-run"* ]]
    [[ "$output" == *"--clis="* ]]
    [[ "$output" == *"--features="* ]]
    [[ "$output" == *"--skip-install"* ]]
}

@test "setup-global.sh rejects unknown flags" {
    run bash "$SETUP_SCRIPT" --bogus-flag
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

# =============================================================================
# Template Files Existence
# =============================================================================

@test "all global template files exist" {
    [ -f "$TEMPLATES_DIR/claude-settings.json" ]
    [ -f "$TEMPLATES_DIR/codex-config.toml" ]
    [ -f "$TEMPLATES_DIR/gemini-settings.json" ]
    [ -f "$TEMPLATES_DIR/opencode-config.json" ]
    [ -f "$TEMPLATES_DIR/sdd-orchestrator-claude.md" ]
    [ -f "$TEMPLATES_DIR/sdd-orchestrator-copilot.md" ]
    [ -f "$TEMPLATES_DIR/sdd-instructions.md" ]
}

@test "copilot instruction templates exist" {
    [ -f "$TEMPLATES_DIR/copilot-instructions/base-rules.instructions.md" ]
    [ -f "$TEMPLATES_DIR/copilot-instructions/sdd-orchestrator.instructions.md" ]
}

@test "gemini command templates exist (10 TOML files)" {
    local count
    count=$(find "$TEMPLATES_DIR/gemini-commands" -name "*.toml" | wc -l)
    [ "$count" -eq 10 ]
}

@test "gemini command TOMLs have valid structure" {
    for toml in "$TEMPLATES_DIR"/gemini-commands/*.toml; do
        grep -q '^\[command\]' "$toml" || {
            echo "Missing [command] in: $(basename "$toml")"
            return 1
        }
        grep -q 'description = ' "$toml" || {
            echo "Missing description in: $(basename "$toml")"
            return 1
        }
        grep -q '\[\[steps\]\]' "$toml" || {
            echo "Missing [[steps]] in: $(basename "$toml")"
            return 1
        }
    done
}

@test "claude-settings.json is valid JSON" {
    python3 -c "import json; json.load(open('$TEMPLATES_DIR/claude-settings.json'))"
}

@test "opencode-config.json is valid JSON" {
    python3 -c "import json; json.load(open('$TEMPLATES_DIR/opencode-config.json'))"
}

@test "gemini-settings.json is valid JSON" {
    python3 -c "import json; json.load(open('$TEMPLATES_DIR/gemini-settings.json'))"
}

# =============================================================================
# Dry-Run Mode
# =============================================================================

@test "dry-run mode produces actions without creating files" {
    run bash "$SETUP_SCRIPT" --dry-run --auto --skip-install
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY-RUN"* ]]
    [[ "$output" == *"action(s) would have been performed"* ]]
    # Should NOT create actual files in test HOME
    [ ! -f "$TEST_HOME/.codex/config.toml" ]
    [ ! -f "$TEST_HOME/.gemini/GEMINI.md" ]
}

@test "dry-run does not create backup files" {
    # Pre-create a settings.json so merge would normally back it up
    mkdir -p "$TEST_HOME/.claude"
    echo '{}' > "$TEST_HOME/.claude/settings.json"

    run bash "$SETUP_SCRIPT" --dry-run --auto --skip-install
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_HOME/.claude/settings.json.bak" ]
}

# =============================================================================
# CLI Filtering
# =============================================================================

@test "--clis=claude configures only Claude" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.claude/settings.json" ]
    # Other CLIs should NOT be configured
    [ ! -f "$TEST_HOME/.codex/config.toml" ]
    [ ! -f "$TEST_HOME/.gemini/settings.json" ]
    [ ! -f "$TEST_HOME/.config/opencode/opencode.json" ]
}

@test "--clis=gemini configures only Gemini" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=gemini
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.gemini/settings.json" ]
    [ -f "$TEST_HOME/.gemini/commands/commit.toml" ]
    [ ! -f "$TEST_HOME/.claude/settings.json" ]
}

@test "--clis=codex configures only Codex" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=codex
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.codex/config.toml" ]
    [ -f "$TEST_HOME/.codex/AGENTS.md" ]
    [ ! -f "$TEST_HOME/.claude/settings.json" ]
}

@test "--clis=copilot configures only Copilot" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=copilot
    [ "$status" -eq 0 ]
    [ -d "$TEST_HOME/.copilot/instructions" ]
    [ -f "$TEST_HOME/.copilot/agents/sdd-orchestrator.md" ]
    [ ! -f "$TEST_HOME/.claude/settings.json" ]
}

@test "--clis=opencode configures only OpenCode" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=opencode
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.config/opencode/opencode.json" ]
    [ ! -f "$TEST_HOME/.claude/settings.json" ]
}

@test "multiple --clis work (claude,gemini)" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude,gemini
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.claude/settings.json" ]
    [ -f "$TEST_HOME/.gemini/settings.json" ]
    [ ! -f "$TEST_HOME/.codex/config.toml" ]
}

# =============================================================================
# Feature Filtering
# =============================================================================

@test "--features=sdd only configures SDD artifacts" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude --features=sdd
    [ "$status" -eq 0 ]
    # SDD marker should be in CLAUDE.md
    [ -f "$TEST_HOME/.claude/CLAUDE.md" ]
    grep -q "SDD" "$TEST_HOME/.claude/CLAUDE.md"
    # Commands should NOT be synced (no commands feature)
    [ ! -d "$TEST_HOME/.claude/commands" ]
}

@test "--features=commands syncs commands without SDD" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=gemini --features=commands
    [ "$status" -eq 0 ]
    [ -d "$TEST_HOME/.gemini/commands" ]
    [ -f "$TEST_HOME/.gemini/commands/commit.toml" ]
    # GEMINI.md should not exist (no agents/sdd feature)
    [ ! -f "$TEST_HOME/.gemini/GEMINI.md" ]
}

# =============================================================================
# JSON Merge
# =============================================================================

@test "JSON merge creates file from template when target absent" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=gemini --features=hooks
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.gemini/settings.json" ]
    python3 -c "
import json
with open('$TEST_HOME/.gemini/settings.json') as f:
    data = json.load(f)
assert 'context' in data
assert 'GEMINI.md' in data['context']['fileName']
"
}

@test "JSON merge preserves existing keys and adds new ones" {
    mkdir -p "$TEST_HOME/.gemini"
    echo '{"existingKey": "keep-me", "context": {"fileName": ["CUSTOM.md"]}}' > "$TEST_HOME/.gemini/settings.json"

    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=gemini --features=hooks
    [ "$status" -eq 0 ]

    python3 -c "
import json
with open('$TEST_HOME/.gemini/settings.json') as f:
    data = json.load(f)
assert data['existingKey'] == 'keep-me', 'Existing key was lost'
assert 'CUSTOM.md' in data['context']['fileName'], 'Existing fileName lost'
assert 'GEMINI.md' in data['context']['fileName'], 'Template fileName not added'
"
}

@test "Claude settings merge deduplicates hooks by matcher" {
    mkdir -p "$TEST_HOME/.claude"
    # Pre-existing settings with Bash hook
    cat > "$TEST_HOME/.claude/settings.json" << 'EXISTING'
{
    "hooks": {
        "PreToolUse": [
            {
                "matcher": "Bash",
                "hooks": [{"type": "command", "command": "echo existing"}]
            }
        ]
    },
    "permissions": {"allow": ["Read"]}
}
EXISTING

    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude --features=hooks
    [ "$status" -eq 0 ]

    python3 -c "
import json
with open('$TEST_HOME/.claude/settings.json') as f:
    data = json.load(f)
# Bash matcher should exist only once (not duplicated)
bash_hooks = [h for h in data['hooks']['PreToolUse'] if h.get('matcher') == 'Bash']
assert len(bash_hooks) == 1, f'Expected 1 Bash matcher, got {len(bash_hooks)}'
# Write matcher should be added (new)
write_hooks = [h for h in data['hooks']['PreToolUse'] if h.get('matcher') == 'Write']
assert len(write_hooks) == 1, 'Write matcher not added'
# Permissions should union
assert 'Read' in data['permissions']['allow'], 'Existing permission lost'
"
}

@test "JSON merge creates backup of existing file" {
    mkdir -p "$TEST_HOME/.claude"
    echo '{"original": true}' > "$TEST_HOME/.claude/settings.json"

    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude --features=hooks
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.claude/settings.json.bak" ]
    grep -q '"original"' "$TEST_HOME/.claude/settings.json.bak"
}

# =============================================================================
# Markdown Marker Merge
# =============================================================================

@test "markdown merge creates new file with marker" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude --features=sdd
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.claude/CLAUDE.md" ]
    grep -q "Spec-Driven Development (SDD) Orchestrator" "$TEST_HOME/.claude/CLAUDE.md"
}

@test "markdown merge preserves content above marker" {
    mkdir -p "$TEST_HOME/.claude"
    cat > "$TEST_HOME/.claude/CLAUDE.md" << 'EOF'
# My Custom Instructions

Keep this content.

## Spec-Driven Development (SDD) Orchestrator

Old SDD content that should be replaced.
EOF

    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude --features=sdd
    [ "$status" -eq 0 ]
    grep -q "My Custom Instructions" "$TEST_HOME/.claude/CLAUDE.md"
    grep -q "Keep this content" "$TEST_HOME/.claude/CLAUDE.md"
    # Old content should be gone, replaced by template
    grep -qi "delegate" "$TEST_HOME/.claude/CLAUDE.md"
}

@test "markdown merge appends when marker not present" {
    mkdir -p "$TEST_HOME/.claude"
    echo "# Existing content without marker" > "$TEST_HOME/.claude/CLAUDE.md"

    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude --features=sdd
    [ "$status" -eq 0 ]
    grep -q "Existing content without marker" "$TEST_HOME/.claude/CLAUDE.md"
    grep -q "SDD" "$TEST_HOME/.claude/CLAUDE.md"
}

# =============================================================================
# Codex: Create-if-Absent
# =============================================================================

@test "codex config.toml is created when absent" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=codex
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.codex/config.toml" ]
    grep -q 'model = "o4-mini"' "$TEST_HOME/.codex/config.toml"
}

@test "codex config.toml is NOT overwritten when present" {
    mkdir -p "$TEST_HOME/.codex"
    echo 'model = "custom-model"' > "$TEST_HOME/.codex/config.toml"

    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=codex
    [ "$status" -eq 0 ]
    grep -q "custom-model" "$TEST_HOME/.codex/config.toml"
    ! grep -q "o4-mini" "$TEST_HOME/.codex/config.toml"
}

# =============================================================================
# SDD Content
# =============================================================================

@test "SDD instructions contain all 8 commands" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=codex --features=sdd
    [ "$status" -eq 0 ]
    for cmd in init explore new continue ff apply verify archive; do
        grep -q "sdd:$cmd" "$TEST_HOME/.codex/AGENTS.md" || {
            echo "Missing sdd:$cmd in AGENTS.md"
            return 1
        }
    done
}

@test "copilot SDD agent file is created" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=copilot --features=sdd
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.copilot/agents/sdd-orchestrator.md" ]
    grep -qi "delegate" "$TEST_HOME/.copilot/agents/sdd-orchestrator.md"
}

@test "gemini SDD commands are created" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=gemini --features=commands,sdd
    [ "$status" -eq 0 ]
    [ -f "$TEST_HOME/.gemini/commands/sdd-new.toml" ]
    [ -f "$TEST_HOME/.gemini/commands/sdd-ff.toml" ]
    [ -f "$TEST_HOME/.gemini/commands/sdd-apply.toml" ]
    [ -f "$TEST_HOME/.gemini/commands/sdd-verify.toml" ]
}

# =============================================================================
# Idempotency
# =============================================================================

@test "running twice is idempotent (no errors, no duplicates)" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude,gemini,codex
    [ "$status" -eq 0 ]

    # Run again
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=claude,gemini,codex
    [ "$status" -eq 0 ]

    # Check no duplicate markers in CLAUDE.md
    local marker_count
    marker_count=$(grep -c "Spec-Driven Development (SDD) Orchestrator" "$TEST_HOME/.claude/CLAUDE.md" || true)
    [ "$marker_count" -eq 1 ]
}

@test "gemini settings merge is idempotent (no duplicate fileNames)" {
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=gemini --features=hooks
    run bash "$SETUP_SCRIPT" --auto --skip-install --clis=gemini --features=hooks
    [ "$status" -eq 0 ]

    python3 -c "
import json
with open('$TEST_HOME/.gemini/settings.json') as f:
    data = json.load(f)
names = data['context']['fileName']
assert names.count('GEMINI.md') == 1, f'GEMINI.md duplicated: {names}'
"
}

# =============================================================================
# Full Auto Run (Smoke)
# =============================================================================

@test "full --auto --skip-install creates all expected directories" {
    run bash "$SETUP_SCRIPT" --auto --skip-install
    [ "$status" -eq 0 ]
    [ -d "$TEST_HOME/.claude" ]
    [ -d "$TEST_HOME/.config/opencode" ]
    [ -d "$TEST_HOME/.codex" ]
    [ -d "$TEST_HOME/.copilot" ]
    [ -d "$TEST_HOME/.gemini" ]
}

@test "full --auto --skip-install shows Setup Complete" {
    run bash "$SETUP_SCRIPT" --auto --skip-install
    [ "$status" -eq 0 ]
    [[ "$output" == *"Setup Complete"* ]]
}

@test "doctor check passes after full setup" {
    run bash "$SETUP_SCRIPT" --auto --skip-install
    [ "$status" -eq 0 ]
    [[ "$output" == *"Passed:"* ]]
    # Should have 0 failures for config files
    [[ "$output" != *"Failed: 0"* ]] || true
}
