# =============================================================================
# INIT-PROJECT: Setup inicial para nuevo proyecto (Windows)
# =============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           PROJECT STARTER FRAMEWORK                        ║" -ForegroundColor Cyan
Write-Host "║                  Init Project                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Set-Location $ProjectDir

# =============================================================================
# 1. Verificar repo git
# =============================================================================
Write-Host "[1/6] Verificando repositorio Git..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    Write-Host "  No es un repo git. Inicializando..." -ForegroundColor Yellow
    git init
    git checkout -b main
    git checkout -b develop
    Write-Host "  Done: Repo inicializado" -ForegroundColor Green
} else {
    Write-Host "  Done: Repo git existente" -ForegroundColor Green
}

# =============================================================================
# 2. Configurar git hooks
# =============================================================================
Write-Host "[2/6] Configurando git hooks..." -ForegroundColor Yellow
git config core.hooksPath .ci-local/hooks
Write-Host "  Done: Hooks configurados" -ForegroundColor Green

# =============================================================================
# 3. Detectar stack
# =============================================================================
Write-Host "[3/6] Detectando stack tecnológico..." -ForegroundColor Yellow

$Stack = "unknown"
if (Test-Path "build.gradle" -or Test-Path "build.gradle.kts") {
    $Stack = "java-gradle"
} elseif (Test-Path "pom.xml") {
    $Stack = "java-maven"
} elseif (Test-Path "go.mod") {
    $Stack = "go"
} elseif (Test-Path "Cargo.toml") {
    $Stack = "rust"
} elseif (Test-Path "package.json") {
    $Stack = "node"
} elseif (Test-Path "pyproject.toml" -or Test-Path "requirements.txt") {
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
Write-Host "[4/6] Verificando dependencias..." -ForegroundColor Yellow

try {
    $null = docker info 2>$null
    Write-Host "  Done: Docker disponible" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Docker no disponible" -ForegroundColor Yellow
}

if (Get-Command semgrep -ErrorAction SilentlyContinue) {
    Write-Host "  Done: Semgrep instalado" -ForegroundColor Green
} else {
    Write-Host "  Warning: Semgrep no instalado (pip install semgrep)" -ForegroundColor Yellow
}

# =============================================================================
# 5. Crear .gitignore si no existe
# =============================================================================
Write-Host "[5/6] Verificando .gitignore..." -ForegroundColor Yellow
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
"@ | Out-File -FilePath ".gitignore" -Encoding utf8
    Write-Host "  Done: .gitignore creado" -ForegroundColor Green
} else {
    Write-Host "  Done: .gitignore existente" -ForegroundColor Green
}

# =============================================================================
# 6. Preparar memoria
# =============================================================================
Write-Host "[6/6] Preparando memoria del proyecto..." -ForegroundColor Yellow

$ProjectName = Split-Path -Leaf $ProjectDir
$Today = Get-Date -Format "yyyy-MM-dd"

$contextFile = ".project/Memory/CONTEXT.md"
if (Test-Path $contextFile) {
    (Get-Content $contextFile) -replace '\[NOMBRE_PROYECTO\]', $ProjectName -replace '\[FECHA\]', $Today | Set-Content $contextFile
}
Write-Host "  Done: Memoria preparada" -ForegroundColor Green

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
Write-Host "  .\scripts\new-wave.ps1           # Crear oleada"
Write-Host ""
