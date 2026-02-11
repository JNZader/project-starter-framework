# =============================================================================
# ADD-SKILL: Agrega skills de Gentleman-Skills u otras fuentes
# =============================================================================
# Uso:
#   .\scripts\add-skill.ps1 gentleman react-19
#   .\scripts\add-skill.ps1 gentleman typescript
#   .\scripts\add-skill.ps1 list              # Listar skills disponibles
#   .\scripts\add-skill.ps1 installed         # Ver skills instalados
# =============================================================================

param(
    [Parameter(Position=0)]
    [string]$Command = "help",

    [Parameter(Position=1)]
    [string]$SkillName = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$SkillsDir = Join-Path $ProjectDir ".ai-config\skills"
$GentlemanRepo = "https://github.com/Gentleman-Programming/Gentleman-Skills.git"
$TempDir = Join-Path $env:TEMP "gentleman-skills"

function Show-Help {
    Write-Host "ADD-SKILL: Agrega skills al proyecto" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso:"
    Write-Host "  .\scripts\add-skill.ps1 gentleman <skill-name>  # Desde Gentleman-Skills"
    Write-Host "  .\scripts\add-skill.ps1 list                    # Listar disponibles"
    Write-Host "  .\scripts\add-skill.ps1 installed               # Ver instalados"
    Write-Host "  .\scripts\add-skill.ps1 remove <skill-name>     # Remover skill"
    Write-Host ""
    Write-Host "Skills populares de Gentleman-Skills:"
    Write-Host "  - react-19, typescript, playwright, angular"
    Write-Host "  - vercel-ai-sdk-5, zustand-5, tailwindcss-4"
    Write-Host ""
}

function Clone-Gentleman {
    if (-not (Test-Path $TempDir)) {
        Write-Host "Cloning Gentleman-Skills repository..." -ForegroundColor Yellow
        git clone --depth 1 $GentlemanRepo $TempDir 2>$null
    } else {
        Write-Host "Updating Gentleman-Skills repository..." -ForegroundColor Yellow
        Push-Location $TempDir
        git pull 2>$null
        Pop-Location
    }
}

function List-Available {
    Clone-Gentleman
    Write-Host "=== Available Skills ===" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Curated (official):" -ForegroundColor Green
    $curatedPath = Join-Path $TempDir "curated"
    if (Test-Path $curatedPath) {
        Get-ChildItem -Path $curatedPath -Directory | Where-Object { $_.Name -ne "README" } | ForEach-Object {
            Write-Host "  - $($_.Name)"
        }
    } else {
        Write-Host "  (none)"
    }

    Write-Host ""
    Write-Host "Community:" -ForegroundColor Green
    $communityPath = Join-Path $TempDir "community"
    if (Test-Path $communityPath) {
        Get-ChildItem -Path $communityPath -Directory | Where-Object { $_.Name -ne "README" } | ForEach-Object {
            Write-Host "  - $($_.Name)"
        }
    } else {
        Write-Host "  (none)"
    }
}

function List-Installed {
    Write-Host "=== Installed Skills ===" -ForegroundColor Cyan
    Write-Host ""

    # List directories
    Get-ChildItem -Path $SkillsDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "_TEMPLATE" } |
        ForEach-Object { Write-Host "  - $($_.Name)" }

    # List .md files
    Get-ChildItem -Path $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -ne "_TEMPLATE" } |
        ForEach-Object { Write-Host "  - $($_.BaseName)" }
}

function Add-GentlemanSkill {
    param([string]$Name)

    # Validate skill name (security: prevent path traversal)
    if ($Name -notmatch '^[a-zA-Z0-9_-]+$') {
        Write-Host "Error: Invalid skill name format. Use only alphanumeric, dash, underscore." -ForegroundColor Red
        exit 1
    }

    Clone-Gentleman

    # Find skill in curated or community
    $sourcePath = $null
    $curatedPath = Join-Path $TempDir "curated\$Name"
    $communityPath = Join-Path $TempDir "community\$Name"

    if (Test-Path $curatedPath) {
        $sourcePath = $curatedPath
    } elseif (Test-Path $communityPath) {
        $sourcePath = $communityPath
    } else {
        Write-Host "Skill '$Name' not found in Gentleman-Skills" -ForegroundColor Red
        Write-Host "Use '.\scripts\add-skill.ps1 list' to see available skills"
        exit 1
    }

    # Copy skill
    Write-Host "Installing skill: $Name" -ForegroundColor Yellow
    Copy-Item -Path $sourcePath -Destination $SkillsDir -Recurse -Force

    Write-Host "Done: Skill '$Name' installed" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Review: $SkillsDir\$Name\"
    Write-Host "  2. Sync config: .\scripts\sync-ai-config.ps1"
}

function Remove-Skill {
    param([string]$Name)

    $skillPath = Join-Path $SkillsDir $Name
    $skillFile = Join-Path $SkillsDir "$Name.md"

    if (Test-Path $skillPath) {
        Remove-Item -Path $skillPath -Recurse -Force
        Write-Host "Done: Removed skill: $Name" -ForegroundColor Green
    } elseif (Test-Path $skillFile) {
        Remove-Item -Path $skillFile -Force
        Write-Host "Done: Removed skill: $Name" -ForegroundColor Green
    } else {
        Write-Host "Skill '$Name' not found" -ForegroundColor Red
        exit 1
    }
}

# =============================================================================
# Main
# =============================================================================
switch ($Command.ToLower()) {
    { $_ -in "gentleman", "g" } {
        if ([string]::IsNullOrEmpty($SkillName)) {
            Write-Host "Error: Specify skill name" -ForegroundColor Red
            Write-Host "Example: .\scripts\add-skill.ps1 gentleman react-19"
            exit 1
        }
        Add-GentlemanSkill -Name $SkillName
    }
    { $_ -in "list", "ls" } {
        List-Available
    }
    { $_ -in "installed", "i" } {
        List-Installed
    }
    { $_ -in "remove", "rm" } {
        if ([string]::IsNullOrEmpty($SkillName)) {
            Write-Host "Error: Specify skill name to remove" -ForegroundColor Red
            exit 1
        }
        Remove-Skill -Name $SkillName
    }
    default {
        Show-Help
    }
}
