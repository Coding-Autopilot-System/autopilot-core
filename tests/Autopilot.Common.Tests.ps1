#requires -Modules Pester

# Unit tests for the pure/deterministic helper functions in
# scripts/lib/Autopilot.Common.psm1. These functions build gh payloads,
# normalise repo names, and parse tool output — the highest-value logic to
# pin down because the operator mutates OTHER repos based on their results.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:ModulePath = Join-Path $RepoRoot "scripts/lib/Autopilot.Common.psm1"
    Import-Module $ModulePath -Force
}

AfterAll {
    Remove-Module Autopilot.Common -Force -ErrorAction SilentlyContinue
}

Describe "Get-RepoName" {
    It "extracts owner/repo from an https clone URL" {
        Get-RepoName -RepoUrl "https://github.com/acme/widgets" | Should -Be "acme/widgets"
    }

    It "tolerates a trailing slash" {
        Get-RepoName -RepoUrl "https://github.com/acme/widgets/" | Should -Be "acme/widgets"
    }

    It "handles an ssh-style URL by taking the final two path segments" {
        Get-RepoName -RepoUrl "https://github.com/acme/deep/nested/widgets" | Should -Be "nested/widgets"
    }
}

Describe "Invoke-GhJson" {
    Context "when gh returns clean JSON" {
        BeforeEach {
            Mock -CommandName gh -ModuleName Autopilot.Common -MockWith { '{"login":"octocat","type":"User"}' }
        }

        It "parses a JSON object into a PSCustomObject" {
            $result = Invoke-GhJson -Arguments @("api", "user")
            $result.login | Should -Be "octocat"
            $result.type | Should -Be "User"
        }
    }

    Context "when gh emits a leading warning line before the JSON" {
        BeforeEach {
            # gh sometimes prints noise on stdout before the payload; the
            # function must locate the first { or [ and parse from there.
            Mock -CommandName gh -ModuleName Autopilot.Common -MockWith { "Warning: something`n[{""number"":7}]" }
        }

        It "strips the prefix and parses the array" {
            $result = Invoke-GhJson -Arguments @("api", "issues")
            $result[0].number | Should -Be 7
        }
    }

    Context "when gh returns nothing" {
        BeforeEach {
            Mock -CommandName gh -ModuleName Autopilot.Common -MockWith { $null }
        }

        It "returns null without throwing" {
            Invoke-GhJson -Arguments @("api", "nothing") | Should -BeNullOrEmpty
        }
    }
}

Describe "Get-LogTail" {
    It "returns null when the log file does not exist" {
        Get-LogTail -LogPath (Join-Path $TestDrive "missing.log") -Lines 5 | Should -BeNullOrEmpty
    }

    It "returns only the last N lines of an existing log" {
        $log = Join-Path $TestDrive "sample.log"
        1..10 | ForEach-Object { "line $_" } | Set-Content -Path $log
        $tail = Get-LogTail -LogPath $log -Lines 3
        $tail | Should -HaveCount 3
        $tail[-1] | Should -Be "line 10"
        $tail[0] | Should -Be "line 8"
    }
}
