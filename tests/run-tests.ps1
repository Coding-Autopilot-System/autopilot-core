#requires -Version 5.1
<#
.SYNOPSIS
    Single entry point for the autopilot-core test suite.

.DESCRIPTION
    Runs, in order:
      1. Python workflow YAML validation (tests/validate_workflows.py)
      2. Control-plane contract tests    (tests/contract-tests.ps1)
      3. Pester unit tests               (tests/*.Tests.ps1)

    Any failure is fatal (non-zero exit) so this is CI-safe.

.EXAMPLE
    pwsh ./tests/run-tests.ps1
#>
[CmdletBinding()]
param(
    # Skip the Python workflow validator (useful when PyYAML is unavailable).
    [switch]$SkipPython
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    if (-not $SkipPython) {
        Write-Host "==> Validating workflow YAML" -ForegroundColor Cyan
        python tests/validate_workflows.py
        if ($LASTEXITCODE -ne 0) { throw "Workflow validation failed (exit $LASTEXITCODE)." }
    }

    Write-Host "==> Running control-plane contract tests" -ForegroundColor Cyan
    & "$PSScriptRoot/contract-tests.ps1"

    Write-Host "==> Running Pester unit tests" -ForegroundColor Cyan
    Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop

    $config = New-PesterConfiguration
    $config.Run.Path = $PSScriptRoot
    $config.Run.Exit = $true
    $config.Output.Verbosity = "Detailed"
    $config.TestResult.Enabled = $false

    Invoke-Pester -Configuration $config
}
finally {
    Pop-Location
}
