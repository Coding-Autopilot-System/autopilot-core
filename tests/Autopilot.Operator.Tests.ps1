#requires -Modules Pester

# Unit tests for the safety/parse logic inside scripts/autopilot-operator.ps1.
#
# The operator script runs its whole mutation pipeline on load (Assert-Env,
# Test-Tool, Search-Issue, clone, push, ...), so it cannot be dot-sourced
# directly. Instead we lift out just its function definitions via the
# PowerShell AST and evaluate those in an isolated module scope. This keeps
# the functions under test byte-for-byte identical to what ships, with zero
# risk of triggering a live gh/git call.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $operatorPath = Join-Path $RepoRoot "scripts/autopilot-operator.ps1"

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $operatorPath, [ref]$tokens, [ref]$parseErrors)

    $funcs = $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true)

    $funcSource = ($funcs | ForEach-Object { $_.Extent.Text }) -join "`n`n"

    # Materialise the extracted functions as a real module so Pester's Mock
    # can intercept `git` calls made from inside them.
    $script:OpModule = New-Module -Name AutopilotOperatorFns -ScriptBlock ([scriptblock]::Create(
        $funcSource + "`nExport-ModuleMember -Function Get-ChangedFile,Assert-SafeChangeSet,Search-Issue")) | Import-Module -PassThru
}

AfterAll {
    Remove-Module AutopilotOperatorFns -Force -ErrorAction SilentlyContinue
}

Describe "Assert-SafeChangeSet - guard clauses" {
    It "rejects an empty change set" {
        { Assert-SafeChangeSet -Paths @() -MaxFiles 20 -MaxLines 1000 } |
            Should -Throw "*No changed files found*"
    }

    It "rejects a change set that exceeds the file limit" {
        { Assert-SafeChangeSet -Paths @("a.py", "b.py", "c.py") -MaxFiles 2 -MaxLines 1000 } |
            Should -Throw "*3 files; limit is 2*"
    }

    It "blocks a .env file anywhere in the tree" {
        { Assert-SafeChangeSet -Paths @("src/app.py", "config/.env") -MaxFiles 20 -MaxLines 1000 } |
            Should -Throw "*Sensitive path blocked*"
    }

    It "blocks private key material by name (id_rsa)" {
        { Assert-SafeChangeSet -Paths @("secrets/id_rsa") -MaxFiles 20 -MaxLines 1000 } |
            Should -Throw "*Sensitive path blocked*"
    }

    It "blocks certificate/key extensions (.pem, .pfx, .key, .p12)" {
        foreach ($p in @("deploy/cert.pem", "a/b.pfx", "x/y.key", "z/w.p12")) {
            { Assert-SafeChangeSet -Paths @($p) -MaxFiles 20 -MaxLines 1000 } |
                Should -Throw "*Sensitive path blocked*"
        }
    }

    It "normalises backslash separators before matching sensitive paths" {
        { Assert-SafeChangeSet -Paths @("deploy\secrets\app.pem") -MaxFiles 20 -MaxLines 1000 } |
            Should -Throw "*Sensitive path blocked*"
    }

    It "does not flag a benign source file that merely contains 'key' as a substring" {
        # 'monkey.py' contains 'key' but is not key material — must not be blocked
        # at the path-guard stage. git diff is mocked to report zero churn.
        Mock -CommandName git -ModuleName AutopilotOperatorFns -MockWith { "0`t0`tmonkey.py" }
        { Assert-SafeChangeSet -Paths @("src/monkey.py") -MaxFiles 20 -MaxLines 1000 } |
            Should -Not -Throw
    }
}

Describe "Assert-SafeChangeSet - line budget" {
    It "rejects a change set that exceeds the line limit" {
        Mock -CommandName git -ModuleName AutopilotOperatorFns -MockWith { "600`t500`tbig.py" }
        { Assert-SafeChangeSet -Paths @("big.py") -MaxFiles 20 -MaxLines 1000 } |
            Should -Throw "*1100 changed lines; limit is 1000*"
    }

    It "accepts a change set within both limits" {
        Mock -CommandName git -ModuleName AutopilotOperatorFns -MockWith { "10`t5`tsmall.py" }
        { Assert-SafeChangeSet -Paths @("small.py") -MaxFiles 20 -MaxLines 1000 } |
            Should -Not -Throw
    }

    It "ignores binary diff rows (git prints '-' for churn) instead of miscounting" {
        Mock -CommandName git -ModuleName AutopilotOperatorFns -MockWith { "-`t-`timage.png" }
        { Assert-SafeChangeSet -Paths @("image.png") -MaxFiles 20 -MaxLines 1000 } |
            Should -Not -Throw
    }
}

Describe "Get-ChangedFile - porcelain parsing" {
    It "extracts paths from standard porcelain status lines" {
        Mock -CommandName git -ModuleName AutopilotOperatorFns -MockWith {
            @(" M src/app.py", "?? new/file.txt")
        }
        $result = Get-ChangedFile
        $result | Should -Contain "src/app.py"
        $result | Should -Contain "new/file.txt"
    }

    It "resolves the destination path for a rename entry" {
        Mock -CommandName git -ModuleName AutopilotOperatorFns -MockWith {
            @("R  old/name.py -> new/name.py")
        }
        Get-ChangedFile | Should -Contain "new/name.py"
    }

    It "strips surrounding quotes git adds to paths with spaces" {
        Mock -CommandName git -ModuleName AutopilotOperatorFns -MockWith {
            @(' M "path with spaces.py"')
        }
        Get-ChangedFile | Should -Contain "path with spaces.py"
    }

    It "returns a unique, sorted set with no duplicates" {
        Mock -CommandName git -ModuleName AutopilotOperatorFns -MockWith {
            @(" M b.py", " M a.py", " M b.py")
        }
        $result = @(Get-ChangedFile)
        $result | Should -HaveCount 2
        $result[0] | Should -Be "a.py"
    }
}

Describe "Search-Issue - GraphQL request construction" {
    It "sends the exact query and first count through gh api graphql" {
        $script:capturedArgs = $null
        Mock -CommandName gh -ModuleName AutopilotOperatorFns -MockWith {
            $script:capturedArgs = $args
            '{"data":{"search":{"nodes":[{"number":1}]}}}'
        }

        $nodes = Search-Issue -SearchQuery "org:acme is:issue label:autofix" -First 5

        # Payload contract: gh must be invoked as `api graphql` with the
        # search query bound to -f q=... and the count bound to -F first=...
        $joined = $script:capturedArgs -join " "
        $joined | Should -Match "api graphql"
        $joined | Should -Match "q=org:acme is:issue label:autofix"
        $joined | Should -Match "first=5"

        $nodes[0].number | Should -Be 1
    }

    It "returns an empty array when the search payload has no data" {
        Mock -CommandName gh -ModuleName AutopilotOperatorFns -MockWith { '{"data":{"search":null}}' }
        @(Search-Issue -SearchQuery "org:acme" -First 5) | Should -HaveCount 0
    }
}
