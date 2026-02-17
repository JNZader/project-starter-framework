# =============================================================================
# GENERATE-AGENTS-CATALOG: Generates AGENTS.md catalog from agent files
# =============================================================================
# Scans .ai-config/agents/ for agent .md files, extracts name and description
# from YAML frontmatter, and produces a categorized markdown catalog.
#
# Usage:
#   .\scripts\generate-agents-catalog.ps1
#
# Output:
#   .ai-config\AGENTS.md
# =============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$AiConfigDir = "$ProjectDir\.ai-config"
$AgentsDir = "$AiConfigDir\agents"
$OutputFile = "$AiConfigDir\AGENTS.md"

Import-Module "$ScriptDir\..\lib\Common.psm1" -Force

Write-Host "=== Generate Agents Catalog ===" -ForegroundColor Cyan

if (-not (Test-Path $AgentsDir)) {
    Write-Host "Error: Agents directory not found at $AgentsDir" -ForegroundColor Red
    exit 1
}

# =============================================================================
# Extract frontmatter field from a file
# =============================================================================
function Get-FrontmatterField {
    param(
        [string]$FilePath,
        [string]$FieldName
    )

    $lines = Get-Content $FilePath
    $inFrontmatter = 0
    $frontmatterLines = @()

    foreach ($line in $lines) {
        if ($line -match "^---\s*$") {
            $inFrontmatter++
            if ($inFrontmatter -ge 2) { break }
            continue
        }
        if ($inFrontmatter -eq 1) {
            $frontmatterLines += $line
        }
    }

    $frontmatter = $frontmatterLines -join "`n"

    # Try to extract inline value: "field: value"
    $value = ""
    foreach ($fmLine in $frontmatterLines) {
        if ($fmLine -match "^${FieldName}:\s*(.+)$") {
            $value = $matches[1].Trim()
            # If value is just ">", it's a multiline YAML scalar; grab next line
            if ($value -eq ">") {
                $value = ""
            }
            break
        }
        if ($fmLine -match "^${FieldName}:\s*$") {
            # Empty inline value, next non-blank indented line has the content
            $value = ""
            break
        }
    }

    # If no inline value found, look for multiline content on the line after the field
    if ([string]::IsNullOrWhiteSpace($value)) {
        $foundField = $false
        foreach ($fmLine in $frontmatterLines) {
            if ($foundField) {
                $trimmed = $fmLine.TrimStart()
                if ($trimmed.Length -gt 0 -and $fmLine -match "^\s") {
                    $value = $trimmed
                }
                break
            }
            if ($fmLine -match "^${FieldName}:") {
                $foundField = $true
            }
        }
    }

    # Remove surrounding quotes if present
    $value = $value -replace "^['""]", "" -replace "['""]$", ""
    # Remove trailing > for YAML multiline indicators
    $value = $value -replace "\s*>$", ""

    return $value
}

# =============================================================================
# Capitalize first letter of a string
# =============================================================================
function ConvertTo-TitleWord {
    param([string]$Word)
    if ([string]::IsNullOrEmpty($Word)) { return $Word }
    return $Word.Substring(0,1).ToUpper() + $Word.Substring(1)
}

# =============================================================================
# Collect all agents grouped by category
# =============================================================================

$agentsByCategory = @{}
$agentCount = 0

$agentFiles = Get-ChildItem $AgentsDir -Recurse -Filter "*.md" | Where-Object { $_.Name -ne "_TEMPLATE.md" }

foreach ($agentFile in $agentFiles) {
    $name = Get-FrontmatterField -FilePath $agentFile.FullName -FieldName "name"
    if ([string]::IsNullOrWhiteSpace($name)) { continue }

    $description = Get-FrontmatterField -FilePath $agentFile.FullName -FieldName "description"

    # Determine category from directory structure
    $relPath = $agentFile.FullName.Substring($AgentsDir.Length + 1)
    $dirPart = Split-Path -Parent $relPath

    if ([string]::IsNullOrWhiteSpace($dirPart)) {
        $category = "root"
    } else {
        # Use first directory component as category
        $category = ($dirPart -split "[\\/]")[0]
    }

    if (-not $agentsByCategory.ContainsKey($category)) {
        $agentsByCategory[$category] = @()
    }
    $agentsByCategory[$category] += [PSCustomObject]@{
        Name        = $name
        Description = $description
    }

    $agentCount++
}

# =============================================================================
# Generate the output file
# =============================================================================

# Backup existing file before overwrite
Backup-IfExists $OutputFile

# Build content
$content = @"
# Available Agents

> Auto-generated catalog. Do not edit manually.
> Generated by: scripts/generate-agents-catalog.ps1

"@

# Sort categories: root first, then alphabetical
$sortedCategories = @()
if ($agentsByCategory.ContainsKey("root")) {
    $sortedCategories += "root"
}
$otherCategories = $agentsByCategory.Keys | Where-Object { $_ -ne "root" } | Sort-Object
$sortedCategories += $otherCategories

$categoryCount = 0

foreach ($category in $sortedCategories) {
    $agents = $agentsByCategory[$category]
    if ($null -eq $agents -or $agents.Count -eq 0) { continue }

    # Capitalize category name for display
    if ($category -eq "root") {
        $displayName = "General"
    } elseif ($category -match "-") {
        # Handle hyphenated names: data-ai -> Data Ai
        $parts = $category -split "-"
        $capitalizedParts = $parts | ForEach-Object { ConvertTo-TitleWord $_ }
        $displayName = $capitalizedParts -join " "
    } else {
        $displayName = ConvertTo-TitleWord $category
    }

    $content += "## $displayName`n`n"
    $content += "| Agent | Description |`n"
    $content += "|-------|-------------|`n"

    # Sort agents alphabetically within category
    $sortedAgents = $agents | Sort-Object -Property Name
    foreach ($agent in $sortedAgents) {
        $escapedDesc = $agent.Description -replace "\|", "\|"
        $content += "| $($agent.Name) | $escapedDesc |`n"
    }

    $content += "`n"
    $categoryCount++
}

$content | Out-File -FilePath $OutputFile -Encoding utf8

Write-Host "Generated catalog with $agentCount agents in $categoryCount categories" -ForegroundColor Green
Write-Host "  Output: $OutputFile"
