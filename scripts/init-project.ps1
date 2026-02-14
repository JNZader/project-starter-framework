# =============================================================================
# INIT-PROJECT: Setup inicial para nuevo proyecto (Windows)
# =============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

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
    git init
    git checkout -b main
    Write-Host "  Done: Repo inicializado con branch main" -ForegroundColor Green
} else {
    Write-Host "  Done: Repo git existente" -ForegroundColor Green
}

# =============================================================================
# 2. Configurar git hooks
# =============================================================================
Write-Host "[2/8] Configurando git hooks..." -ForegroundColor Yellow
if (Test-Path ".ci-local/hooks") {
    git config core.hooksPath .ci-local/hooks
    Write-Host "  Done: Hooks configurados" -ForegroundColor Green
} else {
    Write-Host "  Warning: .ci-local/hooks no encontrado" -ForegroundColor Yellow
}

# =============================================================================
# 3. Detectar stack
# =============================================================================
Write-Host "[3/8] Detectando stack tecnológico..." -ForegroundColor Yellow

$Stack = "unknown"
if ((Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) {
    $Stack = "java-gradle"
} elseif (Test-Path "pom.xml") {
    $Stack = "java-maven"
} elseif (Test-Path "go.mod") {
    $Stack = "go"
} elseif (Test-Path "Cargo.toml") {
    $Stack = "rust"
} elseif (Test-Path "package.json") {
    $Stack = "node"
} elseif ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt")) {
    $Stack = "python"
}

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
    @"
# CI Local
.ci-local/docker/
.ci-local-image-built
semgrep-report.json

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
*.env

# Build
*.log
coverage/
dist/
build/
target/
node_modules/
__pycache__/
.pytest_cache/

# Claude Code
CLAUDE.md
"@ | Out-File -FilePath ".gitignore" -Encoding utf8
    Write-Host "  Done: .gitignore creado" -ForegroundColor Green
} else {
    Write-Host "  Done: .gitignore existente" -ForegroundColor Green
}

# =============================================================================
# 6. Módulos opcionales
# =============================================================================
Write-Host "[6/8] Módulos opcionales..." -ForegroundColor Yellow

if ((Test-Path "optional/obsidian-brain") -or (Test-Path "optional/vibekanban")) {
    Write-Host "  ¿Instalar módulo de memoria del proyecto?" -ForegroundColor Cyan
    Write-Host "    1) obsidian-brain  - Vault Obsidian + Kanban + memoria estructurada (RECOMENDADO)"
    Write-Host "    2) vibekanban      - Oleadas paralelas + memoria (legacy)"
    Write-Host "    3) simple          - Solo un archivo NOTES.md"
    Write-Host "    4) ninguno         - Sin memoria de proyecto"
    Write-Host ""
    $choice = Read-Host "  Opción [1/2/3/4]"

    switch ($choice) {
        "1" {
            if (Test-Path "optional/obsidian-brain/.project") {
                Copy-Item -Recurse "optional/obsidian-brain/.project" "." -Force
                Copy-Item -Recurse "optional/obsidian-brain/.obsidian" "." -Force
                if (Test-Path "optional/obsidian-brain/new-wave.ps1") {
                    Copy-Item "optional/obsidian-brain/new-wave.ps1" "scripts/" -Force
                }
                if (Test-Path "optional/obsidian-brain/new-wave.sh") {
                    Copy-Item "optional/obsidian-brain/new-wave.sh" "scripts/" -Force
                }
                # Append gitignore snippet
                $snippetPath = "optional/obsidian-brain/.obsidian-gitignore-snippet.txt"
                if (Test-Path $snippetPath) {
                    Add-Content -Path ".gitignore" -Value ""
                    Get-Content $snippetPath | Add-Content -Path ".gitignore"
                }
                Write-Host "  Done: Obsidian Brain instalado" -ForegroundColor Green
                Write-Host "  Nota: Instala plugins Kanban, Dataview y Templater desde Obsidian" -ForegroundColor Cyan
            }
        }
        "2" {
            if (Test-Path "optional/vibekanban/.project") {
                Copy-Item -Recurse "optional/vibekanban/.project" "." -Force
                if (Test-Path "optional/vibekanban/new-wave.ps1") {
                    Copy-Item "optional/vibekanban/new-wave.ps1" "scripts/" -Force
                }
                if (Test-Path "optional/vibekanban/new-wave.sh") {
                    Copy-Item "optional/vibekanban/new-wave.sh" "scripts/" -Force
                }
                Write-Host "  Done: VibeKanban instalado (legacy)" -ForegroundColor Green
            }
        }
        "3" {
            if (Test-Path "optional/memory-simple/.project") {
                Copy-Item -Recurse "optional/memory-simple/.project" "." -Force
                Write-Host "  Done: Memory simple instalado" -ForegroundColor Green
            }
        }
        default {
            Write-Host "  Done: Sin módulo de memoria" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  Done: Módulos ya configurados o no disponibles" -ForegroundColor Green
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

if (((Test-Path "optional/obsidian-brain") -or (Test-Path "optional/vibekanban")) -and $TemplateSuffix -ne "") {
    Write-Host "  ¿Qué CI remoto usar?" -ForegroundColor Cyan
    Write-Host "    1) GitHub Actions"
    Write-Host "    2) GitLab CI"
    Write-Host "    3) Woodpecker CI"
    Write-Host "    4) Solo CI-Local (sin CI remoto)"
    Write-Host ""
    $ciChoice = Read-Host "  Opción [1/2/3/4]"

    switch ($ciChoice) {
        "1" {
            New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
            $src = "templates/github/ci-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Copy-Item $src ".github/workflows/ci.yml" -Force
                Write-Host "  Done: GitHub Actions configurado (.github/workflows/ci.yml)" -ForegroundColor Green
            } else {
                Write-Host "  Warning: Template $src no encontrado" -ForegroundColor Yellow
            }
        }
        "2" {
            $src = "templates/gitlab/gitlab-ci-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Copy-Item $src ".gitlab-ci.yml" -Force
                Write-Host "  Done: GitLab CI configurado (.gitlab-ci.yml)" -ForegroundColor Green
            } else {
                Write-Host "  Warning: Template $src no encontrado" -ForegroundColor Yellow
            }
        }
        "3" {
            $src = "templates/woodpecker/woodpecker-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Copy-Item $src ".woodpecker.yml" -Force
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
    (Get-Content "CLAUDE.md") -replace '\[NOMBRE_PROYECTO\]', $ProjectName -replace '\[STACK\]', $Stack | Set-Content "CLAUDE.md"
    Write-Host "  Done: CLAUDE.md actualizado" -ForegroundColor Green
} else {
    Write-Host "  Warning: CLAUDE.md no encontrado" -ForegroundColor Yellow
}

# Actualizar CONTEXT.md si existe
if (Test-Path ".project/Memory/CONTEXT.md") {
    $Today = Get-Date -Format "yyyy-MM-dd"
    (Get-Content ".project/Memory/CONTEXT.md") -replace '\[NOMBRE_PROYECTO\]', $ProjectName -replace '\[FECHA\]', $Today | Set-Content ".project/Memory/CONTEXT.md"
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
Write-Host "Comandos útiles:" -ForegroundColor Green
Write-Host "  .\.ci-local\ci-local.ps1 quick   # Check rápido"
Write-Host "  .\.ci-local\ci-local.ps1 full    # CI completo"
Write-Host "  .\.ci-local\ci-local.ps1 shell   # Shell en entorno CI"
Write-Host ""
