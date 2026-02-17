# =============================================================================
# INIT-PROJECT: Setup inicial para nuevo proyecto (Windows)
# =============================================================================

param(
    [switch]$DryRun,
    [switch]$Help,
    [switch]$NonInteractive,
    [string]$Memory = "",
    [string]$CI = "",
    [switch]$Engram,
    [switch]$Ghagga
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Import-Module "$ScriptDir/../lib/Common.psm1" -Force

# =============================================================================
# Help
# =============================================================================
if ($Help) {
    Write-Host "Usage: .\init-project.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Setup inicial para nuevo proyecto."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -DryRun             Show what would be done without making changes"
    Write-Host "  -NonInteractive     Run without prompts (use defaults or -Memory/-CI flags)"
    Write-Host "  -Memory N           Memory module choice: 1=obsidian-brain, 2=vibekanban, 3=memory-simple, 4=engram, 5=none"
    Write-Host "  -CI N               CI provider: 1=github, 2=gitlab, 3=woodpecker, 4=none"
    Write-Host "  -Engram             Add Engram module (when using -Memory 1)"
    Write-Host "  -Ghagga             Add GHAGGA integration (when using -CI 1)"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    exit 0
}

# =============================================================================
# Dry-run helpers
# =============================================================================
$script:DryRunActions = @()

function Invoke-DryRunCmd {
    param(
        [string]$Description,
        [scriptblock]$Action
    )
    if ($DryRun) {
        Write-Host "  [DRY-RUN] Would execute: $Description" -ForegroundColor Cyan
        $script:DryRunActions += $Description
    } else {
        & $Action
    }
}

function Copy-DryRun {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Recurse,
        [switch]$Force
    )
    if ($DryRun) {
        Write-Host "  [DRY-RUN] Would copy: $Source -> $Destination" -ForegroundColor Cyan
        $script:DryRunActions += "Copy $Source -> $Destination"
    } else {
        $params = @{ Path = $Source; Destination = $Destination }
        if ($Recurse) { $params.Recurse = $true }
        if ($Force) { $params.Force = $true }
        Copy-Item @params
    }
}

function New-DryRunDirectory {
    param([string]$Path)
    if ($DryRun) {
        Write-Host "  [DRY-RUN] Would create directory: $Path" -ForegroundColor Cyan
        $script:DryRunActions += "Create directory $Path"
    } else {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-DryRunFile {
    param(
        [string]$Path,
        [string]$Content,
        [string]$Description = $Path
    )
    if ($DryRun) {
        Write-Host "  [DRY-RUN] Would write file: $Path" -ForegroundColor Cyan
        $script:DryRunActions += "Write $Description"
    } else {
        $Content | Out-File -FilePath $Path -Encoding utf8
    }
}

# =============================================================================
# Reusable function: Install Engram module
# =============================================================================
# Installs the Engram memory module (MCP server config, install scripts,
# gitignore snippet). Called from memory choice "4" and from the secondary
# prompt when adding Engram alongside obsidian-brain.
# =============================================================================
function Install-EngramModule {
    param([string]$FrameworkPath)

    Write-Host "  Installing Engram module..." -ForegroundColor Green

    $projectName = Split-Path -Leaf (Get-Location)

    if (Test-Path "$FrameworkPath/optional/engram/.mcp-config-snippet.json") {
        if (-not (Test-Path ".mcp.json")) {
            if ($DryRun) {
                Write-Host "  [DRY-RUN] Would generate .mcp.json from template" -ForegroundColor Cyan
                $script:DryRunActions += "Generate .mcp.json"
            } else {
                $mcpContent = Get-Content "$FrameworkPath/optional/engram/.mcp-config-snippet.json" -Raw
                $mcpContent = $mcpContent -replace '__PROJECT_NAME__', $projectName
                $mcpContent | Out-File -FilePath ".mcp.json" -Encoding utf8
            }
        } else {
            Write-Host "  .mcp.json ya existe - agrega engram manualmente" -ForegroundColor Yellow
            Write-Host "  Ver: optional/engram/.mcp-config-snippet.json"
        }
    }

    Backup-IfExists "scripts/install-engram.sh"
    if (Test-Path "$FrameworkPath/optional/engram/install-engram.sh") {
        Copy-DryRun -Source "$FrameworkPath/optional/engram/install-engram.sh" -Destination "scripts/" -Force
    }
    Backup-IfExists "scripts/install-engram.ps1"
    if (Test-Path "$FrameworkPath/optional/engram/install-engram.ps1") {
        Copy-DryRun -Source "$FrameworkPath/optional/engram/install-engram.ps1" -Destination "scripts/" -Force
    }

    $snippetPath = "$FrameworkPath/optional/engram/.gitignore-snippet.txt"
    if (Test-Path $snippetPath) {
        if ($DryRun) {
            Write-Host "  [DRY-RUN] Would append engram gitignore snippet" -ForegroundColor Cyan
            $script:DryRunActions += "Append engram gitignore snippet"
        } else {
            Add-Content -Path ".gitignore" -Value ""
            Get-Content $snippetPath | Add-Content -Path ".gitignore"
        }
    }

    Write-Host "  Engram module installed" -ForegroundColor Green
}

if ($DryRun) {
    Write-Host "=== DRY-RUN MODE: No changes will be made ===" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           PROJECT STARTER FRAMEWORK v2.0                   ║" -ForegroundColor Cyan
Write-Host "║                  Init Project                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Set-Location $ProjectDir

# =============================================================================
# 1. Verificar repo git
# =============================================================================
Write-Host "[1/8] Verificando repositorio Git..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    Write-Host "  No es un repo git. Inicializando..." -ForegroundColor Yellow
    Invoke-DryRunCmd -Description "git init" -Action { git init }
    Invoke-DryRunCmd -Description "git checkout -b main" -Action { git checkout -b main }
    Write-Host "  Done: Repo inicializado con branch main" -ForegroundColor Green
} else {
    Write-Host "  Done: Repo git existente" -ForegroundColor Green
}

# =============================================================================
# 2. Configurar git hooks
# =============================================================================
Write-Host "[2/8] Configurando git hooks..." -ForegroundColor Yellow
if (Test-Path ".ci-local/hooks") {
    Invoke-DryRunCmd -Description "git config core.hooksPath .ci-local/hooks" -Action { git config core.hooksPath .ci-local/hooks }
    Write-Host "  Done: Hooks configurados" -ForegroundColor Green
} else {
    Write-Host "  Warning: .ci-local/hooks no encontrado" -ForegroundColor Yellow
}

# =============================================================================
# 3. Detectar stack
# =============================================================================
Write-Host "[3/8] Detectando stack tecnológico..." -ForegroundColor Yellow

$StackInfo = Detect-Stack -ProjectPath "."
$Stack = $StackInfo.StackType

if ($Stack -ne "unknown") {
    Write-Host "  Done: Detectado $Stack" -ForegroundColor Green
} else {
    Write-Host "  Warning: No se detectó stack" -ForegroundColor Yellow
}

# =============================================================================
# 4. Verificar dependencias
# =============================================================================
Write-Host "[4/8] Verificando dependencias..." -ForegroundColor Yellow

try {
    $null = docker info 2>$null
    Write-Host "  Done: Docker disponible" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Docker no disponible (opcional para CI-Local full)" -ForegroundColor Yellow
}

if (Get-Command semgrep -ErrorAction SilentlyContinue) {
    Write-Host "  Done: Semgrep instalado" -ForegroundColor Green
} else {
    Write-Host "  Warning: Semgrep no instalado (pip install semgrep)" -ForegroundColor Yellow
}

# =============================================================================
# 5. Crear .gitignore si no existe
# =============================================================================
Write-Host "[5/8] Verificando .gitignore..." -ForegroundColor Yellow
if (-not (Test-Path ".gitignore")) {
    $gitignoreContent = @"
# CI Local
.ci-local/docker/
.ci-local-image-built
semgrep-report.json
semgrep-results.json

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db

# Env
.env
.env.local
.env.*.local
*.env

# Credentials
.npmrc
credentials.json
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore
.aws/
.ssh/
.gcp/
service-account*.json

# Build
*.log
coverage/
dist/
build/
target/
node_modules/
__pycache__/
.pytest_cache/

# AI config (generated, not committed)
CLAUDE.md
AGENTS.md
GEMINI.md
.cursorrules
.aider.conf.yml
.continue/
"@
    Write-DryRunFile -Path ".gitignore" -Content $gitignoreContent
    Write-Host "  Done: .gitignore creado" -ForegroundColor Green
} else {
    Write-Host "  Done: .gitignore existente" -ForegroundColor Green
}

# =============================================================================
# 6. Módulos opcionales
# =============================================================================
Write-Host "[6/8] Módulos opcionales..." -ForegroundColor Yellow

$Framework = Detect-Framework
$FrameworkDir = $Framework.FrameworkDir
$HasOptional = $Framework.HasOptional

if ($FrameworkDir -ne "") {
    # Copy shared library to target project
    New-DryRunDirectory -Path "lib"
    Copy-DryRun -Source "$FrameworkDir/lib/common.sh" -Destination "lib/common.sh" -Force
    Write-Host "  lib/common.sh copied" -ForegroundColor Green

    if ($HasOptional) {
        Write-Host "  Instalar modulo de memoria del proyecto?" -ForegroundColor Cyan
        Write-Host "    1) obsidian-brain  - Vault Obsidian + Kanban + memoria estructurada (RECOMENDADO)"
        Write-Host "    2) vibekanban      - Oleadas paralelas + memoria (legacy)"
        Write-Host "    3) simple          - Solo un archivo NOTES.md"
        Write-Host "    4) engram          - Memoria persistente para agentes AI (MCP server)"
        Write-Host "    5) ninguno         - Sin memoria de proyecto"
        Write-Host ""
        Write-Host "  Nota: engram complementa a obsidian-brain (pueden usarse juntos)" -ForegroundColor Yellow
        Write-Host ""
        if ($NonInteractive) {
            if ($Memory -ne "") {
                $choice = $Memory
            } else {
                $choice = "5"
            }
        } else {
            $choice = Read-Host "  Opcion [1/2/3/4/5]"
        }

        switch ($choice) {
            "1" {
                if (Test-Path "$FrameworkDir/optional/obsidian-brain/.project") {
                    Copy-DryRun -Source "$FrameworkDir/optional/obsidian-brain/.project" -Destination "." -Recurse -Force
                    Copy-DryRun -Source "$FrameworkDir/optional/obsidian-brain/.obsidian" -Destination "." -Recurse -Force
                    if (Test-Path "$FrameworkDir/optional/obsidian-brain/new-wave.ps1") {
                        Backup-IfExists "scripts/new-wave.ps1"
                        Copy-DryRun -Source "$FrameworkDir/optional/obsidian-brain/new-wave.ps1" -Destination "scripts/" -Force
                    }
                    if (Test-Path "$FrameworkDir/optional/obsidian-brain/new-wave.sh") {
                        Backup-IfExists "scripts/new-wave.sh"
                        Copy-DryRun -Source "$FrameworkDir/optional/obsidian-brain/new-wave.sh" -Destination "scripts/" -Force
                    }
                    # Append gitignore snippet
                    $snippetPath = "$FrameworkDir/optional/obsidian-brain/.obsidian-gitignore-snippet.txt"
                    if (Test-Path $snippetPath) {
                        if ($DryRun) {
                            Write-Host "  [DRY-RUN] Would append .obsidian-gitignore-snippet.txt to .gitignore" -ForegroundColor Cyan
                            $script:DryRunActions += "Append obsidian gitignore snippet"
                        } else {
                            Add-Content -Path ".gitignore" -Value ""
                            Get-Content $snippetPath | Add-Content -Path ".gitignore"
                        }
                    }
                    Write-Host "  Done: Obsidian Brain instalado" -ForegroundColor Green
                    Write-Host "  Nota: Instala plugins Kanban, Dataview y Templater desde Obsidian" -ForegroundColor Cyan
                }
            }
            "2" {
                if (Test-Path "$FrameworkDir/optional/vibekanban/.project") {
                    Copy-DryRun -Source "$FrameworkDir/optional/vibekanban/.project" -Destination "." -Recurse -Force
                    if (Test-Path "$FrameworkDir/optional/vibekanban/new-wave.ps1") {
                        Backup-IfExists "scripts/new-wave.ps1"
                        Copy-DryRun -Source "$FrameworkDir/optional/vibekanban/new-wave.ps1" -Destination "scripts/" -Force
                    }
                    if (Test-Path "$FrameworkDir/optional/vibekanban/new-wave.sh") {
                        Backup-IfExists "scripts/new-wave.sh"
                        Copy-DryRun -Source "$FrameworkDir/optional/vibekanban/new-wave.sh" -Destination "scripts/" -Force
                    }
                    Write-Host "  Done: VibeKanban instalado (legacy)" -ForegroundColor Green
                }
            }
            "3" {
                if (Test-Path "$FrameworkDir/optional/memory-simple/.project") {
                    Copy-DryRun -Source "$FrameworkDir/optional/memory-simple/.project" -Destination "." -Recurse -Force
                    Write-Host "  Done: Memory simple instalado" -ForegroundColor Green
                }
            }
            "4" {
                if (Test-Path "$FrameworkDir/optional/engram") {
                    Install-EngramModule -FrameworkPath $FrameworkDir
                    Write-Host "  Ejecuta: .\scripts\install-engram.ps1 para instalar el binario" -ForegroundColor Cyan
                }
            }
            default {
                Write-Host "  Done: Sin modulo de memoria" -ForegroundColor Green
            }
        }

        # Ask about engram addon if they chose obsidian-brain
        if ($choice -eq "1" -and (Test-Path "$FrameworkDir/optional/engram")) {
            Write-Host ""
            if ($NonInteractive) {
                if ($Engram) {
                    $addEngram = "y"
                } else {
                    $addEngram = "N"
                }
            } else {
                $addEngram = Read-Host "  Agregar tambien Engram para memoria de agentes AI? [y/N]"
            }
            if ($addEngram -eq "y" -or $addEngram -eq "Y") {
                Install-EngramModule -FrameworkPath $FrameworkDir
                Write-Host "  Done: Engram agregado (complementa Obsidian Brain)" -ForegroundColor Green
                Write-Host "  Ejecuta: .\scripts\install-engram.ps1 para instalar el binario" -ForegroundColor Cyan
            }
        }
    } else {
        # Framework detected but optional/ dir not present - create basic memory structure
        Write-Host "  optional/ no disponible. Creando estructura basica de memoria..." -ForegroundColor Yellow
        New-DryRunDirectory -Path ".project/Memory"
        if ($DryRun) {
            Write-Host "  [DRY-RUN] Would create CONTEXT.md, DECISIONS.md, BLOCKERS.md, KANBAN.md" -ForegroundColor Cyan
            $script:DryRunActions += "Create basic memory files"
        } else {
            @("CONTEXT.md", "DECISIONS.md", "BLOCKERS.md", "KANBAN.md") | ForEach-Object {
                $filePath = ".project/Memory/$_"
                if (-not (Test-Path $filePath)) {
                    New-Item -ItemType File -Path $filePath -Force | Out-Null
                }
            }
        }
        Write-Host "  Done: Estructura basica .project/Memory/ creada" -ForegroundColor Green
    }
} else {
    Write-Host "  Done: Modulos ya configurados o no disponibles" -ForegroundColor Green
}

# =============================================================================
# Helper: Assemble dependabot.yml from template files
# =============================================================================
function Get-DependabotContent {
    param([string]$StackType)

    $templateDir = "$FrameworkDir/templates/common/dependabot"
    $content = ""

    # Header (version + updates key)
    $headerFile = "$templateDir/header.yml"
    if (Test-Path $headerFile) {
        $content += (Get-Content $headerFile -Raw)
    } else {
        $content += "version: 2`n`nupdates:`n"
    }

    # GitHub Actions ecosystem (always included)
    $actionsFile = "$templateDir/github-actions.yml"
    if (Test-Path $actionsFile) {
        $content += (Get-Content $actionsFile -Raw)
    }

    # Stack-specific ecosystem
    $ecosystemFile = ""
    switch ($StackType) {
        "java-gradle" { $ecosystemFile = "gradle.yml" }
        "java-maven"  { $ecosystemFile = "maven.yml" }
        "node"        { $ecosystemFile = "npm.yml" }
        "python"      { $ecosystemFile = "pip.yml" }
        "go"          { $ecosystemFile = "gomod.yml" }
        "rust"        { $ecosystemFile = "cargo.yml" }
    }

    if ($ecosystemFile -ne "" -and (Test-Path "$templateDir/$ecosystemFile")) {
        $content += (Get-Content "$templateDir/$ecosystemFile" -Raw)
    }

    return $content
}

# =============================================================================
# 7. CI Provider
# =============================================================================
Write-Host "[7/8] Configurando CI remoto..." -ForegroundColor Yellow

# Map stack to template suffix
$TemplateSuffix = ""
switch ($Stack) {
    "java-gradle"  { $TemplateSuffix = "java" }
    "java-maven"   { $TemplateSuffix = "java" }
    "node"         { $TemplateSuffix = "node" }
    "python"       { $TemplateSuffix = "python" }
    "go"           { $TemplateSuffix = "go" }
    "rust"         { $TemplateSuffix = "rust" }
}

if ($FrameworkDir -ne "" -and $TemplateSuffix -ne "") {
    Write-Host "  Que CI remoto usar?" -ForegroundColor Cyan
    Write-Host "    1) GitHub Actions"
    Write-Host "    2) GitLab CI"
    Write-Host "    3) Woodpecker CI"
    Write-Host "    4) Solo CI-Local (sin CI remoto)"
    Write-Host ""
    if ($NonInteractive) {
        if ($CI -ne "") {
            $ciChoice = $CI
        } else {
            $ciChoice = "4"
        }
    } else {
        $ciChoice = Read-Host "  Opcion [1/2/3/4]"
    }

    switch ($ciChoice) {
        "1" {
            New-DryRunDirectory -Path ".github/workflows"
            New-DryRunDirectory -Path ".github/ISSUE_TEMPLATE"

            # CI workflow
            $src = "$FrameworkDir/templates/github/ci-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Backup-IfExists ".github/workflows/ci.yml"
                Copy-DryRun -Source $src -Destination ".github/workflows/ci.yml" -Force
                Write-Host "  Done: GitHub Actions configurado (.github/workflows/ci.yml)" -ForegroundColor Green
            } else {
                Write-Host "  Warning: Template $src no encontrado" -ForegroundColor Yellow
            }

            # Dependabot auto-merge workflow
            $automerge = "$FrameworkDir/templates/github/dependabot-automerge.yml"
            if (Test-Path $automerge) {
                Backup-IfExists ".github/workflows/dependabot-automerge.yml"
                Copy-DryRun -Source $automerge -Destination ".github/workflows/dependabot-automerge.yml" -Force
                Write-Host "  Done: Dependabot auto-merge configurado" -ForegroundColor Green
            }

            # Assemble dependabot.yml from template fragments
            Backup-IfExists ".github/dependabot.yml"
            $dependabotContent = Get-DependabotContent -StackType $Stack
            Write-DryRunFile -Path ".github/dependabot.yml" -Content $dependabotContent -Description "dependabot.yml (assembled from templates)"
            Write-Host "  Done: Dependabot configurado (.github/dependabot.yml)" -ForegroundColor Green

            # Issue and PR templates
            $issueTemplateDir = "$FrameworkDir/.github/ISSUE_TEMPLATE"
            if (Test-Path $issueTemplateDir) {
                if ($DryRun) {
                    Write-Host "  [DRY-RUN] Would copy issue templates from $issueTemplateDir" -ForegroundColor Cyan
                    $script:DryRunActions += "Copy issue templates"
                } else {
                    Get-ChildItem "$issueTemplateDir/*.md" -ErrorAction SilentlyContinue | ForEach-Object {
                        Copy-Item $_.FullName ".github/ISSUE_TEMPLATE/" -Force
                    }
                }
                Write-Host "  Done: Issue templates copiados" -ForegroundColor Green
            }
            $prTemplate = "$FrameworkDir/.github/PULL_REQUEST_TEMPLATE.md"
            if (Test-Path $prTemplate) {
                Backup-IfExists ".github/PULL_REQUEST_TEMPLATE.md"
                Copy-DryRun -Source $prTemplate -Destination ".github/PULL_REQUEST_TEMPLATE.md" -Force
                Write-Host "  Done: PR template copiado" -ForegroundColor Green
            }

            # GHAGGA AI Code Review (optional)
            if (Test-Path "$FrameworkDir/optional/ghagga") {
                Write-Host ""
                if ($NonInteractive) {
                    if ($Ghagga) {
                        $addGhagga = "y"
                    } else {
                        $addGhagga = "N"
                    }
                } else {
                    $addGhagga = Read-Host "  Agregar AI code review con GHAGGA? [y/N]"
                }
                if ($addGhagga -eq "y" -or $addGhagga -eq "Y") {
                    $reusableGhagga = "$FrameworkDir/.github/workflows/reusable-ghagga-review.yml"
                    if (Test-Path $reusableGhagga) {
                        Copy-DryRun -Source $reusableGhagga -Destination ".github/workflows/" -Force
                    }
                    # Create GHAGGA workflow
                    $ghaggaContent = @"
name: AI Code Review
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main, develop]
concurrency:
  group: ghagga-`${{ github.event.pull_request.number }}
  cancel-in-progress: true
jobs:
  review:
    uses: JNZader/project-starter-framework/.github/workflows/reusable-ghagga-review.yml@main
    with:
      ghagga-url: `${{ vars.GHAGGA_URL }}
      review-mode: simple
    secrets:
      ghagga-token: `${{ secrets.GHAGGA_TOKEN }}
"@
                    Write-DryRunFile -Path ".github/workflows/ghagga-review.yml" -Content $ghaggaContent -Description "GHAGGA review workflow"
                    Write-Host "  Done: GHAGGA AI review configurado" -ForegroundColor Green
                    Write-Host "  Configura GHAGGA_URL (variable) y GHAGGA_TOKEN (secret) en repo settings" -ForegroundColor Cyan
                }
            }
        }
        "2" {
            $src = "$FrameworkDir/templates/gitlab/gitlab-ci-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Backup-IfExists ".gitlab-ci.yml"
                Copy-DryRun -Source $src -Destination ".gitlab-ci.yml" -Force
                Write-Host "  Done: GitLab CI configurado (.gitlab-ci.yml)" -ForegroundColor Green
            } else {
                Write-Host "  Warning: Template $src no encontrado" -ForegroundColor Yellow
            }
        }
        "3" {
            $src = "$FrameworkDir/templates/woodpecker/woodpecker-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Backup-IfExists ".woodpecker.yml"
                Copy-DryRun -Source $src -Destination ".woodpecker.yml" -Force
                Write-Host "  Done: Woodpecker CI configurado (.woodpecker.yml)" -ForegroundColor Green
            } else {
                Write-Host "  Warning: Template $src no encontrado" -ForegroundColor Yellow
            }
        }
        default {
            Write-Host "  Done: Solo CI-Local (sin CI remoto)" -ForegroundColor Green
        }
    }
} elseif ($TemplateSuffix -eq "") {
    Write-Host "  Warning: Stack no detectado, configura CI remoto manualmente" -ForegroundColor Yellow
} else {
    Write-Host "  Done: CI remoto ya configurado o no disponible" -ForegroundColor Green
}

# =============================================================================
# 8. Configurar CLAUDE.md
# =============================================================================
Write-Host "[8/8] Configurando CLAUDE.md..." -ForegroundColor Yellow

$ProjectName = Split-Path -Leaf $ProjectDir

if (Test-Path "CLAUDE.md") {
    if ($DryRun) {
        Write-Host "  [DRY-RUN] Would update CLAUDE.md with project name and stack" -ForegroundColor Cyan
        $script:DryRunActions += "Update CLAUDE.md placeholders"
    } else {
        (Get-Content "CLAUDE.md") -replace '\[NOMBRE_PROYECTO\]', $ProjectName -replace '\[STACK\]', $Stack | Set-Content "CLAUDE.md"
    }
    Write-Host "  Done: CLAUDE.md actualizado" -ForegroundColor Green
} else {
    Write-Host "  Warning: CLAUDE.md no encontrado" -ForegroundColor Yellow
}

# Actualizar CONTEXT.md si existe
if (Test-Path ".project/Memory/CONTEXT.md") {
    $Today = Get-Date -Format "yyyy-MM-dd"
    if ($DryRun) {
        Write-Host "  [DRY-RUN] Would update CONTEXT.md with project name and date" -ForegroundColor Cyan
        $script:DryRunActions += "Update CONTEXT.md placeholders"
    } else {
        (Get-Content ".project/Memory/CONTEXT.md") -replace '\[NOMBRE_PROYECTO\]', $ProjectName -replace '\[FECHA\]', $Today | Set-Content ".project/Memory/CONTEXT.md"
    }
}

# =============================================================================
# Resumen
# =============================================================================
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   Setup Completado!                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proyecto: $ProjectName" -ForegroundColor Green
Write-Host "Stack: $Stack" -ForegroundColor Green
Write-Host ""
Write-Host "Hooks habilitados:" -ForegroundColor Green
Write-Host "  - pre-commit: AI attribution check + lint + security"
Write-Host "  - commit-msg: Valida mensaje sin AI attribution"
Write-Host "  - pre-push:   CI simulation en Docker"
Write-Host ""
if ((Test-Path ".github/dependabot.yml") -or ($DryRun -and $ciChoice -eq "1")) {
    Write-Host "Dependabot:" -ForegroundColor Green
    Write-Host "  - Updates semanales (lunes 9am)"
    Write-Host "  - Auto-merge de patches habilitado"
    Write-Host "  - Habilitar 'Allow auto-merge' en Settings > General"
    Write-Host ""
}
Write-Host "Comandos utiles:" -ForegroundColor Green
Write-Host "  .\.ci-local\ci-local.ps1 quick   # Check rapido"
Write-Host "  .\.ci-local\ci-local.ps1 full    # CI completo"
Write-Host "  .\.ci-local\ci-local.ps1 shell   # Shell en entorno CI"
Write-Host ""

# =============================================================================
# Dry-run summary
# =============================================================================
if ($DryRun) {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║               DRY-RUN SUMMARY                              ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The following $($script:DryRunActions.Count) action(s) would have been performed:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $script:DryRunActions.Count; $i++) {
        Write-Host "  $($i + 1). $($script:DryRunActions[$i])"
    }
    Write-Host ""
    Write-Host "Run without -DryRun to apply these changes." -ForegroundColor Yellow
    Write-Host ""
}
