$ErrorActionPreference = "Stop"

function Assert-Contains {
  param([string]$Text, [string]$Pattern, [string]$Message)
  if ($Text -notmatch $Pattern) { throw $Message }
}

function Assert-NotContains {
  param([string]$Text, [string]$Pattern, [string]$Message)
  if ($Text -match $Pattern) { throw $Message }
}

$operator = Get-Content -Raw "scripts/autopilot-operator.ps1"
$workflow = Get-Content -Raw ".github/workflows/autopilot-operator.yml"
$installer = Get-Content -Raw ".github/workflows/autopilot-org-installer.yml"
$allWorkflows = (Get-ChildItem -Recurse -File -Include *.yml,*.yaml | ForEach-Object { Get-Content -Raw $_.FullName }) -join "`n"

Assert-Contains $operator 'label:autofix label:queued' "Operator must require autofix and queued labels."
Assert-NotContains $operator 'no:label' "Operator must not execute unlabeled issues."
Assert-Contains $operator '-label:try-3' "Operator must exclude exhausted issues."
Assert-Contains $operator 'BEGIN UNTRUSTED ISSUE CONTENT' "Operator must delimit untrusted prompt content."
Assert-Contains $operator 'Assert-SafeChangeSet' "Operator must validate generated changes."
Assert-Contains $operator 'ALLOW_UNVERIFIED' "Operator must enforce verification by default."
Assert-Contains $workflow 'secrets\.ORG_AUTOPILOT_TOKEN' "Workflow must use an explicit org mutation token."
Assert-NotContains $workflow 'GH_TOKEN: \$\{\{ secrets\.GITHUB_TOKEN \}\}' "Workflow must not use repository token for org mutations."

Assert-NotContains $installer 'autofix,queued,docs' "Installer must not queue automation before repository opt-in."

Assert-NotContains $allWorkflows 'actions/checkout@v4|actions/github-script@v7' "Workflows must not use deprecated Node.js 20 action majors."

Write-Host "Control-plane contract tests passed."
