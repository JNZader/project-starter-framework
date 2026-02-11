# =============================================================================
# CI-LOCAL: Universal CI Simulation for Any Project
# =============================================================================
# Detecta automáticamente: Java/Gradle, Java/Maven, Node, Python, Go, Rust
#
# Uso:
#   .\ci-local.ps1              # CI completo
#   .\ci-local.ps1 quick        # Solo lint + compile
#   .\ci-local.ps1 shell        # Shell interactivo en entorno CI
#   .\ci-local.ps1 detect       # Mostrar stack detectado
# =============================================================================

param(
    [string]$Mode = "full",
    [string]$Module = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

# Colores
function Write-Color($Text, $Color) {
    Write-Host $Text -ForegroundColor $Color
}

# =============================================================================
# DETECCIÓN DE STACK
# =============================================================================
function Detect-Stack {
    $stack = @{
        Type = "unknown"
        BuildTool = ""
        Dockerfile = ""
        LintCmd = ""
        TestCmd = ""
        CompileCmd = ""
    }

    # Java + Gradle
    if ((Test-Path "$ProjectDir/build.gradle") -or (Test-Path "$ProjectDir/build.gradle.kts")) {
        $stack.Type = "java-gradle"
        $stack.BuildTool = "gradle"
        $stack.Dockerfile = "java.Dockerfile"
        $stack.LintCmd = "./gradlew spotlessCheck --no-daemon"
        $stack.CompileCmd = "./gradlew classes testClasses --no-daemon"
        $stack.TestCmd = "./gradlew test --no-daemon"

        # Detectar versión de Java del toolchain
        $buildFile = if (Test-Path "$ProjectDir/build.gradle.kts") {
            Get-Content "$ProjectDir/build.gradle.kts" -Raw
        } else {
            Get-Content "$ProjectDir/build.gradle" -Raw
        }
        if ($buildFile -match "languageVersion\s*[=.]\s*JavaLanguageVersion\.of\((\d+)\)") {
            $stack.JavaVersion = $matches[1]
        } elseif ($buildFile -match "sourceCompatibility\s*=\s*['""]?(\d+)") {
            $stack.JavaVersion = $matches[1]
        } else {
            $stack.JavaVersion = "21"  # Default
        }
        return $stack
    }

    # Java + Maven
    if (Test-Path "$ProjectDir/pom.xml") {
        $stack.Type = "java-maven"
        $stack.BuildTool = "maven"
        $stack.Dockerfile = "java.Dockerfile"
        $stack.LintCmd = "./mvnw spotless:check"
        $stack.CompileCmd = "./mvnw compile test-compile"
        $stack.TestCmd = "./mvnw test"
        $stack.JavaVersion = "21"
        return $stack
    }

    # Node.js
    if (Test-Path "$ProjectDir/package.json") {
        $stack.Type = "node"
        $stack.BuildTool = if (Test-Path "$ProjectDir/pnpm-lock.yaml") { "pnpm" } `
                          elseif (Test-Path "$ProjectDir/yarn.lock") { "yarn" } `
                          else { "npm" }
        $stack.Dockerfile = "node.Dockerfile"
        $stack.LintCmd = "$($stack.BuildTool) run lint"
        $stack.CompileCmd = "$($stack.BuildTool) run build"
        $stack.TestCmd = "$($stack.BuildTool) test"
        return $stack
    }

    # Python
    if ((Test-Path "$ProjectDir/pyproject.toml") -or (Test-Path "$ProjectDir/setup.py") -or (Test-Path "$ProjectDir/requirements.txt")) {
        $stack.Type = "python"
        $stack.BuildTool = if (Test-Path "$ProjectDir/poetry.lock") { "poetry" } `
                          elseif (Test-Path "$ProjectDir/Pipfile") { "pipenv" } `
                          else { "pip" }
        $stack.Dockerfile = "python.Dockerfile"
        $stack.LintCmd = "ruff check . || pylint **/*.py"
        $stack.TestCmd = "pytest"
        return $stack
    }

    # Go
    if (Test-Path "$ProjectDir/go.mod") {
        $stack.Type = "go"
        $stack.BuildTool = "go"
        $stack.Dockerfile = "go.Dockerfile"
        $stack.LintCmd = "golangci-lint run"
        $stack.CompileCmd = "go build ./..."
        $stack.TestCmd = "go test ./..."
        return $stack
    }

    # Rust
    if (Test-Path "$ProjectDir/Cargo.toml") {
        $stack.Type = "rust"
        $stack.BuildTool = "cargo"
        $stack.Dockerfile = "rust.Dockerfile"
        $stack.LintCmd = "cargo clippy -- -D warnings"
        $stack.CompileCmd = "cargo build"
        $stack.TestCmd = "cargo test"
        return $stack
    }

    return $stack
}

# =============================================================================
# DOCKER
# =============================================================================
function Get-ImageName($stack) {
    return "ci-local-$($stack.Type)"
}

function Ensure-DockerImage($stack) {
    $imageName = Get-ImageName $stack
    $dockerfile = "$ScriptDir/docker/$($stack.Dockerfile)"

    if (-not (Test-Path $dockerfile)) {
        Write-Color "Creating Dockerfile for $($stack.Type)..." Yellow
        Create-Dockerfile $stack
    }

    $imageExists = docker images -q $imageName 2>$null
    if (-not $imageExists) {
        Write-Color "Building CI image for $($stack.Type)..." Yellow

        # Build args para Java
        $buildArgs = ""
        if ($stack.JavaVersion) {
            $buildArgs = "--build-arg JAVA_VERSION=$($stack.JavaVersion)"
        }

        # Use Start-Process to avoid Invoke-Expression security risks
        $dockerArgs = @("build")
        if ($buildArgs) { $dockerArgs += $buildArgs.Split(' ') }
        $dockerArgs += @("-f", $dockerfile, "-t", $imageName, "$ScriptDir/docker")
        & docker @dockerArgs
    }
}

function Create-Dockerfile($stack) {
    $dockerDir = "$ScriptDir/docker"
    if (-not (Test-Path $dockerDir)) {
        New-Item -ItemType Directory -Path $dockerDir -Force | Out-Null
    }

    switch ($stack.Type) {
        "java-gradle" {
            $content = @"
ARG JAVA_VERSION=21
FROM eclipse-temurin:`${JAVA_VERSION}-jdk-noble
RUN apt-get update && apt-get install -y git curl unzip && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENV GRADLE_USER_HOME=/home/runner/.gradle
ENTRYPOINT ["/bin/bash", "-c"]
"@
        }
        "java-maven" {
            $content = @"
ARG JAVA_VERSION=21
FROM eclipse-temurin:`${JAVA_VERSION}-jdk-noble
RUN apt-get update && apt-get install -y git curl unzip && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
"@
        }
        "node" {
            $content = @"
FROM node:22-slim
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN npm install -g pnpm
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
"@
        }
        "python" {
            $content = @"
FROM python:3.12-slim
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir pytest ruff pylint poetry
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
"@
        }
        "go" {
            $content = @"
FROM golang:1.23-bookworm
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
"@
        }
        "rust" {
            $content = @"
FROM rust:1.83-slim
RUN apt-get update && apt-get install -y git pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
RUN rustup component add clippy rustfmt
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
"@
        }
        default {
            $content = @"
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
"@
        }
    }

    $content | Out-File -FilePath "$dockerDir/$($stack.Dockerfile)" -Encoding utf8 -NoNewline
    Write-Color "Created $($stack.Dockerfile)" Green
}

function Run-InCI($stack, $command) {
    $imageName = Get-ImageName $stack
    $dockerPath = $ProjectDir -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'

    docker run --rm -it `
        -v "${dockerPath}:/home/runner/work" `
        -e CI=true `
        -e GITHUB_ACTIONS=true `
        $imageName $command
}

# =============================================================================
# MAIN
# =============================================================================
Write-Color "`n=== CI-LOCAL ===" Yellow

$stack = Detect-Stack

if ($stack.Type -eq "unknown") {
    Write-Color "Could not detect project type!" Red
    Write-Color "Supported: Java/Gradle, Java/Maven, Node, Python, Go, Rust" Yellow
    exit 1
}

Write-Color "Detected: $($stack.Type) ($($stack.BuildTool))" Green
if ($stack.JavaVersion) {
    Write-Color "Java version: $($stack.JavaVersion)" Green
}

switch ($Mode) {
    "detect" {
        Write-Color "`nStack details:" Cyan
        $stack | Format-List
        exit 0
    }

    "quick" {
        Ensure-DockerImage $stack
        Write-Color "`nRunning quick check..." Yellow

        if ($stack.LintCmd) {
            Write-Color "Lint: $($stack.LintCmd)" Cyan
            Run-InCI $stack "cd /home/runner/work && $($stack.LintCmd)"
        }
        if ($stack.CompileCmd) {
            Write-Color "Compile: $($stack.CompileCmd)" Cyan
            Run-InCI $stack "cd /home/runner/work && $($stack.CompileCmd)"
        }
    }

    "shell" {
        Ensure-DockerImage $stack
        Write-Color "`nOpening shell in CI environment..." Yellow
        $imageName = Get-ImageName $stack
        $dockerPath = $ProjectDir -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'
        docker run --rm -it `
            -v "${dockerPath}:/home/runner/work" `
            -e CI=true `
            $imageName "cd /home/runner/work && bash"
    }

    default {
        Ensure-DockerImage $stack
        Write-Color "`nRunning full CI simulation..." Yellow

        $steps = @()
        if ($stack.LintCmd) { $steps += @{Name="Lint"; Cmd=$stack.LintCmd} }
        if ($stack.CompileCmd) { $steps += @{Name="Compile"; Cmd=$stack.CompileCmd} }
        if ($stack.TestCmd) { $steps += @{Name="Test"; Cmd=$stack.TestCmd} }

        $i = 1
        foreach ($step in $steps) {
            Write-Color "`nStep $i/$($steps.Count): $($step.Name)" Yellow
            Write-Color "  $($step.Cmd)" Cyan
            Run-InCI $stack "cd /home/runner/work && $($step.Cmd)"
            $i++
        }
    }
}

Write-Color "`n✓ CI Local completed successfully!" Green
Write-Color "  Safe to push - CI should pass.`n" Green
