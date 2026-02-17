# =============================================================================
# SYNC-SKILLS: Sincroniza skills con AUTO_INVOKE.md y genera symlinks multi-IDE
# =============================================================================
# Uso:
#   .\scripts\sync-skills.ps1 list      # Listar skills
#   .\scripts\sync-skills.ps1 validate  # Validar formato
#   .\scripts\sync-skills.ps1 symlinks  # Crear symlinks multi-IDE
#   .\scripts\sync-skills.ps1 all       # Todo junto
# =============================================================================

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$AiConfig = Join-Path $ProjectRoot ".ai-config"
$SkillsDir = Join-Path $AiConfig "skills"

Write-Host "=== Skill Sync Tool ===" -ForegroundColor Blue
Write-Host ""

function List-Skills {
    Write-Host "Skills disponibles:" -ForegroundColor Green
    Write-Host ""
    Write-Host ("{0,-25} {1,-50} {2}" -f "SKILL", "DESCRIPTION", "SCOPE")
    Write-Host ("{0,-25} {1,-50} {2}" -f "-----", "-----------", "-----")

    Get-ChildItem -Path $SkillsDir -Recurse -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -ne "_TEMPLATE" } |
        ForEach-Object {
            $skillName = $_.BaseName
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue

            # Extract description
            $description = ""
            if ($content -match "description:\s*(.+)") {
                $description = $matches[1].Substring(0, [Math]::Min(50, $matches[1].Length))
            }

            # Extract scope
            $scope = "global"
            if ($content -match "scope:\s*\[(.+)\]") {
                $scope = $matches[1]
            }

            Write-Host ("{0,-25} {1,-50} {2}" -f $skillName, $description, $scope)
        }
}

function Validate-Skills {
    Write-Host "Validando skills..." -ForegroundColor Blue
    $errors = 0

    Get-ChildItem -Path $SkillsDir -Recurse -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -ne "_TEMPLATE" } |
        ForEach-Object {
            $skillName = $_.BaseName
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            $lines = Get-Content $_.FullName -ErrorAction SilentlyContinue

            # Check frontmatter
            if ($lines[0] -ne "---") {
                Write-Host "  [$skillName] Falta frontmatter YAML" -ForegroundColor Red
                $errors++
                return
            }

            # Check required fields
            if ($content -notmatch "name:") {
                Write-Host "  [$skillName] Falta campo 'name'" -ForegroundColor Red
                $errors++
            }

            if ($content -notmatch "description:") {
                Write-Host "  [$skillName] Falta campo 'description'" -ForegroundColor Red
                $errors++
            }

            # Check Related Skills section
            if ($content -notmatch "## Related Skills") {
                Write-Host "  [$skillName] Falta seccion 'Related Skills'" -ForegroundColor Yellow
            }
        }

    if ($errors -eq 0) {
        Write-Host "Todos los skills son validos" -ForegroundColor Green
    } else {
        Write-Host "Se encontraron $errors errores" -ForegroundColor Red
    }
}

function Setup-Symlinks {
    Write-Host "Generando symlinks multi-IDE..." -ForegroundColor Blue

    $agentsMd = Join-Path $ProjectRoot "AGENTS.md"
    $claudeMd = Join-Path $ProjectRoot "CLAUDE.md"
    $geminiMd = Join-Path $ProjectRoot "GEMINI.md"
    $githubDir = Join-Path $ProjectRoot ".github"
    $copilotMd = Join-Path $githubDir "copilot-instructions.md"

    # Create AGENTS.md if not exists
    if (-not (Test-Path $agentsMd)) {
        Write-Host "Creando AGENTS.md base..." -ForegroundColor Yellow
        @"
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
"@ | Out-File -FilePath $agentsMd -Encoding utf8
    }

    # Note: Windows doesn't support symlinks easily without admin
    # So we copy the content instead
    if (Test-Path $agentsMd) {
        Copy-Item -Path $agentsMd -Destination $claudeMd -Force
        Write-Host "  CLAUDE.md <- AGENTS.md (copied)" -ForegroundColor Green

        Copy-Item -Path $agentsMd -Destination $geminiMd -Force
        Write-Host "  GEMINI.md <- AGENTS.md (copied)" -ForegroundColor Green

        if (-not (Test-Path $githubDir)) {
            New-Item -ItemType Directory -Path $githubDir -Force | Out-Null
        }
        Copy-Item -Path $agentsMd -Destination $copilotMd -Force
        Write-Host "  .github/copilot-instructions.md <- AGENTS.md (copied)" -ForegroundColor Green
    }

    Write-Host "Files creados exitosamente" -ForegroundColor Green
}

function Generate-Summary {
    Write-Host "Generando resumen de skills..." -ForegroundColor Blue

    $summaryFile = Join-Path $AiConfig "SKILLS_SUMMARY.md"

    $content = @"
# Skills Summary

> Auto-generated. Do not edit manually.

## By Category

"@

    $categories = @{
        "Frontend" = "frontend|mantine|astro|tanstack|zod|zustand"
        "Backend" = "chi|pgx|go-backend|fastapi|jwt"
        "Database" = "timescale|redis|sqlite|duckdb|postgres"
        "Infrastructure" = "kubernetes|docker|devops|traefik|opentelemetry"
        "AI-ML" = "langchain|ai-ml|onnx|pytorch|scikit|mlflow|vector"
        "Testing" = "playwright|vitest|test"
        "Mobile" = "ionic|capacitor|mobile"
    }

    foreach ($category in $categories.Keys) {
        $content += "`n### $category`n"
        $pattern = $categories[$category]

        Get-ChildItem -Path $SkillsDir -Recurse -Filter "*.md" -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -ne "_TEMPLATE" -and $_.BaseName -match $pattern } |
            ForEach-Object {
                $skillName = $_.BaseName
                $fileContent = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                $desc = ""
                if ($fileContent -match "description:\s*(.{1,60})") {
                    $desc = $matches[1]
                }
                $content += "- ``$skillName``: $desc`n"
            }
    }

    $content | Out-File -FilePath $summaryFile -Encoding utf8
    Write-Host "Resumen generado: $summaryFile" -ForegroundColor Green
}

function Show-Help {
    Write-Host "Uso: .\sync-skills.ps1 <comando>"
    Write-Host ""
    Write-Host "Comandos:"
    Write-Host "  list      - Listar todos los skills disponibles"
    Write-Host "  validate  - Validar formato de skills"
    Write-Host "  symlinks  - Crear archivos multi-IDE (CLAUDE.md, GEMINI.md, etc.)"
    Write-Host "  summary   - Generar resumen de skills"
    Write-Host "  all       - Ejecutar validate + summary + symlinks"
    Write-Host ""
    Write-Host "Ejemplos:"
    Write-Host "  .\sync-skills.ps1 list"
    Write-Host "  .\sync-skills.ps1 validate"
    Write-Host "  .\sync-skills.ps1 all"
}

# =============================================================================
# Main
# =============================================================================
switch ($Command.ToLower()) {
    "list" {
        List-Skills
    }
    "validate" {
        Validate-Skills
    }
    { $_ -in "symlinks", "setup" } {
        Setup-Symlinks
    }
    "summary" {
        Generate-Summary
    }
    "all" {
        Validate-Skills
        Write-Host ""
        Generate-Summary
        Write-Host ""
        Setup-Symlinks
    }
    default {
        Show-Help
    }
}
