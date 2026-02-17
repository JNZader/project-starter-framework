# =============================================================================
# validate-framework.ps1 - Validates framework structure and consistency
# =============================================================================
# PowerShell counterpart of validate-framework.sh
# Usage: .\scripts\validate-framework.ps1 [-Help]
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
    Write-Host "Usage: .\scripts\validate-framework.ps1 [-Help]"
    Write-Host ""
    Write-Host "Validates framework structure, AI config, templates, workflows,"
    Write-Host "scripts, and Bash/PowerShell parity."
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
# Counters + wrappers that log AND count
# =============================================================================
$script:PassCount = 0
$script:WarnCount = 0
$script:FailCount = 0

function Check-Pass {
    param([string]$Message)
    Write-Host "  [PASS] $Message" -ForegroundColor Green
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

# =============================================================================
# Header
# =============================================================================
Write-Host ""
Write-Host "=== Framework Validation ===" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# [1/6] Core structure
# =============================================================================
Write-Host "[1/6] Core structure" -ForegroundColor Cyan

foreach ($dir in @(".ci-local", ".ai-config", "templates", "scripts", "lib")) {
    if (Test-Path $dir -PathType Container) {
        Check-Pass "$dir/ exists"
    } else {
        Check-Fail "$dir/ missing"
    }
}

foreach ($file in @(".framework-version", ".releaserc", ".gitignore.template", "CLAUDE.md")) {
    if (Test-Path $file -PathType Leaf) {
        Check-Pass "$file exists"
    } else {
        Check-Fail "$file missing"
    }
}

# Validate .framework-version semver format
if (Test-Path ".framework-version" -PathType Leaf) {
    $fwVersion = (Get-Content ".framework-version" -Raw).Trim()
    if ($fwVersion -match '^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$') {
        Check-Pass ".framework-version is valid semver ($fwVersion)"
    } else {
        Check-Fail ".framework-version is not valid semver: $fwVersion"
    }
}

# =============================================================================
# [2/6] AI Config
# =============================================================================
Write-Host ""
Write-Host "[2/6] AI Config" -ForegroundColor Cyan

$agentFiles = @(Get-ChildItem -Path ".ai-config/agents" -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_TEMPLATE.md" })
$skillFiles = @(Get-ChildItem -Path ".ai-config/skills" -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_TEMPLATE.md" })

Write-Host "  Agents: $($agentFiles.Count), Skills: $($skillFiles.Count)"

# --- Python frontmatter validator (if python3 available) ---
$pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    # Verify it is Python 3
    if ($pythonCmd) {
        try {
            $pyVer = & $pythonCmd.Source --version 2>&1
            if ($pyVer -notmatch "Python 3") {
                $pythonCmd = $null
            }
        } catch {
            $pythonCmd = $null
        }
    }
}

if ($pythonCmd -and (Test-Path "scripts/validate-frontmatter.py")) {
    Write-Host "  Using Python frontmatter validator (scripts/validate-frontmatter.py)"
    $pythonExe = $pythonCmd.Source

    foreach ($file in $agentFiles) {
        $relativePath = $file.FullName.Replace("$FrameworkDir\", "").Replace("\", "/")
        try {
            $null = & $pythonExe "$FrameworkDir/scripts/validate-frontmatter.py" $file.FullName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Check-Pass "Frontmatter OK: $relativePath"
            } else {
                Check-Fail "Frontmatter schema invalid: $relativePath"
            }
        } catch {
            Check-Fail "Frontmatter schema invalid: $relativePath"
        }
    }

    foreach ($file in $skillFiles) {
        $relativePath = $file.FullName.Replace("$FrameworkDir\", "").Replace("\", "/")
        try {
            $null = & $pythonExe "$FrameworkDir/scripts/validate-frontmatter.py" $file.FullName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Check-Pass "Frontmatter OK: $relativePath"
            } else {
                Check-Fail "Frontmatter schema invalid: $relativePath"
            }
        } catch {
            Check-Fail "Frontmatter schema invalid: $relativePath"
        }
    }
} else {
    Write-Host "  Python3 not found -- using legacy checks (less strict)"
}

# --- Strict frontmatter validation for agents ---
foreach ($agent in $agentFiles) {
    $relativePath = $agent.FullName.Replace("$FrameworkDir\", "").Replace("\", "/")
    $lines = Get-Content $agent.FullName

    if ($lines.Count -eq 0 -or $lines[0] -ne "---") {
        Check-Fail "No frontmatter: $relativePath"
        continue
    }

    # Extract name: line
    $nameLine = $lines | Where-Object { $_ -match "^name:\s*" } | Select-Object -First 1
    $descLine = $lines | Where-Object { $_ -match "^description:\s*" } | Select-Object -First 1

    if (-not $nameLine) {
        Check-Fail "Missing 'name:' in $relativePath"
    } else {
        $nameValue = ($nameLine -replace "^name:\s*", "") -replace "[`"']", "" | ForEach-Object { $_.Trim() }
        if ([string]::IsNullOrWhiteSpace($nameValue)) {
            Check-Fail "Empty 'name' in $relativePath"
        } elseif ($nameValue -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            Check-Fail "Invalid 'name' (must be kebab-case) in $relativePath -> $nameValue"
        } else {
            Check-Pass "Agent name ok: $relativePath -> $nameValue"
        }
    }

    if (-not $descLine) {
        Check-Fail "Missing 'description:' in $relativePath"
    } else {
        $descValue = ($descLine -replace "^description:\s*", "") -replace "^[|>][-\s]*", ""
        if ([string]::IsNullOrWhiteSpace($descValue)) {
            # description might be multi-line; check the line after "description:"
            $descIndex = [array]::IndexOf($lines, $descLine)
            $nextLineContent = ""
            if ($descIndex -ge 0 -and ($descIndex + 1) -lt $lines.Count) {
                $nextLineContent = $lines[$descIndex + 1].Trim()
            }
            if ([string]::IsNullOrWhiteSpace($nextLineContent)) {
                Check-Fail "Empty 'description' in $relativePath"
            } else {
                Check-Pass "Agent description present for $relativePath"
            }
        } else {
            Check-Pass "Agent description present for $relativePath"
        }
    }
}

# --- Strict frontmatter validation for skills (same rules as agents) ---
foreach ($skill in $skillFiles) {
    $relativePath = $skill.FullName.Replace("$FrameworkDir\", "").Replace("\", "/")
    $lines = Get-Content $skill.FullName

    if ($lines.Count -eq 0 -or $lines[0] -ne "---") {
        Check-Fail "No frontmatter: $relativePath"
        continue
    }

    # Extract name: line
    $nameLine = $lines | Where-Object { $_ -match "^name:\s*" } | Select-Object -First 1
    $descLine = $lines | Where-Object { $_ -match "^description:\s*" } | Select-Object -First 1

    if (-not $nameLine) {
        Check-Fail "Missing 'name:' in $relativePath"
    } else {
        $nameValue = ($nameLine -replace "^name:\s*", "") -replace "[`"']", "" | ForEach-Object { $_.Trim() }
        if ([string]::IsNullOrWhiteSpace($nameValue)) {
            Check-Fail "Empty 'name' in $skill"
        } elseif ($nameValue -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            Check-Fail "Invalid 'name' (must be kebab-case) in $relativePath -> $nameValue"
        } else {
            Check-Pass "Skill name ok: $relativePath -> $nameValue"
        }
    }

    if (-not $descLine) {
        Check-Fail "Missing 'description:' in $relativePath"
    } else {
        $descValue = ($descLine -replace "^description:\s*", "") -replace "^[|>][-\s]*", ""
        if ([string]::IsNullOrWhiteSpace($descValue)) {
            # description might be multi-line; check the line after "description:"
            $descIndex = [array]::IndexOf($lines, $descLine)
            $nextLineContent = ""
            if ($descIndex -ge 0 -and ($descIndex + 1) -lt $lines.Count) {
                $nextLineContent = $lines[$descIndex + 1].Trim()
            }
            if ([string]::IsNullOrWhiteSpace($nextLineContent)) {
                Check-Fail "Empty 'description' in $relativePath"
            } else {
                Check-Pass "Skill description present for $relativePath"
            }
        } else {
            Check-Pass "Skill description present for $relativePath"
        }
    }
}

# =============================================================================
# [3/6] CI Templates
# =============================================================================
Write-Host ""
Write-Host "[3/6] CI Templates" -ForegroundColor Cyan

foreach ($provider in @("github", "gitlab", "woodpecker")) {
    $templateDir = "templates/$provider"
    if (Test-Path $templateDir -PathType Container) {
        $templateCount = @(Get-ChildItem -Path $templateDir -Filter "*.yml" -Recurse -File -ErrorAction SilentlyContinue).Count
        if ($templateCount -gt 0) {
            Check-Pass "templates/${provider}/: $templateCount templates"
        } else {
            Check-Warn "No templates for $provider"
        }
    } else {
        Check-Warn "No templates for $provider"
    }
}

# =============================================================================
# [4/6] Reusable Workflows
# =============================================================================
Write-Host ""
Write-Host "[4/6] Reusable Workflows" -ForegroundColor Cyan

$reusableWorkflows = @(Get-ChildItem -Path ".github/workflows" -Filter "reusable-*.yml" -File -ErrorAction SilentlyContinue)

foreach ($workflow in $reusableWorkflows) {
    $basename = $workflow.Name
    $content = Get-Content $workflow.FullName -Raw

    # Check has workflow_call trigger
    if ($content -match "workflow_call:") {
        Check-Pass "$basename has workflow_call"
    } else {
        Check-Fail "$basename missing workflow_call trigger"
    }

    # Check has permissions
    if ($content -match "permissions:") {
        Check-Pass "$basename has permissions"
    } else {
        Check-Warn "$basename missing permissions block"
    }
}

# =============================================================================
# [5/6] Scripts
# =============================================================================
Write-Host ""
Write-Host "[5/6] Scripts" -ForegroundColor Cyan

$bashScripts = @(Get-ChildItem -Path "scripts" -Filter "*.sh" -File -ErrorAction SilentlyContinue)

foreach ($script in $bashScripts) {
    $basename = $script.Name
    $content = Get-Content $script.FullName -Raw

    # Check sources lib/common.sh
    if ($content -match "lib/common\.sh") {
        Check-Pass "$basename sources lib/common.sh"
    } else {
        Check-Warn "$basename doesn't source shared library"
    }

    # Check has set -e
    if ($content -match "set -e") {
        Check-Pass "$basename has set -e"
    } else {
        Check-Warn "$basename missing set -e"
    }
}

# =============================================================================
# [6/6] Bash/PowerShell Parity
# =============================================================================
Write-Host ""
Write-Host "[6/6] Bash/PowerShell Parity" -ForegroundColor Cyan

foreach ($script in $bashScripts) {
    $basename = $script.Name
    $ps1Name = $basename -replace "\.sh$", ".ps1"
    $ps1Path = "scripts/$ps1Name"

    if (Test-Path $ps1Path -PathType Leaf) {
        Check-Pass "$basename has PS1 counterpart"
    } else {
        Check-Warn "$basename missing PS1 counterpart"
    }
}

# =============================================================================
# Summary
# =============================================================================
Write-Host ""
$total = $script:PassCount + $script:WarnCount + $script:FailCount

Write-Host "================================" -ForegroundColor Cyan
Write-Host -NoNewline "  "
Write-Host -NoNewline "Passed: $($script:PassCount)" -ForegroundColor Green
Write-Host -NoNewline "  "
Write-Host -NoNewline "Warnings: $($script:WarnCount)" -ForegroundColor Yellow
Write-Host -NoNewline "  "
Write-Host -NoNewline "Failures: $($script:FailCount)" -ForegroundColor Red
Write-Host "  (Total: $total)"
Write-Host "================================" -ForegroundColor Cyan

if ($script:FailCount -eq 0 -and $script:WarnCount -eq 0) {
    Write-Host "  All checks passed!" -ForegroundColor Green
} elseif ($script:FailCount -eq 0) {
    Write-Host "  Passed with $($script:WarnCount) warning(s)." -ForegroundColor Yellow
} else {
    Write-Host "  $($script:FailCount) error(s), $($script:WarnCount) warning(s)." -ForegroundColor Red
}

Write-Host ""

if ($script:FailCount -gt 0) {
    exit 1
}

exit 0
