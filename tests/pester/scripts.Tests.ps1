Describe 'Scripts - PowerShell smoke tests' {
    BeforeAll {
        $TestRoot = Join-Path $env:TEMP "ps-scripts-tests-$([System.Guid]::NewGuid().ToString('N'))"
        New-Item -Path $TestRoot -ItemType Directory | Out-Null
    }

    AfterAll {
        if (Test-Path $TestRoot) { Remove-Item -Recurse -Force $TestRoot }
    }

    Context 'init-project.ps1' {
        It 'runs in DryRun + NonInteractive without modifying files' {
            $proj = Join-Path $TestRoot 'proj-init'
            New-Item -Path $proj -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj 'scripts') -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj 'lib') -ItemType Directory | Out-Null

            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\scripts\init-project.ps1") -Destination (Join-Path $proj 'scripts\init-project.ps1') -Force
            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\lib\Common.psm1") -Destination (Join-Path $proj 'lib\Common.psm1') -Force

            Push-Location $proj
            $output = & .\scripts\init-project.ps1 -DryRun -NonInteractive *>&1 | Out-String
            $output | Should -Match 'DRY-RUN'
            Test-Path (Join-Path $proj '.gitignore') | Should -BeFalse
            Pop-Location
        }
    }

    Context 'add-skill.ps1' {
        It 'lists installed skills and can remove a skill safely' {
            $proj = Join-Path $TestRoot 'proj-addskill'
            New-Item -Path $proj -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj '.ai-config\skills') -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $proj 'scripts') -ItemType Directory | Out-Null

            # create demo skill files
            "---`nname: demo-skill`ndescription: Demo`n---" | Out-File -FilePath (Join-Path $proj '.ai-config\skills\demo-skill.md') -Encoding utf8
            New-Item -Path (Join-Path $proj '.ai-config\skills\demo-dir') -ItemType Directory | Out-Null

            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\scripts\add-skill.ps1") -Destination (Join-Path $proj 'scripts\add-skill.ps1') -Force

            Push-Location $proj
            # list installed should show demo-skill
            $output = & .\scripts\add-skill.ps1 installed *>&1 | Out-String
            $output | Should -Match 'demo-skill'

            # remove demo-skill.md
            & .\scripts\add-skill.ps1 remove demo-skill *>&1 | Out-Null
            Test-Path (Join-Path $proj '.ai-config\skills\demo-skill.md') | Should -BeFalse
            Pop-Location
        }

        It 'rejects invalid skill names' {
            $proj = Join-Path $TestRoot 'proj-addskill-bad'
            New-Item -Path $proj -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj '.ai-config\skills') -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $proj 'scripts') -ItemType Directory | Out-Null
            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\scripts\add-skill.ps1") -Destination (Join-Path $proj 'scripts\add-skill.ps1') -Force

            Push-Location $proj
            # Script prints error but doesn't throw; verify the error message is output
            $output = & .\scripts\add-skill.ps1 remove "bad/name" *>&1 | Out-String
            $output | Should -Match 'Invalid skill name'
            Pop-Location
        }
    }

    Context 'sync-skills.ps1' {
        It 'validate command returns success for a valid skill' {
            $proj = Join-Path $TestRoot 'proj-syncskills'
            New-Item -Path $proj -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj '.ai-config\skills') -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $proj 'scripts') -ItemType Directory | Out-Null

            "---`nname: ok-skill`ndescription: OK`n---" | Out-File -FilePath (Join-Path $proj '.ai-config\skills\ok-skill.md') -Encoding utf8
            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\scripts\sync-skills.ps1") -Destination (Join-Path $proj 'scripts\sync-skills.ps1') -Force

            Push-Location $proj
            $output = & .\scripts\sync-skills.ps1 validate *>&1 | Out-String
            $output | Should -Match 'validos'
            Pop-Location
        }
    }

    Context 'generate-agents-catalog.ps1' {
        It 'generates AGENTS.md from frontmatter' {
            $proj = Join-Path $TestRoot 'proj-genagents'
            New-Item -Path $proj -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj '.ai-config\agents') -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $proj 'scripts') -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj 'lib') -ItemType Directory | Out-Null

            "---`nname: test-agent`ndescription: Test desc`n---`n" | Out-File -FilePath (Join-Path $proj '.ai-config\agents\test-agent.md') -Encoding utf8
            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\scripts\generate-agents-catalog.ps1") -Destination (Join-Path $proj 'scripts\generate-agents-catalog.ps1') -Force
            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\lib\Common.psm1") -Destination (Join-Path $proj 'lib\Common.psm1') -Force

            Push-Location $proj
            & .\scripts\generate-agents-catalog.ps1 *>&1 | Out-Null
            Test-Path (Join-Path $proj '.ai-config\AGENTS.md') | Should -BeTrue
            (Get-Content (Join-Path $proj '.ai-config\AGENTS.md') -Raw) | Should -Match 'test-agent'
            Pop-Location
        }
    }

    Context 'sync-ai-config.ps1' {
        It 'opencode target generates AGENTS.md' {
            $proj = Join-Path $TestRoot 'proj-syncai'
            New-Item -Path $proj -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj '.ai-config\agents') -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path $proj 'scripts') -ItemType Directory | Out-Null
            New-Item -Path (Join-Path $proj 'lib') -ItemType Directory | Out-Null

            "---`nname: opencode-agent`ndescription: OC`n---`n" | Out-File -FilePath (Join-Path $proj '.ai-config\agents\opencode-agent.md') -Encoding utf8
            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\scripts\sync-ai-config.ps1") -Destination (Join-Path $proj 'scripts\sync-ai-config.ps1') -Force
            Copy-Item -Path (Resolve-Path "$PSScriptRoot\..\..\lib\Common.psm1") -Destination (Join-Path $proj 'lib\Common.psm1') -Force

            Push-Location $proj
            & .\scripts\sync-ai-config.ps1 -Target opencode *>&1 | Out-Null
            Test-Path (Join-Path $proj 'AGENTS.md') | Should -BeTrue
            (Get-Content (Join-Path $proj 'AGENTS.md') -Raw) | Should -Match 'opencode-agent'
            Pop-Location
        }
    }

    Context 'doctor.ps1' {
        It 'prints help and exits 0' {
            & (Resolve-Path "$PSScriptRoot\..\..\scripts\doctor.ps1") -Help *>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }
    }
}
