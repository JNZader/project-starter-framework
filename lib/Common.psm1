# =============================================================================
# lib/Common.psm1 - Shared functions for project-starter-framework (Windows)
# =============================================================================
# Import from scripts:   Import-Module "$ScriptDir/../lib/Common.psm1" -Force
# Import from ci-local:  Import-Module "$ScriptDir/../lib/Common.psm1" -Force
# =============================================================================

# =============================================================================
# Backup-IfExists - Create a .bak copy of a file before overwriting
# =============================================================================
# Usage: Backup-IfExists "path/to/file"
# =============================================================================
function Backup-IfExists {
    param([string]$Path)
    if (Test-Path $Path) {
        Copy-Item $Path "$Path.bak" -Force
        Write-Host "  Backed up existing $Path" -ForegroundColor Yellow
    }
}

# =============================================================================
# Detect-Stack - Auto-detect project technology stack
# =============================================================================
# Returns: Hashtable with StackType, BuildTool, JavaVersion
# Detects: java-gradle, java-maven, node, python, go, rust
#
# Usage:
#   $stack = Detect-Stack                     # Detects from current directory
#   $stack = Detect-Stack "C:\path\to\project"  # Detects from given directory
#
# NOTE: Does NOT set LintCmd/CompileCmd/TestCmd. Those are CI-specific
#       and should be configured by the caller (e.g., ci-local.ps1).
# =============================================================================
function Detect-Stack {
    param(
        [string]$ProjectPath = "."
    )

    $result = @{
        StackType   = "unknown"
        BuildTool   = ""
        JavaVersion = "21"
    }

    # Java + Gradle
    if ((Test-Path "$ProjectPath/build.gradle") -or (Test-Path "$ProjectPath/build.gradle.kts")) {
        $result.BuildTool = "gradle"
        $result.StackType = "java-gradle"

        # Detect Java version from build files
        $buildFile = $null
        if (Test-Path "$ProjectPath/build.gradle.kts") {
            $buildFile = Get-Content "$ProjectPath/build.gradle.kts" -Raw
        } elseif (Test-Path "$ProjectPath/build.gradle") {
            $buildFile = Get-Content "$ProjectPath/build.gradle" -Raw
        }
        if ($buildFile) {
            if ($buildFile -match "languageVersion\s*[=.]\s*JavaLanguageVersion\.of\((\d+)\)") {
                $result.JavaVersion = $matches[1]
            } elseif ($buildFile -match "sourceCompatibility\s*=\s*['""]?(\d+)") {
                $result.JavaVersion = $matches[1]
            }
        }
        return $result
    }

    # Java + Maven
    if (Test-Path "$ProjectPath/pom.xml") {
        $result.BuildTool = "maven"
        $result.StackType = "java-maven"
        return $result
    }

    # Node.js
    if (Test-Path "$ProjectPath/package.json") {
        $result.StackType = "node"
        if (Test-Path "$ProjectPath/pnpm-lock.yaml") { $result.BuildTool = "pnpm" }
        elseif (Test-Path "$ProjectPath/yarn.lock") { $result.BuildTool = "yarn" }
        else { $result.BuildTool = "npm" }
        return $result
    }

    # Python
    if ((Test-Path "$ProjectPath/pyproject.toml") -or (Test-Path "$ProjectPath/setup.py") -or (Test-Path "$ProjectPath/requirements.txt")) {
        $result.StackType = "python"
        if (Test-Path "$ProjectPath/uv.lock") { $result.BuildTool = "uv" }
        elseif (Test-Path "$ProjectPath/poetry.lock") { $result.BuildTool = "poetry" }
        elseif (Test-Path "$ProjectPath/Pipfile") { $result.BuildTool = "pipenv" }
        else { $result.BuildTool = "pip" }
        return $result
    }

    # Go
    if (Test-Path "$ProjectPath/go.mod") {
        $result.BuildTool = "go"
        $result.StackType = "go"
        return $result
    }

    # Rust
    if (Test-Path "$ProjectPath/Cargo.toml") {
        $result.BuildTool = "cargo"
        $result.StackType = "rust"
        return $result
    }

    return $result
}

# =============================================================================
# Detect-Framework - Locate the project-starter-framework directory
# =============================================================================
# Returns: Hashtable with FrameworkDir (path or empty), HasOptional (bool)
#
# Usage: $fw = Detect-Framework
# =============================================================================
function Detect-Framework {
    $result = @{
        FrameworkDir = ""
        HasOptional  = $false
    }

    if ((Test-Path "templates") -and (Test-Path ".ai-config")) {
        $result.FrameworkDir = "."
    } elseif ((Test-Path "../templates") -and (Test-Path "../.ai-config")) {
        $result.FrameworkDir = ".."
    }

    if ($result.FrameworkDir -and (Test-Path "$($result.FrameworkDir)/optional")) {
        $result.HasOptional = $true
    }

    return $result
}

Export-ModuleMember -Function Detect-Stack, Detect-Framework, Backup-IfExists
