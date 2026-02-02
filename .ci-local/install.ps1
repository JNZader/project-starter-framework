# =============================================================================
# CI-LOCAL: Installation Script (Windows)
# =============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Write-Host "=== CI-LOCAL Installation ===" -ForegroundColor Cyan

Set-Location $ProjectDir

# 1. Configurar git hooks
Write-Host "[1/2] Configuring git hooks..." -ForegroundColor Yellow
git config core.hooksPath .ci-local/hooks
Write-Host "Done" -ForegroundColor Green

# 2. Verificar dependencias
Write-Host "[2/2] Checking dependencies..." -ForegroundColor Yellow

try {
    $null = docker info 2>$null
    Write-Host "Docker: available" -ForegroundColor Green
} catch {
    Write-Host "Docker: not running (required for pre-push CI)" -ForegroundColor Yellow
}

if (Get-Command semgrep -ErrorAction SilentlyContinue) {
    Write-Host "Semgrep: installed" -ForegroundColor Green
} else {
    Write-Host "Semgrep: not installed (pip install semgrep)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Hooks enabled:"
Write-Host "  - pre-commit: AI check + lint + security"
Write-Host "  - commit-msg: Block AI attribution"
Write-Host "  - pre-push:   CI simulation in Docker"
Write-Host ""
