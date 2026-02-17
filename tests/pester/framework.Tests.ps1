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
        Push-Location (Split-Path -Parent $PSScriptRoot + '\..')
        $fw = Detect-Framework
        $fw.FrameworkDir | Should -Not -BeNullOrEmpty
        Pop-Location
    }
}
