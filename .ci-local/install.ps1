# =============================================================================
# CI-LOCAL: Installation Script (Windows)
# =============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

# Import shared library
Import-Module "$ScriptDir\..\lib\Common.psm1" -Force

Write-Host "=== CI-LOCAL Installation ===" -ForegroundColor Cyan

Set-Location $ProjectDir

# 1. Configurar git hooks
Write-Host "[1/2] Configuring git hooks..." -ForegroundColor Yellow
git config core.hooksPath .ci-local/hooks
Write-Host "Done" -ForegroundColor Green

# 2. Verificar dependencias
Write-Host "[2/2] Checking dependencies..." -ForegroundColor Yellow

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerCmd) {
    $null = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker: available" -ForegroundColor Green
    } else {
        Write-Host "Docker: not running (required for pre-push CI)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Docker: not running (required for pre-push CI)" -ForegroundColor Yellow
}

if (Get-Command semgrep -ErrorAction SilentlyContinue) {
    Write-Host "Semgrep: installed (native)" -ForegroundColor Green
} elseif ($dockerCmd) {
    $null = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Semgrep: available via Docker (returntocorp/semgrep)" -ForegroundColor Green
    } else {
        Write-Host "Semgrep: not available (install semgrep or Docker)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Semgrep: not available (install semgrep or Docker)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Hooks enabled:"
Write-Host "  - pre-commit: AI check + lint + security"
Write-Host "  - commit-msg: Block AI attribution"
Write-Host "  - pre-push:   CI simulation in Docker"
Write-Host ""
