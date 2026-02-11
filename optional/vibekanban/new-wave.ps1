# =============================================================================
# NEW-WAVE: Crear oleada de tareas paralelas (Windows)
# =============================================================================
# Uso:
#   .\scripts\new-wave.ps1 "T-001 T-002 T-003"
#   .\scripts\new-wave.ps1 -List
#   .\scripts\new-wave.ps1 -Complete
# =============================================================================

param(
    [Parameter(Position=0)]
    [string]$Tasks,
    [switch]$List,
    [switch]$Complete,
    [switch]$CreateBranches,
    [switch]$Help
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$WavesFile = "$ProjectDir\.project\Memory\WAVES.md"

# Asegurar archivo de oleadas
if (-not (Test-Path $WavesFile)) {
    @"
# Oleadas de Trabajo

> Registro de oleadas de tareas paralelas

---

## Oleada Actual

**Numero:** 0
**Estado:** Ninguna activa
**Tareas:** -

---

## Historial

| # | Tareas | Inicio | Fin | Estado |
|---|--------|--------|-----|--------|
"@ | Out-File -FilePath $WavesFile -Encoding utf8
}

function Show-Help {
    Write-Host "NEW-WAVE: Gestión de oleadas de tareas paralelas" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso:"
    Write-Host "  .\scripts\new-wave.ps1 'T-001 T-002 T-003'   Crear oleada"
    Write-Host "  .\scripts\new-wave.ps1 -List                  Ver oleada actual"
    Write-Host "  .\scripts\new-wave.ps1 -Complete              Completar oleada"
    Write-Host "  .\scripts\new-wave.ps1 -CreateBranches        Crear branches"
}

function Get-CurrentWaveNumber {
    $content = Get-Content $WavesFile -Raw
    if ($content -match '\*\*Numero:\*\* (\d+)') {
        return [int]$matches[1]
    }
    return 0
}

function Show-Wave {
    Write-Host "=== Oleada Actual ===" -ForegroundColor Cyan
    Write-Host ""
    $content = Get-Content $WavesFile
    $inSection = $false
    $lineCount = 0
    foreach ($line in $content) {
        if ($line -match "## Oleada Actual") { $inSection = $true }
        if ($inSection) {
            Write-Host $line
            $lineCount++
            if ($lineCount -gt 8) { break }
        }
    }
}

function New-Wave {
    param([string]$TaskList)

    $waveNum = (Get-CurrentWaveNumber) + 1
    $today = Get-Date -Format "yyyy-MM-dd"
    $taskArray = $TaskList -split ' '
    $taskCount = $taskArray.Count

    Write-Host "Creando Oleada $waveNum..." -ForegroundColor Yellow
    Write-Host "  Tareas: $TaskList"
    Write-Host "  Total: $taskCount tareas"

    $content = Get-Content $WavesFile -Raw
    $content = $content -replace '\*\*Numero:\*\* \d+', "**Numero:** $waveNum"
    $content = $content -replace '\*\*Estado:\*\* .*', '**Estado:** En progreso'
    $content = $content -replace '\*\*Tareas:\*\* .*', "**Tareas:** $TaskList"
    $content | Set-Content $WavesFile

    Write-Host "Done: Oleada $waveNum creada" -ForegroundColor Green

    $response = Read-Host "¿Crear branches para cada tarea? (y/n)"
    if ($response -eq 'y') {
        New-Branches -TaskList $TaskList
    }
}

function New-Branches {
    param([string]$TaskList)

    $baseBranch = "develop"
    Write-Host "Creando branches..." -ForegroundColor Yellow

    git checkout $baseBranch 2>$null
    git pull origin $baseBranch 2>$null

    foreach ($task in ($TaskList -split ' ')) {
        $branchName = "feature/$($task.ToLower())"
        $exists = git show-ref --verify --quiet "refs/heads/$branchName" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Warning: Branch $branchName ya existe" -ForegroundColor Yellow
        } else {
            git checkout -b $branchName $baseBranch
            Write-Host "  Done: Creado $branchName" -ForegroundColor Green
        }
    }

    git checkout $baseBranch
    Write-Host "Done: Branches creados" -ForegroundColor Green
}

function Complete-Wave {
    $waveNum = Get-CurrentWaveNumber
    $today = Get-Date -Format "yyyy-MM-dd"

    Write-Host "Completando Oleada $waveNum..." -ForegroundColor Yellow

    $content = Get-Content $WavesFile -Raw
    $content = $content -replace '\*\*Estado:\*\* .*', '**Estado:** Ninguna activa'
    $content = $content -replace '\*\*Tareas:\*\* .*', '**Tareas:** -'
    $content | Set-Content $WavesFile

    Write-Host "Done: Oleada $waveNum completada" -ForegroundColor Green
}

# Main
if ($Help) {
    Show-Help
} elseif ($List) {
    Show-Wave
} elseif ($Complete) {
    Complete-Wave
} elseif ($CreateBranches) {
    $content = Get-Content $WavesFile -Raw
    if ($content -match '\*\*Tareas:\*\* (.+)') {
        $tasks = $matches[1]
        if ($tasks -ne '-') {
            New-Branches -TaskList $tasks
        } else {
            Write-Host "No hay tareas en la oleada actual" -ForegroundColor Red
        }
    }
} elseif ($Tasks) {
    New-Wave -TaskList $Tasks
} else {
    Show-Help
}
