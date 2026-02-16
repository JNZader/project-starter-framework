# =============================================================================
# INSTALL-ENGRAM: Instala Engram memory server para AI agents (Windows)
# =============================================================================
# Uso:
#   .\install-engram.ps1              # Instalar ultima version
#   .\install-engram.ps1 -Check       # Solo verificar
#   .\install-engram.ps1 -McpConfig   # Generar config MCP
# =============================================================================

param(
    [switch]$Check,
    [switch]$McpConfig,
    [string]$ProjectName = (Split-Path -Leaf (Get-Location))
)

$ErrorActionPreference = "Stop"
$Repo = "Gentleman-Programming/engram"
$InstallDir = "$env:LOCALAPPDATA\engram"

function Test-EngramInstalled {
    $engram = Get-Command engram -ErrorAction SilentlyContinue
    if ($engram) {
        $version = & engram --version 2>$null
        Write-Host "Engram ya instalado: $version" -ForegroundColor Green
        Write-Host "  Path: $($engram.Source)"
        return $true
    }
    return $false
}

function Get-McpConfig {
    param([string]$Name)
    @"
{
  "mcpServers": {
    "engram": {
      "command": "engram",
      "args": ["mcp"],
      "env": {
        "ENGRAM_PROJECT": "$Name"
      }
    }
  }
}
"@
}

# Check mode
if ($Check) {
    if (Test-EngramInstalled) { exit 0 }
    else {
        Write-Host "Engram no instalado" -ForegroundColor Yellow
        exit 1
    }
}

# MCP config mode
if ($McpConfig) {
    Get-McpConfig -Name $ProjectName
    exit 0
}

# Install
Write-Host "=== Instalando Engram ===" -ForegroundColor Cyan

if (Test-EngramInstalled) {
    $reinstall = Read-Host "  Reinstalar? [y/N]"
    if ($reinstall -ne "y") { exit 0 }
}

# Detect architecture
$arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i386" }
$platform = "Windows_${arch}"
Write-Host "Plataforma: $platform" -ForegroundColor Yellow

# Get latest version
Write-Host "Buscando ultima version..." -ForegroundColor Yellow
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
$version = $release.tag_name
Write-Host "Version: $version" -ForegroundColor Green

# Download
$archiveName = "engram_${platform}.zip"
$downloadUrl = "https://github.com/$Repo/releases/download/$version/$archiveName"
$tmpDir = Join-Path $env:TEMP "engram-install"

Write-Host "Descargando $downloadUrl..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
Invoke-WebRequest -Uri $downloadUrl -OutFile "$tmpDir\engram.zip"

# Extract
Write-Host "Extrayendo..." -ForegroundColor Yellow
Expand-Archive -Path "$tmpDir\engram.zip" -DestinationPath $tmpDir -Force

# Install
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Copy-Item "$tmpDir\engram.exe" "$InstallDir\engram.exe" -Force

# Add to PATH if needed
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$userPath;$InstallDir", "User")
    Write-Host "Agregado $InstallDir al PATH del usuario" -ForegroundColor Green
    Write-Host "  Reinicia la terminal para que surta efecto" -ForegroundColor Yellow
}

# Cleanup
Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue

# Verify
if (Test-Path "$InstallDir\engram.exe") {
    Write-Host "Engram instalado correctamente" -ForegroundColor Green
    Write-Host "  Path: $InstallDir\engram.exe"
} else {
    Write-Host "Error: engram.exe no encontrado" -ForegroundColor Red
    exit 1
}

# Show MCP config
Write-Host ""
Write-Host "Config MCP para tu proyecto:" -ForegroundColor Cyan
Write-Host ""
Get-McpConfig -Name $ProjectName
Write-Host ""
Write-Host "Copia esto a .mcp.json en la raiz de tu proyecto" -ForegroundColor Green
