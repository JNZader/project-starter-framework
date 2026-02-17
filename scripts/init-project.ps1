# =============================================================================
# INIT-PROJECT: Setup inicial para nuevo proyecto (Windows)
# =============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

# Helper: Backup a file before overwriting it
function Backup-IfExists {
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        Copy-Item $FilePath "${FilePath}.bak" -Force
        Write-Host "  Backed up existing ${FilePath}" -ForegroundColor Yellow
    }
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
"@ | Out-File -FilePath ".gitignore" -Encoding utf8
    Write-Host "  Done: .gitignore creado" -ForegroundColor Green
} else {
    Write-Host "  Done: .gitignore existente" -ForegroundColor Green
}

# =============================================================================
# 6. Módulos opcionales
# =============================================================================
Write-Host "[6/8] Módulos opcionales..." -ForegroundColor Yellow

$FrameworkDir = ""
# Detect if we're running from the framework repo (has templates/ and .ai-config/)
if ((Test-Path "templates") -and (Test-Path ".ai-config")) {
    $FrameworkDir = "."
} elseif ((Test-Path "../templates") -and (Test-Path "../.ai-config")) {
    $FrameworkDir = ".."
}

$HasOptional = $false
if ($FrameworkDir -ne "" -and (Test-Path "$FrameworkDir/optional")) {
    $HasOptional = $true
}

if ($FrameworkDir -ne "") {
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
        $choice = Read-Host "  Opcion [1/2/3/4/5]"

        switch ($choice) {
            "1" {
                if (Test-Path "$FrameworkDir/optional/obsidian-brain/.project") {
                    Copy-Item -Recurse "$FrameworkDir/optional/obsidian-brain/.project" "." -Force
                    Copy-Item -Recurse "$FrameworkDir/optional/obsidian-brain/.obsidian" "." -Force
                    if (Test-Path "$FrameworkDir/optional/obsidian-brain/new-wave.ps1") {
                        Backup-IfExists "scripts/new-wave.ps1"
                        Copy-Item "$FrameworkDir/optional/obsidian-brain/new-wave.ps1" "scripts/" -Force
                    }
                    if (Test-Path "$FrameworkDir/optional/obsidian-brain/new-wave.sh") {
                        Backup-IfExists "scripts/new-wave.sh"
                        Copy-Item "$FrameworkDir/optional/obsidian-brain/new-wave.sh" "scripts/" -Force
                    }
                    # Append gitignore snippet
                    $snippetPath = "$FrameworkDir/optional/obsidian-brain/.obsidian-gitignore-snippet.txt"
                    if (Test-Path $snippetPath) {
                        Add-Content -Path ".gitignore" -Value ""
                        Get-Content $snippetPath | Add-Content -Path ".gitignore"
                    }
                    Write-Host "  Done: Obsidian Brain instalado" -ForegroundColor Green
                    Write-Host "  Nota: Instala plugins Kanban, Dataview y Templater desde Obsidian" -ForegroundColor Cyan
                }
            }
            "2" {
                if (Test-Path "$FrameworkDir/optional/vibekanban/.project") {
                    Copy-Item -Recurse "$FrameworkDir/optional/vibekanban/.project" "." -Force
                    if (Test-Path "$FrameworkDir/optional/vibekanban/new-wave.ps1") {
                        Backup-IfExists "scripts/new-wave.ps1"
                        Copy-Item "$FrameworkDir/optional/vibekanban/new-wave.ps1" "scripts/" -Force
                    }
                    if (Test-Path "$FrameworkDir/optional/vibekanban/new-wave.sh") {
                        Backup-IfExists "scripts/new-wave.sh"
                        Copy-Item "$FrameworkDir/optional/vibekanban/new-wave.sh" "scripts/" -Force
                    }
                    Write-Host "  Done: VibeKanban instalado (legacy)" -ForegroundColor Green
                }
            }
            "3" {
                if (Test-Path "$FrameworkDir/optional/memory-simple/.project") {
                    Copy-Item -Recurse "$FrameworkDir/optional/memory-simple/.project" "." -Force
                    Write-Host "  Done: Memory simple instalado" -ForegroundColor Green
                }
            }
            "4" {
                if (Test-Path "$FrameworkDir/optional/engram") {
                    # Copy MCP config
                    $projectName = Split-Path -Leaf (Get-Location)
                    if (Test-Path "$FrameworkDir/optional/engram/.mcp-config-snippet.json") {
                        if (-not (Test-Path ".mcp.json")) {
                            $mcpContent = Get-Content "$FrameworkDir/optional/engram/.mcp-config-snippet.json" -Raw
                            $mcpContent = $mcpContent -replace '__PROJECT_NAME__', $projectName
                            $mcpContent | Out-File -FilePath ".mcp.json" -Encoding utf8
                        } else {
                            Write-Host "  .mcp.json ya existe - agrega engram manualmente" -ForegroundColor Yellow
                            Write-Host "  Ver: optional/engram/.mcp-config-snippet.json"
                        }
                    }
                    # Copy install scripts
                    Backup-IfExists "scripts/install-engram.sh"
                    if (Test-Path "$FrameworkDir/optional/engram/install-engram.sh") {
                        Copy-Item "$FrameworkDir/optional/engram/install-engram.sh" "scripts/" -Force
                    }
                    Backup-IfExists "scripts/install-engram.ps1"
                    if (Test-Path "$FrameworkDir/optional/engram/install-engram.ps1") {
                        Copy-Item "$FrameworkDir/optional/engram/install-engram.ps1" "scripts/" -Force
                    }
                    # Append gitignore snippet
                    $snippetPath = "$FrameworkDir/optional/engram/.gitignore-snippet.txt"
                    if (Test-Path $snippetPath) {
                        Add-Content -Path ".gitignore" -Value ""
                        Get-Content $snippetPath | Add-Content -Path ".gitignore"
                    }
                    Write-Host "  Done: Engram configurado" -ForegroundColor Green
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
            $addEngram = Read-Host "  Agregar tambien Engram para memoria de agentes AI? [y/N]"
            if ($addEngram -eq "y" -or $addEngram -eq "Y") {
                $projectName = Split-Path -Leaf (Get-Location)
                if (-not (Test-Path ".mcp.json")) {
                    $mcpContent = Get-Content "$FrameworkDir/optional/engram/.mcp-config-snippet.json" -Raw
                    $mcpContent = $mcpContent -replace '__PROJECT_NAME__', $projectName
                    $mcpContent | Out-File -FilePath ".mcp.json" -Encoding utf8
                }
                Backup-IfExists "scripts/install-engram.sh"
                if (Test-Path "$FrameworkDir/optional/engram/install-engram.sh") {
                    Copy-Item "$FrameworkDir/optional/engram/install-engram.sh" "scripts/" -Force
                }
                Backup-IfExists "scripts/install-engram.ps1"
                if (Test-Path "$FrameworkDir/optional/engram/install-engram.ps1") {
                    Copy-Item "$FrameworkDir/optional/engram/install-engram.ps1" "scripts/" -Force
                }
                $snippetPath = "$FrameworkDir/optional/engram/.gitignore-snippet.txt"
                if (Test-Path $snippetPath) {
                    Add-Content -Path ".gitignore" -Value ""
                    Get-Content $snippetPath | Add-Content -Path ".gitignore"
                }
                Write-Host "  Done: Engram agregado (complementa Obsidian Brain)" -ForegroundColor Green
                Write-Host "  Ejecuta: .\scripts\install-engram.ps1 para instalar el binario" -ForegroundColor Cyan
            }
        }
    } else {
        # Framework detected but optional/ dir not present - create basic memory structure
        Write-Host "  optional/ no disponible. Creando estructura basica de memoria..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path ".project/Memory" -Force | Out-Null
        @("CONTEXT.md", "DECISIONS.md", "BLOCKERS.md", "KANBAN.md") | ForEach-Object {
            $filePath = ".project/Memory/$_"
            if (-not (Test-Path $filePath)) {
                New-Item -ItemType File -Path $filePath -Force | Out-Null
            }
        }
        Write-Host "  Done: Estructura basica .project/Memory/ creada" -ForegroundColor Green
    }
} else {
    Write-Host "  Done: Modulos ya configurados o no disponibles" -ForegroundColor Green
}

# =============================================================================
# Helper: Generate dependabot.yml content based on detected stack
# =============================================================================
function Get-DependabotContent {
    param([string]$StackType)

    $content = @"
version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      # timezone: "UTC"  # Change to your timezone
    labels:
      - "dependencies"
      - "github-actions"
    commit-message:
      prefix: "chore(deps)"
    groups:
      actions:
        patterns:
          - "*"
"@

    switch ($StackType) {
        "java-gradle" {
            $content += @"

  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "java"
    commit-message:
      prefix: "chore(deps)"
    groups:
      java-dependencies:
        patterns:
          - "*"
"@
        }
        "java-maven" {
            $content += @"

  - package-ecosystem: "maven"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "java"
    commit-message:
      prefix: "chore(deps)"
    groups:
      maven-dependencies:
        patterns:
          - "*"
"@
        }
        "node" {
            $content += @"

  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "javascript"
    commit-message:
      prefix: "chore(deps)"
    groups:
      npm-dependencies:
        patterns:
          - "*"
        exclude-patterns:
          - "@types/*"
      npm-types:
        patterns:
          - "@types/*"
"@
        }
        "python" {
            $content += @"

  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "python"
    commit-message:
      prefix: "chore(deps)"
"@
        }
        "go" {
            $content += @"

  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "go"
    commit-message:
      prefix: "chore(deps)"
    groups:
      go-dependencies:
        patterns:
          - "*"
"@
        }
        "rust" {
            $content += @"

  - package-ecosystem: "cargo"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    labels:
      - "dependencies"
      - "rust"
    commit-message:
      prefix: "chore(deps)"
"@
        }
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
    $ciChoice = Read-Host "  Opcion [1/2/3/4]"

    switch ($ciChoice) {
        "1" {
            New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
            New-Item -ItemType Directory -Path ".github/ISSUE_TEMPLATE" -Force | Out-Null

            # CI workflow
            $src = "$FrameworkDir/templates/github/ci-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Backup-IfExists ".github/workflows/ci.yml"
                Copy-Item $src ".github/workflows/ci.yml" -Force
                Write-Host "  Done: GitHub Actions configurado (.github/workflows/ci.yml)" -ForegroundColor Green
            } else {
                Write-Host "  Warning: Template $src no encontrado" -ForegroundColor Yellow
            }

            # Dependabot auto-merge workflow
            $automerge = "$FrameworkDir/templates/github/dependabot-automerge.yml"
            if (Test-Path $automerge) {
                Backup-IfExists ".github/workflows/dependabot-automerge.yml"
                Copy-Item $automerge ".github/workflows/dependabot-automerge.yml" -Force
                Write-Host "  Done: Dependabot auto-merge configurado" -ForegroundColor Green
            }

            # Generate dependabot.yml with detected stack
            Backup-IfExists ".github/dependabot.yml"
            $dependabotContent = Get-DependabotContent -StackType $Stack
            $dependabotContent | Out-File -FilePath ".github/dependabot.yml" -Encoding utf8
            Write-Host "  Done: Dependabot configurado (.github/dependabot.yml)" -ForegroundColor Green

            # Issue and PR templates
            $issueTemplateDir = "$FrameworkDir/.github/ISSUE_TEMPLATE"
            if (Test-Path $issueTemplateDir) {
                Get-ChildItem "$issueTemplateDir/*.md" -ErrorAction SilentlyContinue | ForEach-Object {
                    Copy-Item $_.FullName ".github/ISSUE_TEMPLATE/" -Force
                }
                Write-Host "  Done: Issue templates copiados" -ForegroundColor Green
            }
            $prTemplate = "$FrameworkDir/.github/PULL_REQUEST_TEMPLATE.md"
            if (Test-Path $prTemplate) {
                Backup-IfExists ".github/PULL_REQUEST_TEMPLATE.md"
                Copy-Item $prTemplate ".github/PULL_REQUEST_TEMPLATE.md" -Force
                Write-Host "  Done: PR template copiado" -ForegroundColor Green
            }

            # GHAGGA AI Code Review (optional)
            if (Test-Path "$FrameworkDir/optional/ghagga") {
                Write-Host ""
                $addGhagga = Read-Host "  Agregar AI code review con GHAGGA? [y/N]"
                if ($addGhagga -eq "y" -or $addGhagga -eq "Y") {
                    $reusableGhagga = "$FrameworkDir/.github/workflows/reusable-ghagga-review.yml"
                    if (Test-Path $reusableGhagga) {
                        Copy-Item $reusableGhagga ".github/workflows/" -Force
                    }
                    # Create GHAGGA workflow
                    @"
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
"@ | Out-File -FilePath ".github/workflows/ghagga-review.yml" -Encoding utf8
                    Write-Host "  Done: GHAGGA AI review configurado" -ForegroundColor Green
                    Write-Host "  Configura GHAGGA_URL (variable) y GHAGGA_TOKEN (secret) en repo settings" -ForegroundColor Cyan
                }
            }
        }
        "2" {
            $src = "$FrameworkDir/templates/gitlab/gitlab-ci-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Backup-IfExists ".gitlab-ci.yml"
                Copy-Item $src ".gitlab-ci.yml" -Force
                Write-Host "  Done: GitLab CI configurado (.gitlab-ci.yml)" -ForegroundColor Green
            } else {
                Write-Host "  Warning: Template $src no encontrado" -ForegroundColor Yellow
            }
        }
        "3" {
            $src = "$FrameworkDir/templates/woodpecker/woodpecker-${TemplateSuffix}.yml"
            if (Test-Path $src) {
                Backup-IfExists ".woodpecker.yml"
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
if (Test-Path ".github/dependabot.yml") {
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
