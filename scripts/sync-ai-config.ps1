# =============================================================================
# SYNC-AI-CONFIG: Genera configuracion para diferentes AI CLIs (Windows)
# =============================================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("config", "claude", "opencode", "cursor", "aider", "continue", "gemini", "commands", "all")]
    [string]$Target = "config",

    [Parameter(Position=1)]
    [string]$Mode = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$AiConfigDir = "$ProjectDir\.ai-config"
$SkillIgnoreFile = "$AiConfigDir\.skillignore"

Import-Module "$ScriptDir\..\lib\Common.psm1" -Force

Write-Host "=== Sync AI Config ===" -ForegroundColor Cyan

function Is-SkillIgnored {
    param(
        [Parameter(Mandatory=$true)][string]$SkillKey,
        [Parameter(Mandatory=$true)][string]$TargetName
    )

    if (-not (Test-Path $SkillIgnoreFile)) { return $false }

    foreach ($line in (Get-Content $SkillIgnoreFile -ErrorAction SilentlyContinue)) {
        $clean = ($line -replace '#.*$', '').Trim()
        if ([string]::IsNullOrWhiteSpace($clean)) { continue }

        if ($clean -match ':') {
            $parts = $clean.Split(':', 2)
            if ($parts.Count -eq 2 -and $parts[0] -eq $TargetName -and $parts[1] -eq $SkillKey) {
                return $true
            }
        } elseif ($clean -eq $SkillKey) {
            return $true
        }
    }

    return $false
}

function Generate-Claude {
    param(
        [string]$MergeArg = ""
    )
    Write-Host "Generating Claude Code config..." -ForegroundColor Yellow

    # Support optional 'merge' mode when caller provides extra arg or env var
    $mergeMode = $false
    if ($MergeArg -eq 'merge' -or $MergeArg -eq '--merge' -or $env:SYNC_AI_CONFIG_MODE -eq 'merge') { $mergeMode = $true }

    # Crear directorio .claude
    New-Item -ItemType Directory -Path "$ProjectDir\.claude" -Force | Out-Null

    if ((Test-Path "$ProjectDir\CLAUDE.md") -and $mergeMode) {
        Write-Host "CLAUDE.md exists — performing safe merge (append/update generated section)" -ForegroundColor Yellow
        Backup-IfExists "$ProjectDir\CLAUDE.md"

        $gen = @"

## Auto-generated from .ai-config/

"@
        $basePath = "$AiConfigDir\prompts\base.md"
        if (Test-Path $basePath) {
            $gen += Get-Content $basePath -Raw
            $gen += "`n---`n"
        }

        $gen += "`n## Agentes Disponibles`n`n"
        Get-ChildItem "$AiConfigDir\agents" -Recurse -Filter "*.md" | Where-Object { $_.Name -ne "_TEMPLATE.md" } | ForEach-Object {
            $agentContent = Get-Content $_.FullName -Raw
            if ($agentContent -match "name:\s*(.+)") { $name = $matches[1].Trim() } else { $name = '' }
            if ($agentContent -match "description:\s*(.+)") { $desc = $matches[1].Trim() } else { $desc = '' }
            if ($name) { $gen += "- **$name**: $desc`n" }
        }

        $gen += "`n## Skills Disponibles`n`n"
        Get-ChildItem "$AiConfigDir\skills" -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $relativeSkillPath = $_.FullName.Substring((Join-Path $AiConfigDir "skills").Length + 1).Replace("\", "/")
            $skillKey = $relativeSkillPath -replace "/SKILL\.md$", ""
            if (-not (Is-SkillIgnored -SkillKey $skillKey -TargetName "claude")) {
                $skillContent = Get-Content $_.FullName -Raw
                if ($skillContent -match "name:\s*(.+)") { $sname = $matches[1].Trim() } else { $sname = '' }
                if ($sname) { $gen += "- $sname`n" }
            }
        }

        # If existing file already contains our auto-generated marker, replace that section
        $existing = Get-Content "$ProjectDir\CLAUDE.md" -Raw
        if ($existing -match "(?ms)## Auto-generated from \.ai-config/.*$") {
            # Remove from marker to EOF and append new generated block
            $before = ($existing -split "(?ms)## Auto-generated from \.ai-config/")[0]
            $before = $before.TrimEnd()
            ($before + "`n" + $gen) | Out-File -FilePath "$ProjectDir\CLAUDE.md" -Encoding utf8
        } else {
            # Append generated section at EOF
            $existing + "`n" + $gen | Out-File -FilePath "$ProjectDir\CLAUDE.md" -Encoding utf8
        }

        Write-Host "Merged CLAUDE.md (auto-generated section updated)" -ForegroundColor Green
        return
    }

    # Default behavior: prompt/overwrite as before
    if (Test-Path "$ProjectDir\CLAUDE.md") {
        $overwrite = Read-Host "CLAUDE.md already exists. Overwrite? [y/N]"
        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Host "Skipped CLAUDE.md" -ForegroundColor Yellow
            return
        }
    }

    # Backup existing file before overwrite
    Backup-IfExists "$ProjectDir\CLAUDE.md"

    # Iniciar CLAUDE.md (overwrite)
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
    Get-ChildItem "$AiConfigDir\agents" -Recurse -Filter "*.md" | Where-Object { $_.Name -ne "_TEMPLATE.md" } | ForEach-Object {
        $name = ""
        $desc = ""
        $agentContent = Get-Content $_.FullName -Raw
        if ($agentContent -match "name:\s*(.+)") { $name = $matches[1].Trim() }
        if ($agentContent -match "description:\s*(.+)") { $desc = $matches[1].Trim() }
        if ($name) {
            $content += "- **$name**: $desc`n"
        }
    }

    # Agregar skills
    $content += "`n## Skills Disponibles`n`n"
    Get-ChildItem "$AiConfigDir\skills" -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $relativeSkillPath = $_.FullName.Substring((Join-Path $AiConfigDir "skills").Length + 1).Replace("\", "/")
        $skillKey = $relativeSkillPath -replace "/SKILL\.md$", ""
        if (-not (Is-SkillIgnored -SkillKey $skillKey -TargetName "claude")) {
            $name = ""
            $skillContent = Get-Content $_.FullName -Raw
            if ($skillContent -match "name:\s*(.+)") { $name = $matches[1].Trim() }
            if ($name) {
                $content += "- $name`n"
            }
        }
    }

    $content | Out-File -FilePath "$ProjectDir\CLAUDE.md" -Encoding utf8
    Write-Host "Done: Generated CLAUDE.md" -ForegroundColor Green
}

function Generate-OpenCode {
    Write-Host "Generating OpenCode config..." -ForegroundColor Yellow

    # Backup existing file before overwrite
    Backup-IfExists "$ProjectDir\AGENTS.md"

    $content = @"
# OpenCode Agents

> Auto-generated from .ai-config/

"@

    Get-ChildItem "$AiConfigDir\agents" -Recurse -Filter "*.md" | Where-Object { $_.Name -ne "_TEMPLATE.md" } | ForEach-Object {
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

    # Backup existing file before overwrite
    Backup-IfExists "$ProjectDir\.cursorrules"

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

    # Backup existing file before overwrite
    Backup-IfExists "$ProjectDir\.aider.conf.yml"

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

function Generate-Commands {
    Write-Host "Syncing commands to .claude/commands..." -ForegroundColor Yellow

    $srcDir = Join-Path $AiConfigDir "commands"
    $destDir = Join-Path $ProjectDir ".claude\commands"

    if (-not (Test-Path $srcDir -PathType Container)) {
        Write-Host "  No .ai-config/commands directory found, skipping" -ForegroundColor Yellow
        return
    }

    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    $count = 0
    Get-ChildItem -Path $srcDir -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $relative = $_.FullName.Substring($srcDir.Length + 1)
        $targetPath = Join-Path $destDir $relative
        $targetParent = Split-Path -Parent $targetPath
        if (-not (Test-Path $targetParent -PathType Container)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
        Copy-Item -Path $_.FullName -Destination $targetPath -Force
        $count++
    }

    Write-Host "Done: Synced $count commands to .claude/commands" -ForegroundColor Green
}

function Generate-Gemini {
    Write-Host "Generating Gemini CLI config..." -ForegroundColor Yellow

    if (Test-Path "$ProjectDir\GEMINI.md") {
        $overwrite = Read-Host "GEMINI.md already exists. Overwrite? [y/N]"
        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Host "Skipped GEMINI.md" -ForegroundColor Yellow
            return
        }
    }

    Backup-IfExists "$ProjectDir\GEMINI.md"

    $content = @"
# Gemini CLI Instructions

> Auto-generated from .ai-config/

"@

    $basePath = "$AiConfigDir\prompts\base.md"
    if (Test-Path $basePath) {
        $content += Get-Content $basePath -Raw
        $content += "`n---`n"
    }

    $content += "`n## Agentes Disponibles`n`n"
    Get-ChildItem "$AiConfigDir\agents" -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_TEMPLATE.md" } | ForEach-Object {
        $name = ""
        $desc = ""
        $agentContent = Get-Content $_.FullName -Raw
        if ($agentContent -match "name:\s*(.+)") { $name = $matches[1].Trim() }
        if ($agentContent -match "description:\s*(.+)") { $desc = $matches[1].Trim() }
        if ($name) {
            $content += "- **$name**: $desc`n"
        }
    }

    $content += "`n## Skills Disponibles`n`n"
    Get-ChildItem "$AiConfigDir\skills" -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $relativeSkillPath = $_.FullName.Substring((Join-Path $AiConfigDir "skills").Length + 1).Replace("\", "/")
        $skillKey = $relativeSkillPath -replace "/SKILL\.md$", ""
        if (-not (Is-SkillIgnored -SkillKey $skillKey -TargetName "gemini")) {
            $name = ""
            $skillContent = Get-Content $_.FullName -Raw
            if ($skillContent -match "name:\s*(.+)") { $name = $matches[1].Trim() }
            if ($name) { $content += "- $name`n" }
        }
    }

    $content | Out-File -FilePath "$ProjectDir\GEMINI.md" -Encoding utf8
    Write-Host "Done: Generated GEMINI.md" -ForegroundColor Green
}

function Run-FromConfig {
    $configPath = Join-Path $AiConfigDir "config.yaml"
    if (-not (Test-Path $configPath -PathType Leaf)) {
        Write-Host "No config.yaml found, running all targets" -ForegroundColor Yellow
        Generate-Claude
        Generate-OpenCode
        Generate-Cursor
        Generate-Aider
        Generate-Gemini
        Generate-Commands
        return
    }

    Write-Host "Reading targets from .ai-config/config.yaml..." -ForegroundColor Cyan
    $configLines = Get-Content $configPath -ErrorAction SilentlyContinue
    $claudeMode = ""
    foreach ($line in $configLines) {
        if ($line -match '^\s*claude_mode:\s*([A-Za-z0-9_-]+)\s*$') {
            $claudeMode = $matches[1]
            break
        }
    }

    $targets = @()
    $inTargets = $false
    foreach ($line in $configLines) {
        if ($line -match '^\s*targets:\s*$') {
            $inTargets = $true
            continue
        }
        if ($inTargets -and $line -match '^[A-Za-z0-9_-]+\s*:') {
            $inTargets = $false
        }
        if ($inTargets -and $line -match '^\s*-\s*([A-Za-z0-9_-]+)\s*$') {
            $targets += $matches[1]
        }
    }

    if ($targets.Count -eq 0) {
        Write-Host "No targets found in config.yaml, running all targets" -ForegroundColor Yellow
        Generate-Claude
        Generate-OpenCode
        Generate-Cursor
        Generate-Aider
        Generate-Gemini
        Generate-Commands
        return
    }

    foreach ($configuredTarget in $targets) {
        switch ($configuredTarget) {
            "claude" { Generate-Claude -MergeArg $claudeMode }
            "opencode" { Generate-OpenCode }
            "cursor" { Generate-Cursor }
            "aider" { Generate-Aider }
            "continue" { Generate-Continue }
            "gemini" { Generate-Gemini }
            "commands" { Generate-Commands }
            default { Write-Host "Unknown target: $configuredTarget (skipped)" -ForegroundColor Yellow }
        }
    }
}

# Main
switch ($Target) {
    "config" { Run-FromConfig }
    "claude" { Generate-Claude -MergeArg $Mode }
    "opencode" { Generate-OpenCode }
    "cursor" { Generate-Cursor }
    "aider" { Generate-Aider }
    "continue" { Generate-Continue }
    "gemini" { Generate-Gemini }
    "commands" { Generate-Commands }
    "all" {
        Generate-Claude -MergeArg $Mode
        Generate-OpenCode
        Generate-Cursor
        Generate-Aider
        Generate-Gemini
        Generate-Commands
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
if (Test-Path "$ProjectDir\GEMINI.md") { Write-Host "  - GEMINI.md (Gemini CLI)" }
Write-Host ""
