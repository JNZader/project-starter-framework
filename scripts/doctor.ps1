# =============================================================================
# doctor.ps1 - Diagnostic tool for project-starter-framework (Windows)
# =============================================================================
# Checks environment, framework integrity, and project configuration.
# Complements validate-framework.sh (which checks content/consistency).
# This script checks runtime environment and operational readiness.
# =============================================================================
# Usage: .\scripts\doctor.ps1 [-Help]
# =============================================================================

param(
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FrameworkDir = Split-Path -Parent $ScriptDir

Import-Module "$ScriptDir/../lib/Common.psm1" -Force

Set-Location $FrameworkDir

# =============================================================================
# Help
# =============================================================================
if ($Help) {
    Write-Host "Usage: .\scripts\doctor.ps1 [-Help]"
    Write-Host ""
    Write-Host "Diagnostic tool for project-starter-framework."
    Write-Host "Checks environment dependencies, framework file integrity,"
    Write-Host "and project-level configuration."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help    Show this help message"
    Write-Host ""
    Write-Host "Exit codes:"
    Write-Host "  0    All checks passed (warnings are acceptable)"
    Write-Host "  1    One or more checks failed"
    exit 0
}

# =============================================================================
# Counters
# =============================================================================
$script:PassCount = 0
$script:WarnCount = 0
$script:FailCount = 0

function Check-Ok {
    param([string]$Message)
    Write-Host "  [OK]   $Message" -ForegroundColor Green
    $script:PassCount++
}

function Check-Warn {
    param([string]$Message)
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
    $script:WarnCount++
}

function Check-Fail {
    param([string]$Message)
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
    $script:FailCount++
}

function Check-Info {
    param([string]$Message)
    Write-Host "  [INFO] $Message" -ForegroundColor Cyan
}

# =============================================================================
# Header
# =============================================================================
Write-Host ""
Write-Host "+==========================================================+" -ForegroundColor Cyan
Write-Host "|                   Framework Doctor                        |" -ForegroundColor Cyan
Write-Host "+==========================================================+" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# 1. Environment Checks
# =============================================================================
Write-Host "--- Environment ---" -ForegroundColor Cyan

# Git
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    $gitVersion = (git --version 2>$null) | Select-Object -First 1
    Check-Ok "Git installed ($gitVersion)"
} else {
    Check-Fail "Git not installed"
}

# Docker
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerCmd) {
    $dockerVersion = (docker --version 2>$null) | Select-Object -First 1
    Check-Ok "Docker installed ($dockerVersion)"

    # Docker daemon running
    try {
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Check-Ok "Docker daemon is running"
        } else {
            Check-Warn "Docker daemon is not running (needed for ci-local full)"
        }
    } catch {
        Check-Warn "Docker daemon is not running (needed for ci-local full)"
    }
} else {
    Check-Warn "Docker not installed (needed for ci-local full)"
}

# Semgrep (native or Docker fallback)
$semgrepCmd = Get-Command semgrep -ErrorAction SilentlyContinue
if ($semgrepCmd) {
    $semgrepVersion = (semgrep --version 2>$null) | Select-Object -First 1
    Check-Ok "Semgrep installed natively ($semgrepVersion)"
} elseif ($dockerCmd -and ((docker info 2>$null) -ne $null)) {
    Check-Ok "Semgrep available via Docker (returntocorp/semgrep)"
} else {
    Check-Warn "Semgrep not available (install semgrep or Docker)"
}

# Node.js / npm (optional, info only)
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVersion = (node --version 2>$null)
    Check-Info "Node.js installed ($nodeVersion)"
} else {
    Check-Info "Node.js not installed"
}

$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCmd) {
    $npmVersion = (npm --version 2>$null)
    Check-Info "npm installed (v$npmVersion)"
} else {
    Check-Info "npm not installed"
}

# Python (optional, info only)
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    $pythonVersion = (python --version 2>$null)
    Check-Info "Python installed ($pythonVersion)"
} else {
    $python3Cmd = Get-Command python3 -ErrorAction SilentlyContinue
    if ($python3Cmd) {
        $pythonVersion = (python3 --version 2>$null)
        Check-Info "Python installed ($pythonVersion)"
    } else {
        Check-Info "Python not installed"
    }
}

Write-Host ""

# =============================================================================
# 2. Framework Integrity Checks
# =============================================================================
Write-Host "--- Framework Integrity ---" -ForegroundColor Cyan

# lib/common.sh
if (Test-Path "lib/common.sh") {
    Check-Ok "lib/common.sh exists"
} else {
    Check-Fail "lib/common.sh missing"
}

# .ci-local/ci-local.sh
if (Test-Path ".ci-local/ci-local.sh") {
    Check-Ok ".ci-local/ci-local.sh exists"
} else {
    Check-Fail ".ci-local/ci-local.sh missing"
}

# Hooks
foreach ($hook in @("pre-commit", "commit-msg", "pre-push")) {
    if (Test-Path ".ci-local/hooks/$hook") {
        Check-Ok ".ci-local/hooks/$hook exists"
    } else {
        Check-Fail ".ci-local/hooks/$hook missing"
    }
}

# semgrep.yml
if (Test-Path ".ci-local/semgrep.yml") {
    Check-Ok ".ci-local/semgrep.yml exists"
} else {
    Check-Fail ".ci-local/semgrep.yml missing"
}

# .framework-version
if (Test-Path ".framework-version") {
    $fwVersion = (Get-Content ".framework-version" -Raw).Trim()
    Check-Ok ".framework-version exists (v$fwVersion)"
} else {
    Check-Fail ".framework-version missing"
}

Write-Host ""

# =============================================================================
# 3. Project Checks (only when running OUTSIDE the framework repo)
# =============================================================================
# Detect if we are inside the framework itself: framework has templates/ + .ai-config/
$isFramework = (Test-Path "templates") -and (Test-Path ".ai-config")

Write-Host "--- Project Configuration ---" -ForegroundColor Cyan

if (-not $isFramework) {

    # Git hooks path
    $hooksPath = ""
    try {
        $hooksPath = (git config --get core.hooksPath 2>$null)
    } catch { }

    if ($hooksPath) {
        if ($hooksPath -eq ".ci-local/hooks") {
            Check-Ok "Git hooks path configured ($hooksPath)"
        } else {
            Check-Warn "Git hooks path set to '$hooksPath' (expected .ci-local/hooks)"
        }
    } else {
        Check-Fail "Git hooks path not configured (run: git config core.hooksPath .ci-local/hooks)"
    }

    # .gitignore checks
    if (Test-Path ".gitignore") {
        Check-Ok ".gitignore exists"
        $gitignoreContent = Get-Content ".gitignore" -Raw
        foreach ($entry in @(".env", "CLAUDE.md", "node_modules")) {
            if ($gitignoreContent -match [regex]::Escape($entry)) {
                Check-Ok ".gitignore contains '$entry'"
            } else {
                Check-Warn ".gitignore missing '$entry' entry"
            }
        }
    } else {
        Check-Fail ".gitignore missing"
    }

    # Stack detection
    $stack = Detect-Stack "."
    if ($stack.StackType -ne "unknown") {
        Check-Ok "Stack detected: $($stack.StackType) (build tool: $($stack.BuildTool))"
    } else {
        Check-Warn "No stack detected (unknown project type)"
    }

    # Framework version alignment
    if (Test-Path ".framework-version") {
        $projectVersion = (Get-Content ".framework-version" -Raw).Trim()
        $frameworkVersion = ""
        foreach ($candidate in @("../project-starter-framework/.framework-version", "../../project-starter-framework/.framework-version")) {
            if (Test-Path $candidate) {
                $frameworkVersion = (Get-Content $candidate -Raw).Trim()
                break
            }
        }

        if ($frameworkVersion) {
            if ($projectVersion -eq $frameworkVersion) {
                Check-Ok "Framework version aligned (v$projectVersion)"
            } else {
                Check-Warn "Framework version mismatch: project v$projectVersion vs framework v$frameworkVersion"
            }
        } else {
            Check-Info "Project framework version: v$projectVersion (framework not found for comparison)"
        }
    }

} else {
    Check-Info "Running inside the framework repo (project checks skipped)"
}

Write-Host ""

# =============================================================================
# Summary
# =============================================================================
$total = $script:PassCount + $script:WarnCount + $script:FailCount

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host -NoNewline "  "
Write-Host -NoNewline "Passed: $($script:PassCount)" -ForegroundColor Green
Write-Host -NoNewline "  "
Write-Host -NoNewline "Warnings: $($script:WarnCount)" -ForegroundColor Yellow
Write-Host -NoNewline "  "
Write-Host -NoNewline "Failures: $($script:FailCount)" -ForegroundColor Red
Write-Host "  (Total: $total)"
Write-Host "==========================================================" -ForegroundColor Cyan

if ($script:FailCount -eq 0 -and $script:WarnCount -eq 0) {
    Write-Host "  All checks passed!" -ForegroundColor Green
} elseif ($script:FailCount -eq 0) {
    Write-Host "  Passed with $($script:WarnCount) warning(s)." -ForegroundColor Yellow
} else {
    Write-Host "  $($script:FailCount) check(s) failed. Review the output above." -ForegroundColor Red
}

Write-Host ""

if ($script:FailCount -gt 0) {
    exit 1
}

exit 0
