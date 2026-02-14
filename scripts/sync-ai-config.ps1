# =============================================================================
# SYNC-AI-CONFIG: Genera configuración para diferentes AI CLIs (Windows)
# =============================================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("claude", "opencode", "cursor", "aider", "continue", "all")]
    [string]$Target = "all"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$AiConfigDir = "$ProjectDir\.ai-config"

Write-Host "=== Sync AI Config ===" -ForegroundColor Cyan

function Generate-Claude {
    Write-Host "Generating Claude Code config..." -ForegroundColor Yellow

    # Crear directorio .claude
    New-Item -ItemType Directory -Path "$ProjectDir\.claude" -Force | Out-Null

    # Iniciar CLAUDE.md
    $content = @"
# Claude Code Instructions

> Auto-generated from .ai-config/

"@

    # Agregar prompt base
    $basePath = "$AiConfigDir\prompts\base.md"
    if (Test-Path $basePath) {
        $content += Get-Content $basePath -Raw
        $content += "`n---`n"
    }

    # Agregar agentes
    $content += "`n## Agentes Disponibles`n`n"
    Get-ChildItem "$AiConfigDir\agents\*.md" | Where-Object { $_.Name -ne "_TEMPLATE.md" } | ForEach-Object {
        $agentContent = Get-Content $_.FullName -Raw
        if ($agentContent -match "name:\s*(.+)") { $name = $matches[1].Trim() }
        if ($agentContent -match "description:\s*(.+)") { $desc = $matches[1].Trim() }
        $content += "- **$name**: $desc`n"
    }

    # Agregar skills
    $content += "`n## Skills Disponibles`n`n"
    Get-ChildItem "$AiConfigDir\skills\*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_TEMPLATE.md" } | ForEach-Object {
        $skillContent = Get-Content $_.FullName -Raw
        if ($skillContent -match "name:\s*(.+)") { $name = $matches[1].Trim() }
        $content += "- $name`n"
    }

    $content | Out-File -FilePath "$ProjectDir\CLAUDE.md" -Encoding utf8
    Write-Host "Done: Generated CLAUDE.md" -ForegroundColor Green
}

function Generate-OpenCode {
    Write-Host "Generating OpenCode config..." -ForegroundColor Yellow

    $content = @"
# OpenCode Agents

> Auto-generated from .ai-config/

"@

    Get-ChildItem "$AiConfigDir\agents\*.md" | Where-Object { $_.Name -ne "_TEMPLATE.md" } | ForEach-Object {
        $content += "`n---`n"
        $agentContent = Get-Content $_.FullName -Raw
        # Remover frontmatter YAML
        $agentContent = $agentContent -replace "(?s)^---.*?---\s*", ""
        $content += $agentContent
    }

    $content | Out-File -FilePath "$ProjectDir\AGENTS.md" -Encoding utf8
    Write-Host "Done: Generated AGENTS.md" -ForegroundColor Green
}

function Generate-Cursor {
    Write-Host "Generating Cursor config..." -ForegroundColor Yellow

    $content = @"
# Cursor Rules
# Auto-generated from .ai-config/

## Critical Rules

- NO AI attribution in commits, PRs, or code
- Always read files before modifying
- Run CI-Local before push
- Follow project conventions

"@

    $content | Out-File -FilePath "$ProjectDir\.cursorrules" -Encoding utf8
    Write-Host "Done: Generated .cursorrules" -ForegroundColor Green
}

function Generate-Aider {
    Write-Host "Generating Aider config..." -ForegroundColor Yellow

    $content = @"
# Aider Configuration
# Auto-generated from .ai-config/

model: claude-3-5-sonnet
auto-commits: false
dirty-commits: false

conventions:
  - No AI attribution in commits
  - Conventional commits format
  - Run CI-Local before push
"@

    $content | Out-File -FilePath "$ProjectDir\.aider.conf.yml" -Encoding utf8
    Write-Host "Done: Generated .aider.conf.yml" -ForegroundColor Green
}

function Generate-Continue {
    Write-Host "Generating Continue.dev config..." -ForegroundColor Yellow

    $continueDir = Join-Path $env:USERPROFILE ".continue"
    New-Item -ItemType Directory -Path $continueDir -Force | Out-Null

    $configPath = Join-Path $continueDir "config.json"
    if (-not (Test-Path $configPath)) {
        @"
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
"@ | Out-File -FilePath $configPath -Encoding utf8
        Write-Host "Done: Generated $configPath" -ForegroundColor Green
    } else {
        Write-Host "  $configPath already exists, skipping" -ForegroundColor Yellow
    }
}

# Main
switch ($Target) {
    "claude" { Generate-Claude }
    "opencode" { Generate-OpenCode }
    "cursor" { Generate-Cursor }
    "aider" { Generate-Aider }
    "continue" { Generate-Continue }
    "all" {
        Generate-Claude
        Generate-OpenCode
        Generate-Cursor
        Generate-Aider
    }
}

Write-Host ""
Write-Host "AI config sync complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Generated files:"
if (Test-Path "$ProjectDir\CLAUDE.md") { Write-Host "  - CLAUDE.md (Claude Code)" }
if (Test-Path "$ProjectDir\AGENTS.md") { Write-Host "  - AGENTS.md (OpenCode)" }
if (Test-Path "$ProjectDir\.cursorrules") { Write-Host "  - .cursorrules (Cursor)" }
if (Test-Path "$ProjectDir\.aider.conf.yml") { Write-Host "  - .aider.conf.yml (Aider)" }
Write-Host ""
