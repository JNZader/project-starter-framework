Import-Module -Name "$PSScriptRoot/../../lib/Common.psm1" -Force

Describe 'Common.psm1 - PowerShell parity tests' {
    BeforeAll {
        $tmp = Join-Path $env:TEMP "ps-test-$([System.Guid]::NewGuid().ToString('N'))"
        New-Item -Path $tmp -ItemType Directory | Out-Null
    }

    AfterAll {
        if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    }

    It 'Backup-IfExists creates .bak file' {
        $file = Join-Path $tmp 'sample.txt'
        Set-Content -Path $file -Value 'original'
        Backup-IfExists -Path $file
        Test-Path "$file.bak" | Should -BeTrue
        (Get-Content "$file.bak") -join "`n" | Should -Match 'original'
    }

    Context 'Detect-Stack' {
        It 'detects java-gradle' {
            $dir = Join-Path $tmp 'java-gradle'
            New-Item -Path $dir -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $dir 'build.gradle') -ItemType File | Out-Null
            $res = Detect-Stack -ProjectPath $dir
            $res.StackType | Should -Be 'java-gradle'
            $res.BuildTool | Should -Be 'gradle'
        }

        It 'detects node with pnpm' {
            $dir = Join-Path $tmp 'node'
            New-Item -Path $dir -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $dir 'package.json') -ItemType File | Out-Null
            New-Item -Path (Join-Path $dir 'pnpm-lock.yaml') -ItemType File | Out-Null
            $res = Detect-Stack -ProjectPath $dir
            $res.StackType | Should -Be 'node'
            $res.BuildTool | Should -Be 'pnpm'
        }

        It 'detects python with poetry' {
            $dir = Join-Path $tmp 'python'
            New-Item -Path $dir -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $dir 'pyproject.toml') -ItemType File | Out-Null
            New-Item -Path (Join-Path $dir 'poetry.lock') -ItemType File | Out-Null
            $res = Detect-Stack -ProjectPath $dir
            $res.StackType | Should -Be 'python'
            $res.BuildTool | Should -Be 'poetry'
        }

        It 'returns unknown for empty dir' {
            $dir = Join-Path $tmp 'empty'
            New-Item -Path $dir -ItemType Directory | Out-Null
            $res = Detect-Stack -ProjectPath $dir
            $res.StackType | Should -Be 'unknown'
        }
    }

    It 'Detect-Framework locates the framework when templates exist' {
        # Use repo root relative to test file
        Push-Location (Join-Path (Split-Path -Parent $PSScriptRoot) '..')
        try {
            $fw = Detect-Framework
            $fw.FrameworkDir | Should -Not -BeNullOrEmpty
        } finally {
            Pop-Location
        }
    }

    It 'sync-ai-config.ps1 merge mode appends generated section without overwriting custom content' {
        $tmpDir = Join-Path $tmp 'sync-merge-test'
        New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $tmpDir '.ai-config\agents') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $tmpDir 'scripts') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $tmpDir 'lib') -ItemType Directory -Force | Out-Null

        # minimal agent
        @'
---
name: test-agent
description: Test agent
---
'@ | Out-File -FilePath (Join-Path $tmpDir '.ai-config\agents\test-agent.md') -Encoding utf8

        # existing CLAUDE.md with custom content
        "# Project manual instructions`n`nDo not overwrite this section." | Out-File -FilePath (Join-Path $tmpDir 'CLAUDE.md') -Encoding utf8

        # copy sync script and shared library into temp project and run in merge mode
        Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\scripts\sync-ai-config.ps1") -Destination (Join-Path $tmpDir 'scripts\sync-ai-config.ps1') -Force
        Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\lib\Common.psm1") -Destination (Join-Path $tmpDir 'lib\Common.psm1') -Force
        Push-Location $tmpDir
        try {
            $env:SYNC_AI_CONFIG_MODE = 'merge'
            & .\scripts\sync-ai-config.ps1 -Target claude *>&1 | Out-Null
        } finally {
            Pop-Location
            Remove-Item Env:SYNC_AI_CONFIG_MODE -ErrorAction SilentlyContinue
        }

        # assert CLAUDE.md preserved custom section and contains generated agent
        (Get-Content (Join-Path $tmpDir 'CLAUDE.md') -Raw) | Should -Match 'Project manual instructions'
        (Get-Content (Join-Path $tmpDir 'CLAUDE.md') -Raw) | Should -Match 'test-agent'

        Remove-Item -Recurse -Force $tmpDir
    }

    It 'validate-frontmatter.py accepts multi-line description and valid name' {
        $tmpFile = Join-Path $tmp 'fm-valid.md'
        @'
---
name: valid-name
description: |
  line1
  line2
---
'@ | Out-File -FilePath $tmpFile -Encoding utf8
        & python3 "$PSScriptRoot\..\..\scripts\validate-frontmatter.py" $tmpFile
        $LASTEXITCODE | Should -Be 0
        Remove-Item $tmpFile -Force
    }

    It 'validate-frontmatter.py rejects invalid name' {
        $tmpFile = Join-Path $tmp 'fm-bad.md'
        @'
---
name: Bad_Name
description: Example
---
'@ | Out-File -FilePath $tmpFile -Encoding utf8
        & python3 "$PSScriptRoot\..\..\scripts\validate-frontmatter.py" $tmpFile
        $LASTEXITCODE | Should -Not -Be 0
        Remove-Item $tmpFile -Force
    }
}
