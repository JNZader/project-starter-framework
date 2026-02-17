# =============================================================================
# CI-LOCAL: Universal CI Simulation for Any Project
# =============================================================================
# Detecta automaticamente: Java/Gradle, Java/Maven, Node, Python, Go, Rust
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

Import-Module "$ScriptDir/../lib/Common.psm1" -Force

# Colores
function Write-Color($Text, $Color) {
    Write-Host $Text -ForegroundColor $Color
}

# =============================================================================
# CI STACK DETECTION (extends shared Detect-Stack with CI-specific commands)
# =============================================================================
function Detect-CIStack {
    $baseStack = Detect-Stack -ProjectPath $ProjectDir

    $stack = @{
        Type       = $baseStack.StackType
        BuildTool  = $baseStack.BuildTool
        JavaVersion = $baseStack.JavaVersion
        Dockerfile = ""
        LintCmd    = ""
        TestCmd    = ""
        CompileCmd = ""
    }

    switch ($stack.Type) {
        "java-gradle" {
            $stack.Dockerfile = "java.Dockerfile"
            $stack.LintCmd = "./gradlew spotlessCheck --no-daemon"
            $stack.CompileCmd = "./gradlew classes testClasses --no-daemon"
            $stack.TestCmd = "./gradlew test --no-daemon"
        }
        "java-maven" {
            $stack.Dockerfile = "java.Dockerfile"
            $stack.LintCmd = "./mvnw spotless:check"
            $stack.CompileCmd = "./mvnw compile test-compile"
            $stack.TestCmd = "./mvnw test"
        }
        "node" {
            $stack.Dockerfile = "node.Dockerfile"
            $stack.LintCmd = "$($stack.BuildTool) run lint"
            $stack.CompileCmd = "$($stack.BuildTool) run build"
            $stack.TestCmd = "$($stack.BuildTool) test"
        }
        "python" {
            $stack.Dockerfile = "python.Dockerfile"
            $stack.LintCmd = "ruff check . || pylint **/*.py"
            $stack.TestCmd = "pytest"
        }
        "go" {
            $stack.Dockerfile = "go.Dockerfile"
            $stack.LintCmd = "golangci-lint run"
            $stack.CompileCmd = "go build ./..."
            $stack.TestCmd = "go test ./..."
        }
        "rust" {
            $stack.Dockerfile = "rust.Dockerfile"
            $stack.LintCmd = "cargo clippy -- -D warnings"
            $stack.CompileCmd = "cargo build"
            $stack.TestCmd = "cargo test"
        }
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

    # Detect staleness: rebuild if the Dockerfile content has changed since last build
    $currentHash = (Get-FileHash $dockerfile -Algorithm SHA256).Hash
    $imageHash = docker inspect --format='{{index .Config.Labels "dockerfile-hash"}}' $imageName 2>$null
    if ($LASTEXITCODE -ne 0) { $imageHash = "" }

    if ($currentHash -ne $imageHash) {
        Write-Color "Image stale or missing, rebuilding for $($stack.Type)..." Yellow

        $dockerArgs = @("build", "--label", "dockerfile-hash=$currentHash")
        if ($stack.JavaVersion) {
            $dockerArgs += @("--build-arg", "JAVA_VERSION=$($stack.JavaVersion)")
        }
        $dockerArgs += @("-f", $dockerfile, "-t", $imageName, "$ScriptDir/docker")
        & docker @dockerArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed"
        }
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
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.62.0 && \
    mv /root/go/bin/golangci-lint /usr/local/bin/
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
    $dockerPath = $ProjectDir -replace '\\', '/'
    if ($dockerPath -match '^([A-Za-z]):') {
        $dockerPath = '/' + $matches[1].ToLower() + $dockerPath.Substring(2)
    }

    docker run --rm -it `
        -v "${dockerPath}:/home/runner/work" `
        -e CI=true `
        $imageName $command
}

# =============================================================================
# MAIN
# =============================================================================
Write-Color "`n=== CI-LOCAL ===" Yellow

$stack = Detect-CIStack

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
        $dockerPath = $ProjectDir -replace '\\', '/'
        if ($dockerPath -match '^([A-Za-z]):') {
            $dockerPath = '/' + $matches[1].ToLower() + $dockerPath.Substring(2)
        }
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

Write-Color "`nCI Local completed successfully!" Green
Write-Color "  Safe to push - CI should pass.`n" Green
